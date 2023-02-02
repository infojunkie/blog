---
layout: post
title: Still Drupal after all these years
date: 2023-02-01
---
I thought I was done with Drupal in 2016 when we rebuilt [Meedan's fact-checking platform, Check](https://github.com/meedan/check), using Ruby / React. It felt like a breath of fresh air to decouple the frontend from the backend, and further subdivide the application into a set of services that can be designed and maintained independently. Breaking the monolith was all the rage back then!

But I was hired again for my Drupal expertise in 2022. For the past 8 months, I've been working on a massive site refresh using Drupal 9, and I must admit that, against my expectations, I really enjoyed working on this platform. I found Drupal 8/9+ to be a real step forward in terms of developer experience compared to previous versions, particularly well-suited to build large web sites.

But I won't get into the top 10 reasons I like Drupal 9. In this post, I will list a few interesting snippets that I developed over the course of this project.

## Showing an export link for each manually updated config item
The Configuration API is by far the best surprise I had about Drupal 9. Finally, a core system that is robust enough to hold any configuration set reliably, and extensible enough for contrib modules. Back in Drupal 7-, maintaining a consistent configuration across stages had been the bane of my existence, and I was delighted to find it was now a solved problem.

One minor wrinkle I found is related to the scenario of admin users wanting to update the configs that are otherwise stored in source control:
- Admin changes a permission on stage PROD via Admin UI
- Devops makes a code deployment on stages DEV => TEST => PROD
- The permission change is lost, unless Admin exports the updated permission config and hands it to Devops before deployment

To support this scenario, Admin needs to go to **Configuration synchronization** `/admin/config/development/configuration`, examine the changed items, then head over to **Single export** `/admin/config/development/configuration/single/export` and GUESS how the name that they saw on the previous screen maps to a given configuration type/name pair on this one. User-unfriendly and error-prone!

My quick solution was to add an **Export config** action for each updated item in the **Configuration synchronization** screen, as per the attached screenshot. This was feasible to implement because [the **Single export** route actually accepts a specific configuration type/name pair](https://git.drupalcode.org/project/drupal/-/blob/9.5.3/core/modules/config/config.routing.yml#L56-64), which my code computes given the configuration item (and that was not terribly straightforward). Now Admin can easily export all modified configuration items without any guesswork!

{% include image.html url="/assets/drupal-config-sync.png" width="100%" %}

{% include image.html url="/assets/drupal-config-export.png" width="100%" %}

```php
/**
 * Implements hook_form_FORM_ID_alter() for config_admin_import_form.
 *
 * Show export link for each modified config item.
 */
function MYMODULE_form_config_admin_import_form_alter(&$form, FormStateInterface $form_state, $form_id) {
  $configs = [];
  foreach (\Drupal::service('entity_type.manager')->getDefinitions() as $entity_type => $definition) {
    if ($definition->entityClassImplements(ConfigEntityInterface::class)) {
      $entity_storage = \Drupal::service('entity_type.manager')->getStorage($entity_type);
      foreach ($entity_storage->loadMultiple() as $entity) {
        $configs[$definition->getConfigPrefix() . '.' . $entity->id()] = [
          'config_type' => $entity_type,
          'config_name' => $entity->id(),
        ];
      }
    }
  }

  $collection = '';
  $config_change_type = 'update';
  if (!empty($form[$collection][$config_change_type]['list']['#rows'])) {
    foreach ($form[$collection][$config_change_type]['list']['#rows'] as &$config_change) {
      $config_item = $config_change['name'];

      if (array_key_exists($config_item, $configs)) {
        $config_type = $configs[$config_item]['config_type'];
        $config_name = $configs[$config_item]['config_name'];
      }
      else {
        $config_type = 'system.simple';
        $config_name = $config_item;
      }

      $config_change['operations']['data']['#links']['export'] = [
        'title' => t('Export config'),
        'url' => Url::fromRoute('config.export_single', [
          'config_type' => $config_type,
          'config_name' => $config_name,
        ]),
      ];
    }
  }
}
```
## Backup and Migrate: PostgreSQL support
I was suprised this hadn't been already done, so I [added PostgreSQL support to the venerable Backup and Migrate (BAM) module](https://www.drupal.org/project/backup_migrate/issues/2930369). Instead of previous patches that implemented SQL generation and parsing manually, I opted for the much simpler and (imho) more robust approach of invoking the standard tools `pg_dump` and `pgsql` for the backup and restore operations. It took me less than a day to get that patch working, and we've been using it daily on this project for the past 8 months, so I have good confidence it is production-ready.

For example, the backup implementation is about 40 lines long:
```php
  /**
   * Export this source to the given temp file.
   *
   * This should be the main back up function for this source.
   *
   * @return \Drupal\backup_migrate\Core\File\BackupFileReadableInterface
   *   A backup file with the contents of the source dumped to it.
   */
  public function exportToFile() {
    $adapter = new DrupalTempFileAdapter(\Drupal::service('file_system'));
    $tempfilemanager = new TempFileManager($adapter);
    $this->setTempFileManager($tempfilemanager);
    $file = $this->getTempFileManager()->create('sql');

    // A bit of PHP magic to get the configuration of the db_exclude plugin.
    // The PluginManagerInterface::get($plugin_id) method returns a PluginInterface which does not expose the confGet() method.
    // So we want to cast it to a PluginBase which does expose confGet().
    // Since PHP doesn't have an explicit casting operator for classes, we use an inline function whose return type is PluginBase.
    // https://stackoverflow.com/a/69771390/209184
    $exclude_tables = (array) (fn($plugin):PluginBase=>$plugin)($this->plugins()->get('db_exclude'))->confGet('exclude_tables');
    $nodata_tables = (array) (fn($plugin):PluginBase=>$plugin)($this->plugins()->get('db_exclude'))->confGet('nodata_tables');

    $process_args = [
      'pg_dump',
      '--host', $this->confGet('host'),
      '--port', $this->confGet('port'),
      '--user', $this->confGet('username'),
      '--clean'
    ];
    if ($exclude_tables) {
      foreach($exclude_tables as $table) {
        array_push($process_args, '--exclude-table', $table);
      }
    }
    if ($nodata_tables) {
      foreach($nodata_tables as $table) {
        array_push($process_args, '--exclude-table-data', $table);
      }
    }
    $process = new Process(
      array_merge($process_args, [$this->confGet('database')]),
      null,
      [
        'PGPASSWORD' => $this->confGet('password')
      ]
    );
    $process->run();
    if (!$process->isSuccessful()) {
      $message = $process->getErrorOutput();
      \Drupal::logger('backup_migrate')->error($message);
      throw new BackupMigrateException($message);
    }
    $file->write($process->getOutput());
    $file->close();
    return $file;
  }
```

## Backup and Migrate: Drupal 9 / Drush 11 support
Supporting content migrations across stages is a tricky subject, and most tools I reviewed seemed too fragile or too complex to be delivered to a client. We opted to use a simple workflow based on BAM backup/restore coupled with config re-synchronization. To help automate the process, I wrote a set of `drush` commands that implement BAM backup and restore. It's been tested extensively, but only with a specific set of sources and destinations, so I am reproducing the current code here until it gets published as a module. One design decision I made was to produce output as JSON, to make it easier for downstream automation.

The typical usage scenario is the following:
```shell
$ drush bamb default_db private_files
// => {
//    "status": "success",
//    "message": "Backup complete."
//}
$ drush bamls --files=private_files
// => {
//    "sources": [
//        {
//            "id": "default_db",
//            "label": "Default Drupal Database",
//            "type": "DefaultDB"
//        },
//        {
//            "id": "entire_site",
//            "label": "Entire Site (do not use)",
//            "type": "EntireSite"
//        },
//        {
//            "id": "private_files",
//            "label": "Private Files Directory",
//            "type": "DrupalFiles"
//        },
//        {
//            "id": "public_files",
//            "label": "Public Files Directory",
//            "type": "DrupalFiles"
//        },
//        {
//            "id": "ssot_database",
//            "label": "SSoT Database",
//            "type": "PostgreSQL"
//        }
//    ],
//    "destinations": [
//        {
//            "id": "private_files",
//            "label": "Private Files Directory",
//            "type": "Directory"
//        },
//        {
//            "id": "s3_bucket",
//            "label": "S3 Bucket",
//            "type": "awss3"
//        }
//    ],
//    "files": {
//        "private_files": [
//            {
//                "id": "backup-2023-01-27T15-44-19.sql.gz",
//                "filename": "prod-2023-01-27T15-44-19.sql.gz",
//                "filesize": 19499222,
//                "datestamp": 1674869134
//            }
//        ]
//    }
//}
$ drush bamr default_db private_files backup-2023-01-27T15-44-19.sql.gz
// => {
//    "status": "success",
//    "message": "Restore complete."
//}
```
```php
<?php

namespace Drush\Commands;

use Drush\Drush;
use Drush\Commands\DrushCommands;
use Drush\Boot\DrupalBootLevels;
use Drupal\backup_migrate\Core\Destination\ListableDestinationInterface;
use Symfony\Component\Console\Input\InputOption;

class BackupMigrateCommands extends DrushCommands
{
    /**
     * List sources and destinations.
     *
     * @command backup_migrate:list
     * @aliases bamls
     *
     * @option sources Flag to list sources (default: yes, use --no-sources to hide)
     * @option destinations Flag to list destinations (default: yes, use --no-destinations to hide)
     * @option files Flag to list files for a comma-separated list of destination identifiers (default: none)
     *
     * @param options
     *
     * @return string JSON listing of sources, destinations, files
     *
     */
    public function list(array $options = [
        'sources' => true,
        'destinations' => true,
        'files' => InputOption::VALUE_REQUIRED,
    ]): string {
        Drush::bootstrapManager()->doBootstrap(DrupalBootLevels::FULL);
        $bam = \backup_migrate_get_service_object();
        $output = [];
        if ($options['sources']) {
            $output['sources'] = array_reduce(array_keys($bam->sources()->getAll()), function($sources, $source_id) {
                $source = \Drupal::entityTypeManager()->getStorage('backup_migrate_source')->load($source_id);
                if ($source) {
                    $sources[] = [
                        'id' => $source_id,
                        'label' => $source->get('label'),
                        'type' => $source->get('type'),
                    ];
                }
                return $sources;
            }, []);
        }
        if ($options['destinations']) {
            $output['destinations'] = array_reduce(array_keys($bam->destinations()->getAll()), function($destinations, $destination_id) {
                $destination = \Drupal::entityTypeManager()->getStorage('backup_migrate_destination')->load($destination_id);
                if ($destination) {
                    $destinations[] = [
                        'id' => $destination_id,
                        'label' => $destination->get('label'),
                        'type' => $destination->get('type'),
                    ];
                }
                return $destinations;
            }, []);
        }
        if ($options['files']) {
            foreach(array_map('trim', explode(',', $options['files'])) as $destination_id) {
                $destination = $bam->destinations()->get($destination_id);
                if (!$destination) {
                    $this->logger()->warning(dt('The destination !id does not exist.', ['!id' => $destination_id]));
                    continue;
                }
                if (!$destination instanceof ListableDestinationInterface) {
                    $this->logger()->warning(dt('The destination !id is not listable.', ['!id' => $destination_id]));
                    continue;
                }
                try {
                    $files = $destination->listFiles();
                    $output['files'][$destination_id] = array_reduce(array_keys($files), function($files_info, $file_id) use($files) {
                        $files_info[] = array_merge([
                            'id' => $file_id,
                            'filename' => $files[$file_id]->getFullName(),
                        ], $files[$file_id]->getMetaAll());
                        return $files_info;
                    }, []);
                    usort($output['files'][$destination_id], function($file1, $file2) {
                        // TODO What if datestamp is not available?
                        $a = $file1['datestamp'];
                        $b = $file2['datestamp'];
                        if ($a == $b) return 0;
                        return ($a < $b) ? -1 : 1;
                    });
                }
                catch (\Exception $e) {
                    $this->logger()->error(dt('The destination !id caused an error: !error', [
                        '!id' => $destination_id,
                        '!error' => $e->getMessage()
                    ]));
                }
            }
        }
        return json_encode($output, JSON_PRETTY_PRINT);
    }

    /**
     * Backup.
     *
     * @command backup_migrate:backup
     * @aliases bamb
     *
     * @param source_id Identifier of the Backup Source.
     * @param destination_id Identifier of the Backup Destination.
     *
     * @return string Backup completion status
     *
     * @throws \Drupal\backup_migrate\Core\Exception\BackupMigrateException
     *
     */
    public function backup(
        $source_id,
        $destination_id
    ): string
    {
        Drush::bootstrapManager()->doBootstrap(DrupalBootLevels::FULL);
        $bam = \backup_migrate_get_service_object();
        $bam->backup($source_id, $destination_id);
        return json_encode([
            'status' => 'success',
            'message' => dt('Backup complete.')
        ], JSON_PRETTY_PRINT);
    }

    /**
     * Restore.
     *
     * @command backup_migrate:restore
     * @aliases bamr
     *
     * @param source_id Identifier of the Backup Source.
     * @param destination_id Identifier of the Backup Destination.
     * @param file_id optional Identifier of the Destination file.
     *
     * @return string Restore completion status
     *
     * @throws \Drupal\backup_migrate\Core\Exception\BackupMigrateException
     *
     */
    public function restore(
        $source_id,
        $destination_id,
        $file_id = null,
    ): string
    {
        Drush::bootstrapManager()->doBootstrap(DrupalBootLevels::FULL);
        $bam = \backup_migrate_get_service_object();
        $bam->restore($source_id, $destination_id, $file_id);
        return json_encode([
            'status' => 'success',
            'message' => dt('Restore complete.')
        ], JSON_PRETTY_PRINT);
    }
}
```
## Fixing Google Charts rendering in tabbed pages
Google Charts has a [long-standing, known issue rendering correctly in hidden divs](https://stackoverflow.com/search?q=google+charts+hidden). This caused us much head scratching and debugging hours before we even landed on the correct diagnosis: a chart that renders correctly on the [Charts API Example page](https://git.drupalcode.org/project/charts/-/tree/5.0.x/modules/charts_api_example) does not work inside a tab! Oh, the joys of programming sometimes.

Once diagnosed, the fix was obvious: detect that a tab is selected to refresh the charts contained therein. The following JavaScript file can be added to your theme as is and should handle the standard Bootstrap tabs (it also fixes the window resize event handling). It does depend on a small patch made to the [`charts_google` module](https://git.drupalcode.org/project/charts/-/tree/5.0.x/modules/charts_google), to avoid leaking memory when the graph is redrawn:
```javascript
(function ($, Drupal, once) {
  ("use strict");

  function redrawGoogleChart(element) {
    const contents = new Drupal.Charts.Contents();
    const chartId = element.id;
    if (Drupal.googleCharts.charts.hasOwnProperty(chartId)) {
      Drupal.googleCharts.charts[chartId].clearChart();
    }
    const dataAttributes = contents.getData(chartId);
    Drupal.googleCharts.drawChart(chartId, dataAttributes['visualization'], dataAttributes['data'], dataAttributes['options'])();
  }

  Drupal.behaviors.redrawGoogleCharts = {
    attach: function (context, settings) {
      $('.nav-link', context).on('shown.bs.tab', function (e) {
        if (Drupal.Charts && Drupal.googleCharts) {
          $('.charts-google', $(e.target).attr('data-bs-target')).each(function () {
            if (this.dataset.hasOwnProperty('chart')) {
              redrawGoogleChart(this);
            }
          });
        }
      });

      window.addEventListener('resize', function () {
        if (Drupal.Charts && Drupal.googleCharts) {
          Drupal.googleCharts.waitForFinalEvent(function () {
            $('.charts-google').each(function () {
              if (this.dataset.hasOwnProperty('chart')) {
                redrawGoogleChart(this);
              }
            });
          }, 200, 'google-charts-redraw');
        }
      });
    },
  };

})(jQuery, Drupal, once);
```
```patch
diff --git a/modules/charts_google/js/charts_google.js b/modules/charts_google/js/charts_google.js
index f7abe81..76143bc 100755
--- a/modules/charts_google/js/charts_google.js
+++ b/modules/charts_google/js/charts_google.js
@@ -6,7 +6,7 @@

   'use strict';

-  Drupal.googleCharts = Drupal.googleCharts || {charts: []};
+  Drupal.googleCharts = Drupal.googleCharts || {charts: {}};

   /**
    * Behavior to initialize Google Charts.
@@ -122,6 +122,7 @@
         options['colorAxis'] = {colors: colors};
       }
       chart.draw(data, options);
+      Drupal.googleCharts.charts[chartId] = chart;
     };
   };
```

I might dig up more snippets later - for now, happy coding! :cat: :computer:

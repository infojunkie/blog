---
layout: post
title: "Drupal 9: Backup and Migrate - Drush 11 support"
date: 2023-06-01
category: drupal
description: In which I publish a small Drush 11 command for Backup and Migrate.
---
Supporting content migrations across stages is a tricky subject, and most tools I reviewed seemed too fragile or too complex to be delivered to a client. We opted to use a simple workflow based on [BAM (Backup and Migrate)](https://www.drupal.org/project/backup_migrate) coupled with config re-synchronization. To help automate the process, I wrote a set of `drush` commands that implement BAM backup and restore. It's been tested extensively, but only with a specific set of sources and destinations, so I am reproducing the current code here until it gets published as a module. One design decision I made was to produce output as JSON, to make it easier for downstream automation.

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

And here's the source for the command:
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

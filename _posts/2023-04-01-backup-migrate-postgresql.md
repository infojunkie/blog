---
layout: post
title: "Drupal 9: Backup and Migrate - PostgreSQL support"
date: 2023-04-01
category: drupal
description: In which I describe a simple and robust approach to support PostgreSQL with Backup and Migrate module.
---
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

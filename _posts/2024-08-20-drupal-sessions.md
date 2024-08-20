---
layout: post
title: "Drupal 10: From cookies to user sessions"
date: 2024-08-20
category: drupal
---
When you need to examine user session tokens, you know you're deep in the bowels of the CMS. That's what happened to me recently, as I was debugging why CloudFlare was mixing up user sessions and giving admin access to otherwise unpermissioned users :scream:

To help debug this, I needed a way to associate user cookies with entries from the `sessions` table. I wrote a drush script to do exactly that: Given the value of the SESSXXX cookie in your browser, the script will find the corresponding `sessions` entry and dump its information, decoding the session metadata in the process:
```bash
$ drush scr export_sessions.php -- --cookie=5XvW3NGG8q1PcCrEXn676THvQBitaUwDiPw8XzAgXtihV43u
```
```json
[
    {
        "uid": "1",
        "sid": "-Xcm0ar3mWcMhIhhBANA3K-jUx3JNOsu190LPEUzIN8",
        "hostname": "172.24.0.1",
        "timestamp": "1724179990",
        "session": "_sf2_attributes|a:1:{s:3:\"uid\";s:1:\"1\";}_sf2_meta|a:4:{s:1:\"u\";i:1724179990;s:1:\"c\";i:1723574737;s:1:\"l\";i:2000000;s:1:\"s\";s:43:\"OCpNT7IvSsWNfPeYXam7E7XFPTKqb-8qWPUTMe8MFlQ\";}",
        "sf2": [
            {
                "name": "attributes",
                "value": {
                    "uid": "1"
                }
            },
            {
                "name": "meta",
                "value": {
                    "u": 1724179990,
                    "c": 1723574737,
                    "l": 2000000,
                    "s": "OCpNT7IvSsWNfPeYXam7E7XFPTKqb-8qWPUTMe8MFlQ"
                }
            }
        ]
    }
]
```

The same script will dump ALL sessions if you don't pass in a cookie value. Here's the source code of `export_sessions.php`:
```php
<?php

/**
 * Retrieve session entry for given cookie.
 * Based on https://drupal.stackexchange.com/a/231726/767
 */

use Drupal\Component\Utility\Crypt;

if (!empty($extra)) {
  if (!str_starts_with($extra[0], '--cookie=')) {
    die("Usage: drush scr export_sessions.php [-- --cookie=<value of SESSxxxx cookie>]\n");
  }
  else {
    $cookie = trim(str_replace('--cookie=', '', $extra[0]));
    $cookie = urldecode($cookie);
    $sid = Crypt::hashBase64($cookie);
  }
}
$connection = \Drupal::database();
if (isset($sid)) {
  $query = $connection->query('SELECT * FROM {sessions} WHERE sid = :sid', [':sid' => $sid]);
}
else {
  $query = $connection->query('SELECT * FROM {sessions}');
}

echo json_encode(array_map(function($session) {
  preg_match_all('/_sf2_(\w+)\|/', $session->session, $matches, PREG_OFFSET_CAPTURE | PREG_SET_ORDER);
  $session->sf2 = array_map(function($match, $index) use ($session, $matches) {
    $offset = $match[0][1] + strlen($match[0][0]);
    $length = $index + 1 < count($matches) ?
      $matches[$index + 1][0][1] - $offset:
      strlen($session->session) - 1 - $match[0][1];
    return [
      'name' => $match[1][0],
      'value' => unserialize(substr($session->session, $offset, $length)),
    ];
  }, $matches, array_keys($matches));
  return $session;
}, $query->fetchAll()), JSON_PRETTY_PRINT) . "\n";
```
That's it. Short and sweet! :candy:

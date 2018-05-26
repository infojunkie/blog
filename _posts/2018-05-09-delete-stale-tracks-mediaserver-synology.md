---
layout: post
title: Deleting stale tracks from the Synology NAS media database
date: 2018-05-09
---
[In a previous post]({% post_url 2018-04-02-synology-mediaserver %}), I've been exploring the
structure of the `mediaserver` database which is the media database on the Synology NAS.

In some cases, tracks and folders that are moved or removed on the NAS filesystem (especially from CIFS/Samba) are not reflected in the **Audio Station** app - this is because the stale paths are not removed from the `mediaserver` database.
Here is a recipe to clean them up - I'll show the live steps but please practice standard backup
procedure before doing so:

- `ssh your-nas-hostname` to get into the NAS
- `sudo su -` to become root
- `su - postgres` to become the Postgres user
- `psql mediaserver` to connect to the media database
- `select * from track where path like '%path/to/old/files%';` to identify the tracks that you want to remove - make sure you get that right!
- `delete from track where path like '%path/to/old/files%';` to remove those entries and their children records in related tables
- Repeat the above `select` and `delete` instructions for tables `music` and `directory` with the same `path` condition
- Refresh your audio app: the files and folders should be gone!

That's it! Don't nuke your data :joy:

---
layout: post
title: Extracting and manipulating the media database from Synology NAS
date: 2018-04-03
---
As a dedicated music listener, I care about my media library. I run a Synology DS411+ NAS
which has been excellent at serving large amounts of media, but their audio apps (**Audio Station** on
the browser, **DS audio** on mobile) inevitably have missing features that I wish I could use while
trying to locate and play music. I've submitted a few bug reports and feature requests to Synology,
and I am happy to report that at least one bug I filed was fixed, and quite promptly too. As a
maintainer of production software myself, I say kudos (and many thanks) to the Synology team!

However, I can go a little further to scratch my own itch. Today, I decided to start exploring the inner
workings of the Synology media server. I hypothesized that there must be some kind of database that
allows the various apps (audio, video, etc.) to search and locate the media on the NAS. A little googling
led me to a [Stack Exchange post](https://unix.stackexchange.com/questions/377713/postgresql-installation-on-a-synology-diskstation-ds216j-pgadminiii)
that showed a PostgreSQL server containing databases such as `mediaserver`, `photo`, `video_metadata`. Bingo!

Here's what I did to load `mediaserver` onto my laptop:

### Get the database dump
- `ssh rokanan` to get into the NAS (I like Ursula Le Guin)
- `sudo su - postgres` to become the Postgres user
- `pg_dump mediaserver | bzip2 > mediaserver.sql.bz2` to dump the desired database
- `exit` to return to your account
- `sudo mv /var/services/pgsql/mediaserver.sql.bz2 .` to move the file to your home
- exit the NAS
- `scp rokanan:~/mediaserver.sql.bz2 .` to get the file locally

### Load the database locally
I used a [Postgres Docker image](https://hub.docker.com/_/postgres/) to avoid running Postgres server locally.
To spin it up, I used Docker Compose with the following Compose file:
```
version: '3'
volumes:
  mediaserver:
services:
  postgres:
    image: postgres:9.5
    volumes:
      - mediaserver:/var/lib/postgresql/data
    ports:
      - 5432:5432
    environment:
      - POSTGRES_DB=mediaserver
      - POSTGRES_USER=MediaIndex
      - POSTGRES_PASSWORD=MediaIndex
```
- `docker-compose up` will create a new, blank database `mediaserver` or reload the existing one
- `bzip2 -dc mediaserver.sql.bz2 | docker-compose exec -T postgres psql -U MediaIndex mediaserver` to load the database dump into Postgres

### Deleting stale tracks from the database
In some cases, tracks and folders that are moved or removed on the NAS filesystem (especially from CIFS/Samba) are not reflected in the **Audio Station** app - this is because the stale paths are not removed from the `mediaserver` database.

Here is a recipe to clean them up - I'll show the live steps but please practice standard backup
procedure before doing so:

- `ssh your-nas-hostname` to get into the NAS
- `sudo su - postgres` to become the Postgres user
- `psql mediaserver` to connect to the media database
- `select * from track where path like '%path/to/old/files%';` to identify the tracks that you want to remove - make sure you get that right!
- `delete from track where path like '%path/to/old/files%';` to remove those entries and their children records in related tables
- Repeat the above `select` and `delete` instructions for tables `music` and `directory` with the same `path` condition
- Refresh your audio app: the files and folders should be gone!

That's it! Don't nuke your data :scream:

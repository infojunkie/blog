---
layout: post
title: Extracting the media database from Synology NAS
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
- `sudo su -` to become root
- `su - postgres` to become the Postgres user
- `pg_dump mediaserver | bzip2 > mediaserver.sql.bz2` to dump the desired database
- `exit` to return to root
- `mv /var/services/pgsql/mediaserver.sql.bz2 .` to move the file to my home
- `chown your-username:users mediaserver.sql.bz2` to make the file accessible
- exit the NAS
- `scp rokanan:~/mediaserver.sql.bz2 .` to get the file locally

### Load the database locally
I used a [Postgres Docker image](https://hub.docker.com/_/postgres/) to avoid running Postgres server locally.
To spin it up, I used Docker Compose with the following Compose file:
```
version: '3'
services:
  postgres:
    container_name: postgres
    restart: always
    image: postgres:latest
    volumes:
      - ./database:/var/lib/postgresql/data
    ports:
      - 5432:5432
```
- `docker-compose up` will create a new, blank database `postgres` or reload the existing one
- `bzip2 -dc mediaserver.sql.bz2 | docker exec -i postgres psql -U postgres` to load the database dump into Postgres - don't worry about the `ERROR:  role "MediaIndex" does not exist` errors

That's it! Now I was able to connect to the server via [pgAdmin](https://www.pgadmin.org/) to explore the database.
Next time I'll start doing useful stuff with it :wave:

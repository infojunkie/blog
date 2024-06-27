---
layout: post
title: Still Drupal after all these years
date: 2023-02-01
category: drupal
---
I thought I was done with Drupal in 2016 when we rebuilt [Meedan's fact-checking platform, Check](https://github.com/meedan/check), using Ruby / React. It felt like a breath of fresh air to decouple the frontend from the backend, and further subdivide the application into a set of services that can be designed and maintained independently. Breaking the monolith was all the rage back then!

But I was hired again for my Drupal expertise in 2022. For the past 8 months, I've been working on a massive site refresh using Drupal 9, and I must admit that, against my expectations, I really enjoyed working on this platform. I found Drupal 8/9+ to be a real step forward in terms of developer experience compared to previous versions, particularly well-suited to build large web sites.

But I won't get into the top 10 reasons I like Drupal 9. In this post, I will list a few interesting snippets that I developed over the course of this project:

- [Showing an export link for each manually updated config item]({% link _posts/2023-03-01-export-link.md %})
- [Backup and Migrate: PostgreSQL support]({% link _posts/2023-04-01-backup-migrate-postgresql.md %})
- [Backup and Migrate: Drupal 9 / Drush 11 support]({% link _posts/2023-06-01-backup-migrate-drush.md %})
- [Fixing Google Charts rendering in tabbed pages]({% link _posts/2023-05-01-google-charts-tabs.md %})

I might dig up more snippets later - for now, happy coding! :cat: :computer:

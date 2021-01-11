#!/bin/bash
git pull
source .env
bundle install
bundle exec jekyll build
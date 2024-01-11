#!/bin/sh

# Fail fast on errors
set -e

rm -rf _site
mkdir _site
# Put bundles in a known path
bundle config set path $HOME/.bundle
# Update gems
gem install bundler:2.1.4
bundle install
# Build the site
bundle exec jekyll build

git checkout -f master
git pull --rebase

cp -r _site/* .
git add -A
git commit -a -m "Published master to GitHub pages."
git push origin master && git checkout develop

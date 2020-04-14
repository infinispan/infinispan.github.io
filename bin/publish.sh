#!/bin/sh

rm -rf _site
# Put bundles in a known path
bundle config set path $HOME/.bundle
# Update gems
bundle install
# Fetch docs
bundle exec bin/fetch_docs.rb
# Build the site
bundle exec awestruct -gw -Pproduction

git checkout -f master
git pull --rebase

cp -r _site/* .
git add -A
git commit -a -m "Published master to GitHub pages."
git push origin master && git checkout develop

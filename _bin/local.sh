#!/bin/sh

# Fail fast on errors
set -e

rm -rf _site
mkdir _site
# Put bundles in a known path
bundle config set path $HOME/.bundle
# Update gems
if ! [ -x "$(command -v bundle)" ]; then
    echo "Bundler missing"
    gem install bundler:2.5.1
fi
#
bundle install
# Build the site
bundle exec jekyll serve

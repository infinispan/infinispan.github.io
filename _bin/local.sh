#!/bin/sh

# Fail fast on errors
set -e

skip_docs=false

usage() {
    echo "Usage: $0 [-n]"
    echo "  -n  Skip the documentation download (sets SKIP_FETCH_DOCS=true)"
}

while getopts ":n" opt; do
    case "$opt" in
        n) skip_docs=true ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done

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
if [ "$skip_docs" = true ]; then
    SKIP_FETCH_DOCS=true bundle exec jekyll serve --incremental
else
    bundle exec jekyll serve --incremental
fi

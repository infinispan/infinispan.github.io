#!/bin/sh
rm -rf _site
bin/fetch_docs.rb -f
bundle exec awestruct -g -Pproduction --deploy

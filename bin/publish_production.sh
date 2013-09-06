#!/bin/sh
rm -rf _site
bundle exec awestruct -g -Pproduction --deploy

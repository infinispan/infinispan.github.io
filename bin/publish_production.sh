#!/bin/sh

if [ -x "/usr/bin/scl_source" ]; then
  source scl_source enable rh-ruby22
fi

rm -rf _site
bin/fetch_docs.rb

# Update gems
bundle install

# The awestruct github_pages deployer doesn't work on the CI machine ATM, it deletes everything on the master branch
# so we deploy manually instead
#bundle exec awestruct -gw -Pproduction --deploy
bundle exec awestruct -gw -Pproduction

git checkout -f master
git pull --rebase

cp -r _site/* .
git add -A
git commit -a -m "Published master to GitHub pages."
git push origin master && git checkout develop

#!/bin/sh
rm -rf _site
bin/fetch_docs.rb -f

# The awestruct github_pages deployer doesn't work on the CI machine ATM, it deletes everything on the master branch
# so we deploy manually instead
#bundle exec awestruct -gw -Pproduction --deploy
bundle exec awestruct -gw -Pproduction
git checkout master
cp -r _site/* .
git commit -a -m "Published master to GitHub pages."
git push origin master

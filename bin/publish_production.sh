#!/bin/sh
rm -rf _site
bin/fetch_docs.rb -f

# The awestruct github_pages deployer doesn't work on the CI machine ATM, it deletes everything on the master branch
# so we deploy manually instead
#bundle exec awestruct -gw -Pproduction --deploy
bundle exec awestruct -gw -Pproduction

rm -rf _master_branch
git clone --branch master git@github.com:infinispan/infinispan.github.io.git _master_branch || exit 1

cd _master_branch
cp -r ../_site/* .

git add -A
git commit -m "Published master to GitHub pages."  || exit 1
git push origin master
cd ..

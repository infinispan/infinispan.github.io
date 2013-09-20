#!/bin/sh

rm -rf _site
bin/fetch_docs.rb -f
bundle exec awestruct -g -Pstaging

git clone ssh://5229a8884382ecc523000001@stg-ispn.rhcloud.com/~/git/stg.git _stg

cd _stg
git rm -rf php
git commit -am "Clean old site"
mkdir php
cp -r ../_site/* php/
git add php
git commit -am "New site"
git push
cd ..

rm -rf _stg

echo "******************************************************"
echo "       Staging Build Complete"
echo "       ----------------------"
echo " Visit http://stg-ispn.rhcloud.com to test"
echo "******************************************************"

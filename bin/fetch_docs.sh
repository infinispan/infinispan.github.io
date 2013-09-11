#!/bin/sh

### TOOD Read these from site.yml ; possibly rewrite this script in Ruby
ISPN_REPO=git@github.com:maniksurtani/infinispan.git
DOC_ROOT=documentation/src/main/asciidoc

rm -rf docs
mkdir docs
mkdir docs/5.0.x
mkdir docs/5.1.x
mkdir docs/5.2.x
mkdir docs/5.3.x

rm -rf infinispan_srcs >> /dev/null 2>&1
git clone $ISPN_REPO infinispan_srcs
cd infinispan_srcs

git checkout t_docs_5.0.x
cp -r $DOC_ROOT/* ../docs/5.0.x/

git checkout t_docs_5.1.x
cp -r $DOC_ROOT/* ../docs/5.1.x/

git checkout t_docs_5.2.x
cp -r $DOC_ROOT/* ../docs/5.2.x/

git checkout t_docs_5.3.x
cp -r $DOC_ROOT/* ../docs/5.3.x/

cd ..
rm -rf infinispan_srcs

echo "*********************************************************************"
echo "   Infinispan docs retrieved and ready to be rendered with site"
echo "*********************************************************************"
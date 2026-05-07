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

# Clone tutorials repo and generate guide metadata
echo "Building tutorial guides..."
rm -rf _tmp_tutorials
git clone --depth 1 --branch main https://github.com/infinispan/infinispan-simple-tutorials.git _tmp_tutorials
cd _tmp_tutorials
./mvnw clean package -DskipTests=true
./mvnw -Pguides -pl docs-maven-plugin package -q
cd ..

# Copy generated guide data into Jekyll source
cp _tmp_tutorials/target/guides/index.yaml _data/guides.yaml
mkdir -p _guides
cp _tmp_tutorials/target/guides/guides/*.adoc _guides/

# Cleanup
rm -rf _tmp_tutorials
echo "Tutorial guides ready."

# Build the site
bundle exec jekyll build

# Workflow only fetches develop, we need to fetch also master
git fetch origin master
git checkout -f master
git pull --rebase

cp -r _site/* .
git add -A
git commit -a -m "Published master to GitHub pages."
git push origin master && git checkout develop

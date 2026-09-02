#!/bin/sh

# Fail fast on errors
set -e

# Recover if a previous run was interrupted while on the publish branch,
# which may have left the working tree empty
if [ "$(git symbolic-ref -q --short HEAD)" = "_site_publish" ]; then
    git checkout -f develop
fi
git branch -D _site_publish 2>/dev/null || true

rm -rf _site
mkdir _site
# Put bundles in a known path
bundle config set path $HOME/.bundle
# Update gems
if ! [ -x "$(command -v bundle)" ]; then
    echo "Bundler missing"
    gem install bundler:4.0.20
fi
#
bundle install

# Clone tutorials repo and generate guide metadata
echo "Building tutorial guides..."
rm -rf _tmp_tutorials
git clone --depth 1 --branch main https://github.com/infinispan/infinispan-simple-tutorials.git _tmp_tutorials
cd _tmp_tutorials
./mvnw clean install -DskipTests=true
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

# Rebuild master as a single orphan commit so no history is preserved
git checkout --orphan _site_publish
git rm -rf .
# Restore .gitignore (deleted above) so build artifacts are not committed
git checkout develop -- .gitignore
cp -r _site/. .
git add -A
git commit -m "Published master to GitHub pages."
git push --force origin _site_publish:master
git checkout develop
git branch -D _site_publish
git branch -f master origin/master || true

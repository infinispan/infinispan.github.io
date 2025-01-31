#!/bin/bash
REPO=github.com/infinispan/infinispan
BASEDIR=$(dirname "$0")/..
CONFIG_FILE="$BASEDIR/_data/ispn.yml"

update_version ()
{
  echo -n "Processing $1: "
  BASE_VERSION=$(yq ".$1.minor_version" "$CONFIG_FILE")

  LATEST_VERSION=$(gh release list -R $REPO |cut -f1|grep "^$BASE_VERSION"|head -n1)
  VERSION_INFO=$(gh release view -R $REPO $LATEST_VERSION --json publishedAt,url|yq -r "[.publishedAt,.url]|@csv"|tr -d \")

  echo "$LATEST_VERSION"

  IFS=, read -r RELEASE_DATE URL <<< "$VERSION_INFO"
  RELEASE_DATE=$(date -d"$RELEASE_DATE" +%Y/%m/%d)

  yq -i "
   .$1.version = \"$LATEST_VERSION\" |
   .$1.release_date = \"$RELEASE_DATE\" |
   .$1.maven_latest = \"$LATEST_VERSION\" |
   .$1.fixed_issues = \"$URL\" |
   .$1.download.server = \"https://github.com/infinispan/infinispan/releases/download/$LATEST_VERSION/infinispan-server-$LATEST_VERSION.zip\" |
   .$1.download.docker_native = \"quay.io/infinispan/server-native:$LATEST_VERSION-1\" |
   .$1.download.docker_cli = \"quay.io/infinispan/cli:$LATEST_VERSION-1\" |
   .docs.infinispan.\"$2\".core.html = \"org.infinispan:infinispan-docs:$LATEST_VERSION:zip:html\"
  " "$CONFIG_FILE"
}

update_version "stable" "15.1.x"
#update_version "unstable" "15.2.x"
update_version "old.\"15.0\"" "15.0.x"
update_version "old.\"14.0\"" "14.0.x"


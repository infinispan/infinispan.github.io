#!/bin/bash
JIRA_URL="https://issues.redhat.com/rest/api/latest"
RELEASE_NOTES_URL="https://issues.redhat.com/secure/ReleaseNote.jspa"
PROJECT="ISPN"
BASEDIR=$(dirname "$0")/..
CONFIG_FILE="$BASEDIR/_data/ispn.yml"

update_version ()
{
  echo -n "Processing $1: "
  BASE_VERSION=$(yq ".$1.minor_version" "$CONFIG_FILE")

  LATEST_VERSION=$(curl -s -H "Authorization: Bearer $TOKEN" "$JIRA_URL/project/$PROJECT/versions"|yq -r ".[]| select(.released==true)|select(.name | match(\"^$BASE_VERSION.\")) |.name"|sort -V|tail -n1)
  VERSION_INFO=$(curl -s -H "Authorization: Bearer $TOKEN" "$JIRA_URL/project/$PROJECT/versions"|yq -r ".[]| select(.name==\"$LATEST_VERSION\")|[.projectId,.id,.userReleaseDate]|@csv"|tr -d \")

  echo "$LATEST_VERSION"

  IFS=, read -r PROJECT_ID RELEASE_ID RELEASE_DATE <<< "$VERSION_INFO"

  yq -i "
   .$1.version = \"$LATEST_VERSION\" |
   .$1.release_date = \"$RELEASE_DATE\" |
   .$1.maven_latest = \"$LATEST_VERSION\" |
   .$1.fixed_issues = \"$RELEASE_NOTES_URL?projectId=$PROJECT_ID&version=$RELEASE_ID\" |
   .$1.download.server = \"https://downloads.jboss.org/infinispan/$LATEST_VERSION/infinispan-server-$LATEST_VERSION.zip\" |
   .$1.download.docker_native = \"quay.io/infinispan/server-native:$LATEST_VERSION-1\" |
   .$1.download.docker_cli = \"quay.io/infinispan/cli:$LATEST_VERSION-1\"
  " "$CONFIG_FILE"
}

update_version "stable"
update_version "old.\"14.0\""
update_version "old.\"13.0\""
update_version "old.\"12.1\""
update_version "old.\"12.0\""

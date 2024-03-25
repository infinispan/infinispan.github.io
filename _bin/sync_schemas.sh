#!/bin/sh

# Fail fast on errors
set -e

KEY="${HOME}/.ssh/infinispan"
USER="infinispan"
PORT="2222"
HOST="filemgmt-prod-sync.jboss.org"
REMOTE_DIR="/schema_htdocs/infinispan/"

WD=$(dirname $0)

pushd "${WD}/../schemas"
rsync -rvm -e "ssh -o StrictHostKeyChecking=accept-new -i ${KEY} -p ${PORT}" --include='*.xsd' --exclude='server/*' --exclude='*' ${USER}@${HOST}:${REMOTE_DIR} .
popd

git add -A
git commit -a -m "Sync schemas"
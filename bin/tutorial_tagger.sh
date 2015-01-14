#!/bin/bash
git checkout master
echo "### Removing old tags (local + remote) ###"
for i in .git/refs/tags/step-*; do 
	TAG=`basename "$i"`
	echo $TAG
	git tag -d "$TAG"
	git push origin :"$TAG"
done
echo "### Tagging all commits ###"
COMMITS=`git log --reverse|grep commit|cut -f 2 -d ' '`
STEP=0
for COMMIT in $COMMITS; do
	LOG=`git log --oneline $COMMIT|head -n 1|cut -f 2 -d ' '`
	echo $STEP $LOG
	git tag -a "step-$STEP" -m "$LOG" $COMMIT
	STEP=$((STEP+1))
done
echo "### Done ###"
echo "Don't forget to git push -f origin --tags"


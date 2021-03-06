#!/bin/bash

set -e;

TMPDIR=`mktemp -d`
echo "Working in $TMPDIR"
cd $TMPDIR

git init;

echo "Copying"
cp -r $TRAVIS_BUILD_DIR/_site/* .
touch .nojekyll

git add -A;
git commit -m "Deploying from $(date -u +"%Y-%m-%dT%H:%M:%SZ")";
git remote add origin git@github.com:${TRAVIS_REPO_SLUG}.git
ls
git push origin master --force;

cd ${TRAVIS_BUILD_DIR}

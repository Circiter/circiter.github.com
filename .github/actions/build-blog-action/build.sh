#!/bin/sh

#!/usr/bin/env bash
# Stop execution on a first error (needs bash).
#set -eu; set -o pipefail

apk update
apk upgrade
# FIXME: Is the nodejs really needed?
apk add zlib-dev build-base libxml2-dev libxslt-dev \
    readline-dev libffi-dev ruby-dev yaml-dev zlib \
    libxml2 ruby-io-console readline libxslt \
    ruby yaml libffi nodejs ruby-irb ruby-json ruby-rake \
    git bash curl ttf-freefont fontconfig \
    ruby-bundler ruby-bigdecimal imagemagick \
    ruby-json # perl wget

#gem install bundler json jekyll
gem install --no-document jekyll

#tlmgr install <package>
tlmgr update --self
tlmgr install Type1fonts concmath-fonts collection-fontsextra collection-latexextra collection-langcyrillic xypic collection-mathextra

#bundle clean
#bundle config <name> <value>
#BUNDLE_PATH=`pwd`/.bundle

cp .gemrc $HOME/

bundle install

mkdir $FOLDER

JEKYLL_ENV=production bundle exec jekyll build --trace

cd "$FOLDER"
if [ "x$CNAME" != x ]; then
  echo "$CNAME" > CNAME
fi
cd ..

COMMIT_EMAIL="${GITHUB_ACTOR:-github-pages-deploy-action}@users.noreply.github.com"

COMMIT_NAME="${GITHUB_ACTOR:-GitHub Pages Deploy Action}"

git config --global user.email "${COMMIT_EMAIL}"
git config --global user.name "${COMMIT_NAME}"

REPOSITORY_PATH="https://${ACCESS_TOKEN:-"x-access-token:$GITHUB_TOKEN"}@github.com/${GITHUB_REPOSITORY}.git"

rm -r .git
mkdir result
cd result
git init
mv ../$FOLDER/* .
git add --all --force
git commit --quiet --allow-empty -m -
git push --force "$REPOSITORY_PATH" $BRANCH

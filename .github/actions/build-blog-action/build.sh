#!/bin/sh

#sudo apt-get install texlive-publishers texlive-latex-recommended texlive-latex-extra \
#    texlive-fonts-recommended texlive-fonts-extra

apk update
apk upgrade
apk add curl wget bash git ruby ruby-dev ruby-bundler ruby-bigdecimal

#apk add jekyll

#ruby -S gem install jekyll github-pages kramdown rouge

BUNDLE_PATH=`pwd`/.bundle

#gem install jekyll kramdown rouge github-pages
bundle install

#latex --version

mkdir $FOLDER

[ -d .bundle ] && ls -a ".bundle/"

bundle exec jekyll build --trace
#ruby -S jekyll build --trace

cd "$FOLDER"
#echo > .nojekyll
if [ -e index.html ]; then mv index.html _.html; fi
echo 'under construction' > index.html
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

#git push --quiet --force https://${{github.actor}}:${{secrets.GITHUB_TOKEN}}@github.com/${{github.repository}} master

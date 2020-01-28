#!/bin/sh

bundle install

echo 'Files in ' `pwd` ':'
ls -a
#mkdir --parents "./$FOLDER/.github/workflows"
#touch "./$FOLDER/.github/workflows/workflow.yml"
#echo Moving...
#cat ./post_workflow > "./$FOLDER/.github/workflows/workflow.yml"
#echo Ok.

bundle exec jekyll build --trace

cd "./$FOLDER"
echo > .nojekyll
if [ -e index.html ]; then mv index.html _.html; fi
echo 'under construction' > index.html
cd ..

# Installs Git and jq.
apt-get update
apt-get install -y git
apt-get install -y jq

# Gets the commit email/name if it exists in the push event payload.
COMMIT_EMAIL=`jq '.pusher.email' ${GITHUB_EVENT_PATH}`
COMMIT_NAME=`jq '.pusher.name' ${GITHUB_EVENT_PATH}`

# If the commit email/name is not found in the event payload then it falls back to the actor.
if [ -z "$COMMIT_EMAIL" ]
then
  COMMIT_EMAIL="${GITHUB_ACTOR:-github-pages-deploy-action}@users.noreply.github.com"
fi

if [ -z "$COMMIT_NAME" ]
then
  COMMIT_NAME="${GITHUB_ACTOR:-GitHub Pages Deploy Action}"
fi

# Configures Git.
git init
git config --global user.email "${COMMIT_EMAIL}"
git config --global user.name "${COMMIT_NAME}"

## Initializes the repository path using the access token.
REPOSITORY_PATH="https://${ACCESS_TOKEN:-"x-access-token:$GITHUB_TOKEN"}@github.com/${GITHUB_REPOSITORY}.git"

# Checks out the base branch to begin the deploy process.
git checkout "${BASE_BRANCH:-master}"

if [ "x$CNAME" != x ]; then
  echo "$CNAME" > "$FOLDER/CNAME"
fi

echo 'Files in' "$FOLDER/"
ls "$FOLDER/" -a

rm -r .git
git clone "$REPOSITORY_PATH"
REP=`basename "$GITHUB_REPOSITORY"`
cd $REP
git checkout "$BRANCH"
echo Files in $BRANCH before moving are
ls -a
cd ..
cp -r "$FOLDER/*" "$REP"
cd $REP
echo Files in $BRANCH after moving are
ls -a
if [ -d _site ]; then rm -r _site; fi
echo empty > .nojekyll
git add --all .
git commit --quiet --allow-empty -m _
git push --force "$REPOSITORY_PATH" "$BRANCH"

# Commits the data to Github.
#git add -f $FOLDER
#git commit --quiet --allow-empty -m -
#git push --force "$REPOSITORY_PATH" "$BRANCH"
#git push $REPOSITORY_PATH `git subtree split --prefix $FOLDER ${BASE_BRANCH:-master}`:$BRANCH --force

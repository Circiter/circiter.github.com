#!/bin/sh

bundle install

bundle exec jekyll build --trace

cd "./$FOLDER"
#echo > .nojekyll
if [ -e index.html ]; then mv index.html _.html; fi
echo 'under construction' > index.html
if [ "x$CNAME" != x ]; then
  echo "$CNAME" > CNAME
fi
cd ..

# Installs Git and jq.
#apt-get update
#apt-get install -y git
#apt-get install -y jq

# Gets the commit email/name if it exists in the push event payload.
#COMMIT_EMAIL=`jq '.pusher.email' ${GITHUB_EVENT_PATH}`
#COMMIT_NAME=`jq '.pusher.name' ${GITHUB_EVENT_PATH}`

# If the commit email/name is not found in the event payload then it falls back to the actor.
#if [ -z "$COMMIT_EMAIL" ]
#then
  COMMIT_EMAIL="${GITHUB_ACTOR:-github-pages-deploy-action}@users.noreply.github.com"
#fi

#if [ -z "$COMMIT_NAME" ]
#then
  COMMIT_NAME="${GITHUB_ACTOR:-GitHub Pages Deploy Action}"
#fi

# Configures Git.
#git init
git config --global user.email "${COMMIT_EMAIL}"
git config --global user.name "${COMMIT_NAME}"

## Initializes the repository path using the access token.
REPOSITORY_PATH="https://${ACCESS_TOKEN:-"x-access-token:$GITHUB_TOKEN"}@github.com/${GITHUB_REPOSITORY}.git"

#git checkout "${BASE_BRANCH:-master}"

#rm -r .git
#git clone "$REPOSITORY_PATH"
#cd `basename "$GITHUB_REPOSITORY"`
#git checkout "$BRANCH"
#for i in `ls "../$FOLDER/"`; do
#    cp -r "../$FOLDER/$i" .
#done

#git add --all .
#git add -f "$FOLDER"
echo moving files...
mv $FOLDER .$FOLDER
rm -r * .github
mv .$FOLDER/* .
rm -r .$FOLDER
git add --all --force
git commit --quiet --allow-empty -m -
echo pushing...
git push --force "$REPOSITORY_PATH" "${BRANCH:-master}"

# Commits the data to Github.
#git add -f $FOLDER
#git commit --quiet --allow-empty -m -
#git push --force "$REPOSITORY_PATH" "$BRANCH"

#git push $REPOSITORY_PATH `git subtree split --prefix $FOLDER ${BASE_BRANCH:-master}`:$BRANCH --force

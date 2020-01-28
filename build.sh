#!/bin/sh

bundle install

mkdir "$FOLDER"
mkdir "$FOLDER/.github"
mkdir "$FOLDER/.github/workflows"
echo 'Files in source branch:'
ls -a
mv post_workflow "$FOLDER/.github/workflow/workflow.yml"

bundle exec jekyll build --trace

echo Destination folder is "$FOLDER"
cd "$FOLDER"
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

# Directs the action to the the Github workspace.
cd $GITHUB_WORKSPACE

# Configures Git.
git init
git config --global user.email "${COMMIT_EMAIL}"
git config --global user.name "${COMMIT_NAME}"

## Initializes the repository path using the access token.
REPOSITORY_PATH="https://${ACCESS_TOKEN:-"x-access-token:$GITHUB_TOKEN"}@github.com/${GITHUB_REPOSITORY}.git"

# Checks out the base branch to begin the deploy process.
git checkout "${BASE_BRANCH:-master}"

if [ "$CNAME" ]; then
  echo $CNAME > $FOLDER/CNAME
fi

echo 'Files:'
ls "$FOLDER/" -a

# Commits the data to Github.
git add -f $FOLDER

git commit -m "Deploying to ${BRANCH} from ${BASE_BRANCH:-master} ${GITHUB_SHA}" --quiet
git push $REPOSITORY_PATH `git subtree split --prefix $FOLDER ${BASE_BRANCH:-master}`:$BRANCH --force

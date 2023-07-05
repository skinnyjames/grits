#! /bin/bash

build_directory="public"
build_branch="pages"

# delete previous site built, if it exists
if [ -d "$build_directory" ]; then
  echo "Found previous site build, deleting it"
  rm -rf $build_directory
fi

# get remote origin url, e.g. https://codeberg.org/user/repo.git
remote_origin_url=$(git config --get remote.origin.url)

# generate hugo static site to `build` directory
make build

# initialize a git repo in build_directory and checkout to build_branch
cd $build_directory
git init
git checkout -b $build_branch

# stage all files except .gitignore (don't want it in the static site)
git add -- . ':!.gitignore'

# commit static site files and force push to build_branch of the origin
git commit -m "build: update static site"
git remote add origin $remote_origin_url
git push --force origin $build_branch


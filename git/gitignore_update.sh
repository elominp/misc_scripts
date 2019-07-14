#!/usr/bin/env bash

GIT_REPO_ROOT="$(dirname $(git rev-parse --git-dir . | head -1))"
GITIGNORE="$GIT_REPO_ROOT/.gitignore"

echo -e "[ \e[1;92mStart\e[0m ] Adding untracked files to $GITIGNORE"
echo "# [$(date +'+%Y/%m/%d %H:%M:%S')] Automatic .gitignore update" >> $GITIGNORE

for file in $(git ls-files --others --exclude-standard --full-name $GIT_REPO_ROOT); do
  echo "[ Adding ] Adding $file to $GITIGNORE"
  echo $file >> $GITIGNORE
done

echo -e "[ \e[1;92mDone\e[0m ] Adding untracked files to $GITIGNORE"

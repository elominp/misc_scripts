#!/usr/bin/env bash

SPECIAL_REPO=""
BASE_REPO="avr-random"
AVR_RANDOM_REPO="https://github.com/elominp/AVRRandom.git;avr-random;master"
MISC_SCRIPTS_REPO="https://github.com/elominp/misc_scripts.git;misc-scripts;master"
JSXLSXIO_REPO="https://github.com/elominp/jsxlsxio.git;jsxlsxio;master"
REPO_LIST=($AVR_RANDOM_REPO $MISC_SCRIPTS_REPO $JSXLSXIO_REPO)
TMP_DIR="tmp"

# Args: reason
abort() {
    echo -e "[$(date +'+%Y/%m/%d %H:%M:%S')][ \e[1;91mAborting\e[0m ] $1"
    exit 1
}

# Args: path to return, reason
fail() {
    echo -e "[$(date +'+%Y/%m/%d %H:%M:%S')][ \e[1;91mFailure\e[0m ] $2"
    cd $1
}

# Args: path to return, reason
success() {
    echo -e "[$(date +'+%Y/%m/%d %H:%M:%S')][ \e[1;92mDone\e[0m ] $2"
    cd $1
}

# Args: repository URL, dest name, branch
clone_repository() {
    RET_PWD=$PWD
    mkdir -p $TMP_DIR
    CLONE_LOG="$2.clone.log"
    cd $TMP_DIR
    git clone $1 --recursive $2 > $CLONE_LOG 2>&1 || (fail $RET_PWD "Unable to clone $1 repository into $2, see $PWD/$CLONE_LOG for more details" && return 1)
    cd $2 || (fail $RET_PWD "Unable to move into cloned $2 directory" && return 1)
    CHECKOUT_LOG="$2.checkout.$3.log"
    git checkout $3 > $CHECKOUT_LOG 2>&1 || (fail $RET_PWD "Unable to checkout $3 branch, see $PWD/$CLONE_LOG for more details" && return 1)
    success $RET_PWD "Cloning $1 repository into $2 using $3 branch"
}

clone_repositories() {
    for REPO in ${REPO_LIST[@]}; do
        ARGS=()
        IFS=';' read -ra ARGS <<< "$REPO"
        clone_repository ${ARGS[0]} ${ARGS[1]} ${ARGS[2]} || (fail "Unable to clone repository ${ARGS[0]}" && return 1)
    done
    success $PWD "Cloned all repositories"
}

# Args: repository folder name
merge_repository() {
    RET_PWD=$PWD
    mv "$TMP_DIR/$1/.git" "$BASE_REPO/.$1.git" || fail $RET_PWD "Unable to move .git folder from $1 into monorepo"
    cd "$TMP_DIR/$1" || fail $RET_PWD "Unable to change directory into $TMP_DIR/$1"
    FILES=$(find .)
    cd - || abort "Unable to change back to previous directory"
    for file in $FILES; do
        mv -n "$TMP_DIR/$1/$file" "$BASE_REPO/$file" > "$TMP_DIR/$1.merge.log" 2>&1
    done
    success $RET_PWD "Merged $1 repository"
}

merge_base_repository() {
    mv "$TMP_DIR/$BASE_REPO" $BASE_REPO || fail $PWD "Unable to move base repository from temporary folder to destination"
    success $PWD "Moved base repository from temporary folder to destination"
}

merge_special_repository() {
    for REPO in $REPO_LIST; do
        if [ ${REPO[1]} == $SPECIAL_REPO ]; then
            merge_repository $REPO || (fail $PWD "Unable to merge special repository" && return 1)
            # Write here special actions
        fi
    done
    success $PWD "Merged special repository"
}

merge_repositories() {
    merge_base_repository || (fail $PWD "Unable to merge base repository" && return 1) 
    if [ "$BASE_REPO" != "$SPECIAL_REPO" -a "$SPECIAL_REPO" != "" ]; then
        merge_special_repository || fail $PWD "Unable to merge special repository"
    fi
    for REPO in ${REPO_LIST[@]}; do
        INFO=()
        IFS=';' read -ra INFO <<< "$REPO"
        if [ "${INFO[1]}" != "$BASE_REPO" -a "${INFO[1]}" != "$SPECIAL_REPO" ];
        then
            merge_repository ${INFO[1]} || fail $PWD "Unable to merge repositories into monorepo"
        else
            echo -e "[$(date +'+%Y/%m/%d %H:%M:%S')][ \e[1;93mSkipped\e[0m ] ${INFO[1]} already merged"
        fi
    done
    success $PWD "Merged repositories into monorepo"
}

update_gitignore() {
    cd $BASE_REPO

    GIT_REPO_ROOT="$(dirname $(git rev-parse --git-dir . | head -1))"
    GITIGNORE="$GIT_REPO_ROOT/.gitignore"

    echo -e "[$(date +'+%Y/%m/%d %H:%M:%S')][ \e[1;92mStart\e[0m ] Adding untracked files to $GITIGNORE"
    echo "# [$(date +'+%Y/%m/%d %H:%M:%S')] Automatic .gitignore update" >> $GITIGNORE

    for file in $(git ls-files --others --exclude-standard --full-name $GIT_REPO_ROOT); do
        echo "[ Adding ] $file to $GITIGNORE"
    echo $file >> $GITIGNORE
    done

    success $OLDPWD "Adding untracked files to $GITIGNORE"
}

clone_repositories || abort "Failed to clone repositories"
merge_repositories || abort "Failed to merge repositories"
update_gitignore

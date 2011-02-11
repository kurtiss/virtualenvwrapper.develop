#
# virtualenvwrapper.develop plugin
#

develop_verify_current_environment() {
    virtualenvwrapper_verify_workon_home || return 1
    virtualenvwrapper_verify_active_environment || return 1
    site_packages="`virtualenvwrapper_get_site_packages_dir`"

    if [ ! -d "${site_packages}" ]
    then
        echo "ERROR: currently-active virtualenv does not appear to have a site-packages directory" >&2
        return 1
    fi

    return 0
}

develop_ensure_devfile() {
    develop_verify_current_environment || return 1

    parent_virtualenv=$(python -c "import os; print os.path.basename(\"$VIRTUAL_ENV\")")
    parent_cfg_path="$VIRTUAL_ENV/etc/$parent_virtualenv/virtualenvwrapper.develop"
    parent_develop_file="$parent_cfg_path/environments.txt"

    mkdir -p $parent_cfg_path
    touch $parent_develop_file   

    echo $parent_develop_file
    return 0
}

develop() {
    parent_develop_file=$(develop_ensure_devfile) || return 1

    if [ "$*" = "" ]
    then
        echo "Usage: develop dir [dir ...]"
        if [ -f "$parent_develop_file" ]
        then
            echo
            echo "Existing projects under development:"
            cat "$parent_develop_file"
        fi
        return 1
    fi
    
    current_dir="`pwd`"
    
    for develop_env_name in "$@"
    do
        develop_env_needs_setup=1

        while read line
        do
            if [ "$line" = "$develop_env_name" ]
            then
                echo "$develop_env_name is already under development."
                develop_env_needs_setup=0
                break
            fi
        done < $parent_develop_file

        if [ "$develop_env_needs_setup" = "1" ]
        then
            echo "Setting up $develop_env_name for development..."
            cd "$WORKON_HOME/$develop_env_name"
            python setup.py develop
            echo
            echo "$develop_env_name" > $parent_develop_file
        fi
    done
    
    cd $current_dir

    return 0
}

undevelop() {
    parent_develop_file=$(develop_ensure_devfile) || return 1

    if [ "$*" = "" ]
    then
        echo "Usage: undevelop dir [dir ...]"
        if [ -f "$parent_develop_file" ]
        then
            echo
            echo "Existing projects under development:"
            cat "$parent_develop_file"
        fi
        return 1
    fi
    
    current_dir="`pwd`"
    cd `virtualenvwrapper_get_site_packages_dir`
    
    for develop_env_name in "$@"
    do
        develop_env_needs_torndown=0

        while read line
        do
            if [ "$line" = "$develop_env_name" ]
            then
                develop_env_needs_torndown=1
                break
            fi
        done < $parent_develop_file
        
        if [ "$develop_env_needs_torndown" = "1" ]
        then
            echo "Tearing down $develop_env_name from development..."
            rm "$develop_env_name.egg-link"
            sed "/^$develop_env_name$/d" $parent_develop_file > $parent_develop_file
        else
            echo "$develop_env_name is not under development."
        fi
    done
    
    cd $current_dir
    
    return 0
}

develop_newproject_cp() {
    if [ ! -f "$3" ]
    then
        eval "$VIRTUALENVWRAPPER_PYTHON -c \"import pkgutil; print pkgutil.get_data('virtualenvwrapper.develop', 'develop_newproject_data/$2')\"" | sed -e "s/\${PROJECT}/$1/" > "$3"
    fi
}

develop_selfupdate() {
    sudo pip install git+http://github.com/kurtiss/virtualenvwrapper.develop.git\#egg=virtualenvwrapper --upgrade
    # NOTE: will have to open a new shell for now.
}

newproject() {
    mkdir -p "$1"
    mkvirtualenv --no-site-packages "$1"
    cd "$1"
    easy_install pip
    mkdir -p etc/pip
    mkdir -p etc/fabric
    mkdir -p "src/$1"
    mkdir -p "etc/$1"
    rm -f etc/pip/develop.txt

    develop_newproject_cp "$1" __init__.py.txt "src/$1/__init__.py"
    develop_newproject_cp "$1" version.py.txt "src/$1/version.py"
    develop_newproject_cp "$1" gitignore.txt ".gitignore"
    develop_newproject_cp "$1" README.txt "README"
    develop_newproject_cp "$1" setup.py.sample.txt "setup.py.sample"

    touch etc/pip/develop.txt
    touch etc/pip/requirements.txt

    pip install -r etc/pip/develop.txt
}

git-safe-merge() {
    # don't want to lose any commits because we're floating in space...
    working_head=$(git symbolic-ref HEAD 2>/dev/null)
    if [ ! -n "$working_head" ]; then
        echo "Fatal: Can't begin merge, because you're not on a branch, and that's just scary." 1>&2
        return 1
    fi

    working_branch=$(expr "$working_head" : 'refs/heads/\(.*\)')

    recv_remote=$(git config branch.$2.remote)
    recv_remote=${send_remote:-"origin"}

    recv_ref=$(git config branch.$2.merge)
    recv_ref=${recv_ref:-"refs/heads/$2"}

    recv_branch=$(expr $recv_ref : 'refs/heads/\(.*\)')
    recv_tracking_branch="refs/remotes/$recv_remote/$recv_branch"

    # checkout the receiving branch if we're not on it
    if [ ! "$working_branch" = "$2" ]; then
        checkout_error=$(git checkout "$2" 2>&1 >/dev/null)
        if [ "$?" != 0 ]; then
           echo "Fatal: can't begin merge, because of problems with your working branch." 1>&2
           echo ""
           echo "    $checkout_error"
           return 1
        fi
    fi

    # if any local commits exist in the receiving branch, let's just stop and take care of that first.
    recv_commit_count=$(git rev-list $recv_tracking_branch..HEAD | wc -l)
    if [ ! "$recv_commit_count" -eq "0" ]; then
        git checkout "$working_branch" > /dev/null 2>&1
        echo "Fatal: Can't begin merge, because your local receiving branch ($2) is ahead of its remote ($recv_remote/$recv_branch) by $recv_commit_count commit(s)." 1>&2
        return 1
    fi

    # it's also possible that we're behind our tracking branch, so let's get up to date.
    git pull $recv_remote $2 > /dev/null 2>&1 

    # determine the remote for the sending branch, assuming origin
    send_remote=$(git config branch.$1.remote)
    send_remote=${send_remote:-"origin"}

    # determine the ref for the sending branch, assuming refs/heads/$1
    send_ref=$(git config branch.$1.merge)
    send_ref=${send_ref:-"refs/heads/$1"}

    send_branch=$(expr $send_ref : 'refs/heads/\(.*\)')
    send_tracking_branch="refs/remotes/$send_remote/$send_branch"

    # now we make sure our index knows about the remote branch we're merging
    git fetch $send_remote $send_branch:$send_tracking_branch >/dev/null 2>&1

    # take care of the case where the sending branch is just garbage
    if [ "$?" != 0 ]; then
        git checkout "$working_branch" >/dev/null 2>&1
        echo "Fatal: Can't begin merge, because the remote '$send_remote' doesn't have a branch named '$send_branch'." >&2
        return 1
    fi

    # NOTE: if the last command succeeded, so should this one.
    git fetch $send_remote $send_branch:$send_branch >/dev/null 2>&1

    # TODO: figure out what happens when you provide the same value for send/recv branches

    # if any local commits exist in the sending branch, let's just stop and take care of that first.
    checkout_error=$(git checkout "$send_branch" 2>&1 >/dev/null)
    if [ "$?" != 0 ]; then
        # NOTE: the only way this would happen is if $working_branch = $recv_branch
        echo "Fatal: can't begin merge, because of problems with your working branch." 1>&2
        echo "" 1>&2
        echo "    ${checkout_error//$'\n'/$'\n'    }" 1>&2
        return 1
    fi
  
    send_commit_count=$(git rev-list $send_tracking_branch..HEAD | wc -l)
    if [ ! "$send_commit_count" -eq "0" ]; then
        git checkout "$working_branch" > /dev/null 2>&1
        echo "Fatal: Can't begin merge because your local sending branch ($1) is ahead of its remote ($send_remote/$send_branch) by $send_commit_count commit(s)." 1>$2
        return 1
    fi

    # it's also possible that we're behind our tracking branch, let's fast-forward
    git pull $send_remote $send_branch >/dev/null 2>&1
    
    # create a clean branch for the merge to take place in
    merge_branch="$recv_branch-merge-$send_branch"
    git checkout -b $merge_branch > /dev/null 2>&1

    # attempt the merge
    merge_output=$(git merge "$recv_branch")
    if [ "$?" != 0 ]; then
        echo "Fatal: Trvial merge was unsuccessful. Your current branch is '$merge_branch'. Complete the merge manually from here." 1>&2
        echo "" 1>&2
        echo "    ${merge_output//$'\n'/$'\n'    }" 1>&2
        echo "" 1>&2
        echo "    To complete this merge, follow the directions above, finishing with a merge commit. Then perform the following:" 1>&2
        echo "    $ git checkout $recv_branch" 1>&2
        echo "    $ git merge $merge_branch" 1>&2
        echo "    $ git branch -D $merge_branch" 1>&2
        echo "" 1>&2
        echo "    Finally, push the merged branch to its remote." 1>&2
        echo "    $ git push $recv_remote $recv_branch" 1>&2
        return 1
    fi 

    # there really should not be any problems at this stage
    git checkout "$2" >/dev/null 2>&1
    git merge "$merge_branch" >/dev/null 2>&1
    git branch -D "$merge_branch" >/dev/null 2>&1
    
    git checkout "$working_branch" >/dev/null 2>&1
    echo "Trivial merge was successful.  Your current branch is '$working_branch'."
    echo ""
    echo "    To push $recv_branch to its remote, perform the following:"
    echo "    $ git checkout $recv_branch && git push $recv_remote $recv_branch"
    echo ""
    echo "    To see the commits you will be pushing:"
    echo "    $ git checkout $recv_branch && git rev-list $recv_tracking_branch..HEAD"
    return 0
}

git-wipeout() {
    git checkout master >/dev/null 2>&1
    git branch -D "$1"
    git push origin :$1
}
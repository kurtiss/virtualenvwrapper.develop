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
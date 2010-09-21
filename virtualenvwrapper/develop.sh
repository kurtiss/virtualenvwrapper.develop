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
        eval "$VIRTUALENVWRAPPER_PYTHON -c \"import pkgutil; print pkgutil.get_data('virtualenvwrapper.develop', '$2')\"" | sed -e "s/\${PROJECT}/$1/" > "$3"
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

    develop_newproject_cp "$1" newproject/__init__.py.txt "src/$1/__init__.py"
    develop_newproject_cp "$1" newproject/version.py.txt "src/$1/version.py"
    develop_newproject_cp "$1" newproject/gitignore.txt ".gitignore"
    develop_newproject_cp "$1" newproject/postactivate.txt "bin/postactivate"
    develop_newproject_cp "$1" newproject/predeactivate.txt "bin/predeactivate"
    develop_newproject_cp "$1" newproject/pip_develop.txt "etc/pip/develop.txt"
    develop_newproject_cp "$1" newproject/fabfile.py.txt "etc/fabric/fabfile.py"
    develop_newproject_cp "$1" newproject/README.txt "README"
    develop_newproject_cp "$1" newproject/setup.py.sample.txt "setup.py.sample"

    touch etc/pip/requirements.txt

    pip install -r etc/pip/develop.txt
}
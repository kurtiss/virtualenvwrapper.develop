__mkproject_usage() {
    local CMDNAME="$1"
    cat <<EOF
Usage: $CMDNAME PROJECT_NAME [options]
Make a new project, structured for virtualenvwrapper.develop-style development/testing.

Options:
EOF

    cat <<EOF | column -s\& -t
-o & Instead of only adding new files, also overwrite any existing files.
-i & Install project dependencies after creation.
-h & Display this help and exit.
EOF
}

__mkproject_render() {
    local PROJECT_NAME="$1"
    local IN_FILE="$2"
    local OUT_FILE="$3"

    local GET_IN_FILE="import pkgutil; print pkgutil.get_data('virtualenvwrapper.develop', 'develop_mkproject_data/$IN_FILE')"
    local READ_IN_FILE="$VIRTUALENVWRAPPER_PYTHON -c \"$GET_IN_FILE\""
    local REPLACE_PROJECT_VAR="s/\${PROJECT}/$PROJECT_NAME/"

    eval "$READ_IN_FILE" | sed -e "$REPLACE_PROJECT_VAR"  > "$OUT_FILE"
}

__mkproject_render_update() {
    local OUT_FILE="$3"
    if [ ! -f "$OUT_FILE" ]; then
        eval __mkproject_render $*
    fi
}

mkproject() {
    virtualenvwrapper_verify_workon_home || return 1

    local CMDNAME="mkproject"
    local PROJECT_NAME="$1"
    local PROJECT_DIR="$WORKON_HOME/$PROJECT_NAME"
    local USAGE="__mkproject_usage $CMDNAME"
    local RENDER="__mkproject_render $PROJECT_NAME"
    local RENDER_UPDATE="__mkproject_render_update $PROJECT_NAME"
    local INSTALL_PROJECT="0"
    
    # PROJECT_NAME unspecified
    shift
    if [ "$?" -gt "0" ]; then
        eval $USAGE
        return 1
    fi

    SET_PARAMS=$(getopt oih $*)
    if [ "$?" -gt "0" ]; then
        eval $USAGE
        return 1
    fi

    eval set -- $SET_PARAMS

    local RENDER_PROJECT_FILE="$RENDER_UPDATE"
    if [ -f "$PROJECT_DIR" ]; then
        local RENDER_VIRTUALENV_FILE="$RENDER_UPDATE"
    else
        local RENDER_VIRTUALENV_FILE="$RENDER"
    fi

    while true; do
        case "$1" in
            -h)
                eval $USAGE
                return 0
            ;;
            -o) 
                RENDER_PROJECT_FILE="$RENDER"
                RENDER_VIRTUALENV_FILE="$RENDER"
            ;;
            -i)
                INSTALL_PROJECT="1"
            ;;
            --) shift; break ;;
        esac
        shift
    done

    # create initial virtual env
    mkvirtualenv --no-site-packages "$PROJECT_NAME"
    easy_install pip
    deactivate
    
    # update with project structure
    cd "$WORKON_HOME/$PROJECT_NAME"

    eval $RENDER_PROJECT_FILE "root:.gitignore" ".gitignore"
    eval $RENDER_PROJECT_FILE "root:README" "README"
    eval $RENDER_PROJECT_FILE "root:setup.py.sample" "setup.py.sample"

    mkdir -p etc/pip
    eval $RENDER_PROJECT_FILE "etc:pip:requirements.txt" "etc/pip/requirements.txt"
    eval $RENDER_PROJECT_FILE "etc:pip:testing.txt" "etc/pip/testing.txt"

    eval $RENDER_PROJECT_FILE "bin:install" "bin/install"
    chmod +x "bin/install"

    eval $RENDER_PROJECT_FILE "bin:integrate" "bin/integrate"
    chmod +x "bin/integrate"

    eval $RENDER_VIRTUALENV_FILE "bin:postactivate" "bin/postactivate"
    chmod +x "bin/postactivate"

    eval $RENDER_VIRTUALENV_FILE "bin:predeactivate" "bin/predeactivate"
    chmod +x "bin/predeactivate"
    
    eval $RENDER_PROJECT_FILE "bin:postactivate.cowork" "bin/postactivate.cowork"
    chmod +x "bin/postactivate.cowork"

    eval $RENDER_PROJECT_FILE "bin:predeactivate.cowork" "bin/predeactivate.cowork"
    chmod +x "bin/predeactivate.cowork"

    mkdir -p "src/$PROJECT_NAME"
    eval $RENDER_PROJECT_FILE "src:__init__.pyt" "src/$PROJECT_NAME/__init__.py"
    eval $RENDER_PROJECT_FILE "src:version.pyt" "src/$PROJECT_NAME/version.py"

    mkdir -p "src/${PROJECT_NAME}_testsuite"
    eval $RENDER_PROJECT_FILE "testsuite:__init__.pyt" "src/${PROJECT_NAME}_testsuite/__init__.py"
    eval $RENDER_PROJECT_FILE "testsuite:all.pyt" "src/${PROJECT_NAME}_testsuite/all.py"

    workon "$PROJECT_NAME"
    cdvirtualenv

    if [ "$INSTALL_PROJECT" -gt "0" ]; then
        . "bin/install" -tu        
    fi

    return 0
}
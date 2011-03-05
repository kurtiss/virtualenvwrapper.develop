develop-verify-current-environment() {
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

develop-ensure-sourced() {
    if [ "$1" ]; then
        eval $2
        exit 1
    fi
}
 
develop-selfupdate() {
    CMDNAME="develop-selfupdate"

    USAGE=$(cat <<EOF
Usage: $CMDNAME [options]
Update the virtualenvwrapper.develop command suite.

Options:
EOF
)

    USAGE=${USAGE}$(cat <<EOF | column -s\& -t
    &
    -b BRANCH & Install virtualenvwrapper.develop at the given BRANCH.
    -h & Display this help and exit.
EOF
)

    SET_PARAMS=$(getopt hb: $*)

    if [ "$?" -gt "0" ]; then
      echo "$USAGE" >&2
      return 1
    fi

    virtualenvwrapper_verify_active_environment 2>/dev/null
    if [ "$?" -lt "1" ]; then
        echo "ERROR: virtualenv is active, you probably want to run this command outside a virtualenv." >&2
        return 1
    fi

    eval set -- "$SET_PARAMS"

    PROJECT_URI="git+http://github.com/kurtiss/virtualenvwrapper.develop.git"
    BRANCH=""

    while true; do
        case "$1" in
            -h) echo "$USAGE"; return 0 ;;
            -b) shift; BRANCH="@$1" ;;
            --) shift; break ;;
        esac
        shift
    done

    sudo pip install "${PROJECT_URI}${BRANCH}#egg=virtualenvwrapper" --upgrade
    source virtualenvwrapper.sh

    return 0
}

develop-teardown() {
    unset develop-verify-current-environment
    unset develop-ensure-sourced
    unset develop-selfupdate
    unset develop-teardown
}
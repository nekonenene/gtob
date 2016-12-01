#!/bin/bash

command_name="gtob"

# init variables
gh_repo_url="" # GitHub repository URL
gh_repo_user=""
gh_repo_name=""
bb_username="" # Bitbucket username
bb_password="" # Bitbucket password
branch_name="master"
is_private=false
migrate_wiki=false

# define variables
local_repos_path="$HOME/.$command_name-tmp"
bb_api_url="https://api.bitbucket.org/2.0"
bb_ssh_url="git@bitbucket.org"
remote_url_name="origin"
color_error="\033[31;1m" # red, bold
color_warn="\033[33m" # yellow
color_reset="\033[m"

# show version info
version() {
    echo "$command_name 0.0.1 by nekonenene <hatonekoe@gmail.com>"
}

# show how to use
usage() {
    version
cat << EOF >&2

Migrate GitHub repository to Bitbucket

Usage:
    $command_name -U git@github.com:username/repo_name.git -u bitbucket_username -p bitbucket_password

Options:
    -U, --url           GitHub repository URL   (*require)
    -u, --username      Your Bitbucket username (*require)
    -p, --password      Your Bitbucket password (*require)
    -b, --branch        Specify branch name (*option, default: master)
    -P, --private       Create private Bitbucket repository (*option)
    -w, --wiki          Migrate GitHub Wiki (*option)
    -h, --help          Display this help text
    -v, --version       Display current script version

Examples:
    create the private Bitbucket repository:
        $command_name -U git@github.com:username/repo_name.git -u username -p password --private
    copy "develop" branch and GitHub Wiki:
        $command_name -U git@github.com:username/repo_name.git -u username -p password -b develop --wiki

EOF
}

# check if user input required options
check_required_items() {
    if [ -z "$gh_repo_url" ]; then
        echo -e $color_error"error: \"--url\" item is not found"$color_reset
        exit 1
    fi
    if [ -z "$bb_username" ]; then
        echo -e $color_error"error: \"--username\" item is not found"$color_reset
        exit 1
    fi
    if [ -z "$bb_password" ]; then
        echo -e $color_error"error: \"--password\" item is not found"$color_reset
        exit 1
    fi
}

# get the username and the repository name from GitHub URL
analyze_url() {
    gh_repo_user=`echo "$1" | sed "s/^.*github\.com.\([^\/]\{1,\}\)\/\([^\.]\{1,\}\).*$/\1/"`
    gh_repo_name=`echo "$1" | sed "s/^.*github\.com.\([^\/]\{1,\}\)\/\([^\.]\{1,\}\).*$/\2/"`
}

# git clone from GitHub
clone() {
    tmp_repo_path="$local_repos_path/$gh_repo_name"
    if [ -n "$gh_repo_url" ]; then
        git clone $gh_repo_url $tmp_repo_path --branch $branch_name
    fi
}

wiki_clone() {
    gh_wiki_url=`echo "$gh_repo_url" | sed "s/\.git$/.wiki/"`
    git clone $gh_wiki_url $tmp_wiki_path
}

wiki_push() {
    current_dir=`pwd`
    if [ ! -e $tmp_wiki_path ]; then
        echo -e $color_error"error: wiki directory is not exist"$color_reset
    else
        cd $tmp_wiki_path
        git remote set-url origin "$bb_ssh_url:$bb_username/$gh_repo_name.git/wiki"
        if [ ! -e Home.md ]; then
            echo "**https://bitbucket.org/$bb_username/$gh_repo_name/wiki/browse/**" >> Home.md
            git add Home.md
            git commit -m "Add Home.md"
        fi
        git push --force
        cd current_dir
    fi
}

wiki() {
    tmp_wiki_path="$tmp_repo_path.wiki"
    wiki_clone
    wiki_push
    rm -rf $tmp_wiki_path
}

# remove all tmp files (for develop)
clean_all() {
    rm -rf "$local_repos_path/*"
    echo "remove all files in \"$local_repos_path\""
}

# if the repository has .gitmodules, then rewrite submodule URL
submodule() {
    current_dir=`pwd`
    cd $tmp_repo_path
    cd $current_dir
}

# create Bitbucket repository
create_repo() {
    bb_response=`curl -X POST "$bb_api_url/repositories/$bb_username/$gh_repo_name" \
    --user "$bb_username:$bb_password" \
    -H "Content-type: application/json" \
    -d "{\"scm\": \"git\", \"is_private\": \"$is_private\", \"name\": \"$gh_repo_name\", \"has_wiki\": \"$migrate_wiki\"}"`

    # TODO: if receive {"type": "error", "error": {"fields": {"name": ["You already have a repository with this name."]}, "message": "Repository with this Slug and Owner already exists."}} then
    # echo -e $color_warn"warn: \"$gh_repo_name\" repository is already exists in Bitbucket"$color_reset
}

# git push to Bitbucket
push() {
    current_dir=`pwd`
    cd $tmp_repo_path
    git remote set-url $remote_url_name "$bb_ssh_url:$bb_username/$gh_repo_name.git"
    git push --set-upstream $remote_url_name $branch_name --force
    git push $remote_url_name --tags
    cd $current_dir
}

# main steps
migrate() {
    check_required_items
    analyze_url $gh_repo_url
    clone
    submodule
    create_repo
    push
    if $migrate_wiki; then
        wiki
    fi
    rm -rf $tmp_repo_path
}

# read options
read_opts() {
    while [ $# -gt 0 ]; do
        case $1 in
            -U | --url )
                shift
                gh_repo_url=$1
                ;;
            -u | --username )
                shift
                bb_username=$1
                ;;
            -p | --password )
                shift
                bb_password=$1
                ;;
            -b | --branch )
                shift
                branch_name=$1
                ;;
            -P | --private )
                is_private=true
                ;;
            -w | --wiki )
                migrate_wiki=true
                ;;
            -v | --version )
                version
                exit 0
                ;;
            -h | --help )
                usage
                exit 0
                ;;
            --clean )
                clean_all
                exit 0
                ;;
            * ) # default case
                echo -e $color_error"error: \"$1\" option does not exist"$color_reset
                exit 1
                ;;
        esac
        shift
    done
}

# entry point
main() {
    if !(type git >/dev/null 2>&1); then
        echo -e $color_error"error: $command_name requires \"git\", please install"$color_reset
        exit 1
    fi

    case $# in
        0 )
            usage
            exit 0
            ;;
        * )
            read_opts $@
            migrate
            exit 0
            ;;
    esac
}

main $@

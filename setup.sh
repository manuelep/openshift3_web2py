#!/bin/bash

usage="$(basename "$0") [-h] [-l=<value>] [-u=<url>] [-c=<url>] [-t=<string>] [-m=<value>] [-c] -- A script that helps you to include the desidered web2py framework version.

A url to a brand new git repository has to be passed as argument.

Optional parameters:
    -h   Show this help text and exit.
    -l*  Set the script logging level accoddingly to RFC 5424;
         Allowed values: 0-7, default: 6.
    -u*  Overwrite the web2py repository reference from wich clone the framework.
    -t*  Specify the desidered framework version expressed by commit tag (eg. 'R-2.14.6').
    -m   Include in the project a minified web2py framework;
         Allowed values: 0-1.
    -c   Remove framework cloned repository.
    -r   A git repository url where to push updates.

    *    Options require passing a value
";

# Courtesy of: https://stackoverflow.com/a/14203146/1039510
for i in "$@"
do
case $i in
    -h*|--help*)
    echo "$usage";
    exit;
    shift # past argument=value
    ;;
    -l=*|--log=*)
    LOGGING_LEVEL="${i#*=}";
    shift # past argument=value
    ;;
    -u=*|--url=*)
    URL="${i#*=}";
    shift # past argument=value
    ;;
    -o=*|--origin=*)
    UPSTREAM="${i#*=}";
    shift # past argument=value
    ;;
    -t=*|--tag=*)
    TAG="${i#*=}";
    shift # past argument=value
    ;;
    -m=*|--mini=*)
    MINIFICATION_LEVEL="${i#*=}";
    MINIFICATION_LEVEL=${MINIFICATION_LEVEL:-0};
    shift # past argument=value
    ;;
    -m*|--mini*)
    MINIFICATION_LEVEL=0;
    shift
    ;;
    -c*|--clean*)
    CLEAN=true;
    shift
    ;;
    *)
    ;;
esac
done

# Courtesy of: https://stackoverflow.com/a/33597663
# set verbose default level to info
__VERBOSE=${LOGGING_LEVEL:-6};
declare -A LOG_LEVELS
# https://en.wikipedia.org/wiki/Syslog#Severity_level
LOG_LEVELS=([0]="emerg" [1]="alert" [2]="crit" [3]="err" [4]="warning" [5]="notice" [6]="info" [7]="debug")
function .log () {
  local LEVEL=${1}
  shift
  if [ ${__VERBOSE} -ge ${LEVEL} ]; then
    echo -e "[${LOG_LEVELS[$LEVEL]}] \t $@"
  fi;
}

.log $__VERBOSE "Logging level set to $__VERBOSE / 7 (i.e.: [${LOG_LEVELS[$__VERBOSE]}])"

web2py_repo_url=${URL:='https://github.com/web2py/web2py.git'};

if [ ! -z $MINIFICATION_LEVEL ]
then
    MINIFICATION_LABELS=([0]="as_is" [1]="with_admin");
    MINIFICATION_LABEL="${MINIFICATION_LABELS[${MINIFICATION_LEVEL:=0}]}";
    # MINIFICATION_LEVEL validation
    if [[ $MINIFICATION_LEVEL =~ [^[:digit:]] ]] || [ -z $MINIFICATION_LABEL ]
    then
        .log 0 "Not supported minification level.";
        exit 1;
    fi;
fi;

.log 7 "MINIFICATION_LEVEL = $MINIFICATION_LEVEL";
.log 7 "MINIFICATION_LABEL = $MINIFICATION_LABEL";

CLEAN=${CLEAN:=false};

SCRIPT=`realpath -s $0`;
SCRIPTPATH=`dirname $SCRIPT`;

WDBKP=`pwd`;
cd $SCRIPTPATH;

web2py_rel_path="wsgi/web2py"
web2py_abs_path="${SCRIPTPATH}/$web2py_rel_path";

function minify {
    #
    # Clone web2py repo
    web2py_repo="${web2py_abs_path}.git";
    git clone --recursive $web2py_repo_url $web2py_repo;
    cd $web2py_repo;
    if [ -n ${1+x} ]
    then
        # Checkout to the required tag
        git checkout tags/$1 && git submodule update --recursive;
    fi;
    # Run the minifaction script
    rm -rf ../web2py;
    python ./scripts/make_min_web2py.py ../web2py;
    if [ "$MINIFICATION_LEVEL" -ge "1" ]
    then
        # Add the admin application
        rsync -av ./applications/admin "${web2py_abs_path}/applications/";
    fi;
    if [ "$CLEAN" = "true" ]
    then
        rm -rf $web2py_repo;
    fi
    mytag=`git describe --tags`;
    cd -;
    echo $mytag;
};

function git_add {
    #
    branch="web2py_$1$2"
    git checkout -b $branch;
    git add $web2py_rel_path;
    git commit $web2py_rel_path -m "web2py $1";
}

function sub {
    #
    git checkout -b "web2py_$1"
    git submodule add $web2py_repo_url $web2py_rel_path;
    cd $web2py_abs_path;
    if [ -n ${1+x} ]
    then
        # Checkout to the required tag
        git checkout tags/$1;
    fi;
    mytag=`git describe --tags`;
    cd -;
    echo $mytag;
};

if [ ! -z $MINIFICATION_LEVEL ]
then
    rtag=`minify $TAG`;
    git_add $TAG "_mini";
else
    rtag=`sub $TAG`;
    git_add $TAG;
fi;

if [ ! -z $UPSTREAM ]
then
    git remote add upstream $UPSTREAM && git push -u upstream master;
fi;

git status;

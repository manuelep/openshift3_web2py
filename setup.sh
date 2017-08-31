#!/bin/bash

usage="$(basename "$0") [-h] [-l=<value>] [-u=<url>] [-t=<string>] [-m=<value>] [-c] -- A script that helps you to include the desidered web2py framework version.

where:
    -h   Show this help text and exit.
    -l*  Set the script logging level accoddingly to RFC 5424;
         Allowed values: 0-7, default: 6.
    -u*  Overwrite the web2py repository reference from wich clone the framework.
    -t*  Specify the desidered framework version expressed by commit tag (eg. 'R-2.14.6').
    -m   Include in the project a minified web2py framework;
         Allowed values: 0-1.
    -c   Remove framework cloned repository.

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
            # unknown option
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
  fi
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
    fi
fi

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
    fi
    # Run the minifaction script
    python ./scripts/make_min_web2py.py $web2py_abs_path;
    if [ "$MINIFICATION_LEVEL" -ge "1" ]
    then
        # Add the admin application
        rsync -av ./applications/admin "${web2py_abs_path}/applications/";
    fi
    mytag=`git describe --tags`;
    cd -;
    echo $mytag;
};

function git_add {
    #
    branch="web2py_$1_mini"
    git checkout -b $branch
    git add ;
    git commit wsgi -m "web2py $1";
    echo $branch;
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
    fi
    mytag=`git describe --tags`;
    cd -;
    echo $mytag;
};

if [ ! -z $MINIFICATION_LEVEL ]
then
    rtag=`minify $TAG`;
    new_branch=`git_add $TAG`;
    if [ $CLEAN ]
    then
        rm -rf $web2py_abs_path;
    fi
else
    rtag=`sub $TAG`;
    new_branch=`git_add $TAG`;
fi

echo "Switched to branch '$new_branch'"

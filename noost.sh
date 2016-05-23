#!/bin/bash

################################################################################
# FLAGS                                                                        #
################################################################################

MAKE_FOLDERS_WRITABLE=0

################################################################################
# VARIABLES                                                                    #
################################################################################

APACHE_CONF_PATH='/etc/apache2/sites-enabled/localhost-site.conf'

COMPOSER_PACKAGE=''
NETTE_COMPOSER_PACKAGE='nette/web-project'

PROJECT_NAME=''
PROJECT_PATH=''
FULL_PROJECT_PATH=''

################################################################################
# HELPERS                                                                      #
################################################################################

function check_command {
    command_chunks=( $1 )
    $1 >/dev/null 2>&1 || { errecho "Tool '${command_chunks[0]}' required, but it's not installed. Aborting."; exit 1; }
}

function check_tools {
    check_command "composer -V"
    # check_command "npm -v"
    # check_command "bower -v"
}

function errecho {
    echo >&2 "$1"
}

function not_implemented_yet {
    echo >&2 "'$1' not implented yet."
}

function print_help {
    echo "PHP web project bootstrapping tool"
    echo "=================================="
    echo ""
    echo ""
    echo "Usage: $1 [options] <project_path> <project_name>"
    echo "Available options"
    echo ""
    echo "    -a <path>                Apache configuration file path (default: $APACHE_CONF_PATH)"
    echo "    -c <package_name>        composer web project package"
    echo "    -n                       creates Standard Nette Web Project"
    echo "    -w                       make 'log' and 'temp' folders writable"
    echo "    -h                       displays help"
}

################################################################################
# NOOST                                                                        #
################################################################################

function create_frontend_folder_structure {
    # TODO Invesigate why shellcheck displays warning on the next line
    mkdir -p "$FULL_PROJECT_PATH/www/"{"src/"{"font","image","js","style"},"dist/"{"font","image","style","js"}}
}

function init_composer_project {
    echo "Creating Composer Project"
    echo "-------------------------"
    echo "Composer Package: '$COMPOSER_PACKAGE'"
    echo "Location: '$FULL_PROJECT_PATH'"

    composer create-project "$COMPOSER_PACKAGE" "$FULL_PROJECT_PATH"

    echo "Done"
    echo ""
}

function init_plain_project {
    echo "Creating plain Web Project..."
    echo "-----------------------------"
    echo "Location: '$PROJECT_PATH'"
    echo "Done"
    echo ""
}

function make_folders_writable {
    echo "Making 'log' and 'temp' folders writable"
    echo "----------------------------------------"

    # Log folder
    if [ -d "$FULL_PROJECT_PATH/log" ]
    then
        chmod -R a+rw "$FULL_PROJECT_PATH/log"
    else
        errecho "Folder '$FULL_PROJECT_PATH/log' not found. Skipping."
    fi

    # Temp folder
    if [ -d "$FULL_PROJECT_PATH/temp" ]
    then
        chmod -R a+rw "$FULL_PROJECT_PATH/temp"
    else
        errecho "Folder '$FULL_PROJECT_PATH/temp' not found. Skipping."
    fi

    echo "Done"
    echo ""
}

function setup_virtual_host {
    echo "Setting up virtual host"
    echo "-----------------------"

    # Add line 127.0.1.1 project.l into /etc/hosts
    echo "127.0.1.1 $PROJECT_NAME.l" | sudo tee -a /etc/hosts > /dev/null
    # Create entry in server config /etc/apache2/sites-enabled/localhost-site.conf
    VIRTUAL_HOST="
        <VirtualHost *:80>
            ServerName ${PROJECT_NAME}.l
            ServerAdmin webmaster@localhost

            DocumentRoot ${FULL_PROJECT_PATH}/www
            <Directory />
                Options FollowSymLinks
                AllowOverride All
            </Directory>
            <Directory ${FULL_PROJECT_PATH}/www>
                Options Indexes FollowSymLinks MultiViews
                AllowOverride All
                Require all granted
            </Directory>
            ErrorLog ${FULL_PROJECT_PATH}/log/error.log
            LogLevel warn
            CustomLog ${FULL_PROJECT_PATH}/log.log combined
        </VirtualHost>"
    sudo tee -a "$APACHE_CONF_PATH" <<< "$VIRTUAL_HOST" > /dev/null

    # Restart apache
    sudo service apache2 restart

    echo "Done"
    echo ""
}

################################################################################
# MAIN LOOP                                                                    #
################################################################################

# Check if prerequisites are met
check_tools

##################
# Load arguments #
##################

# Read options
while [ "$1" != "" ]
do
    case $1 in
        -a) shift
            if [ -z "$1" ]
            then
                errecho "Apache configuration file path not specified. Aborting."
                exit 1
            fi

            APACHE_CONF_PATH="$1"
            shift

            if [ ! -f "$APACHE_CONF_PATH" ]
            then
                errecho "Apache configuration file path not found. Aborting."
                exit 1
            fi
            ;;

        -c) shift
            if [ -z "$1" ]
            then
                errecho "Composer package not specified. Aborting."
                exit 1
            fi

            COMPOSER_PACKAGE="$1"
            shift

            # TODO validate composer package name

            if [ "$COMPOSER_PACKAGE" = "$NETTE_COMPOSER_PACKAGE" ]
            then
                MAKE_FOLDERS_WRITABLE=1
            fi
            ;;

        -h) shift
            print_help $0
            exit 0
            ;;

        -n) shift
            COMPOSER_PACKAGE=$NETTE_COMPOSER_PACKAGE
            MAKE_FOLDERS_WRITABLE=1
            ;;

        -w) shift
            MAKE_FOLDERS_WRITABLE=1
            ;;

        *)  break                       # First unknown option is a project path
            ;;
    esac
done

# Load project path
if [ -z "$1" ]
then
    errecho "No project path provided. Aborting."
    echo ""
    print_help $0
    exit 1
fi
PROJECT_PATH="$1"

# Load project name
if [ -z "$2" ]
then
    errecho "No project name provided. Aborting."
    echo ""
    print_help $0
    exit 1
fi
PROJECT_NAME="$2"

# Validate project name (only [a-z])
if [[ ! "$PROJECT_NAME" =~ ^[a-z]+$ ]]
then
    errecho "Project name could contain only [a-z] characters. Aborting."
    exit 1
fi

# Check if project path doesn't collide with existing content
if [ -a "$PROJECT_PATH" ]
then
    errecho "Provided path collide with existing file/folder. Aborting."
    exit 1
fi

# Create project folder and determine FULL_PROJECT_PATH
mkdir -p "$PROJECT_PATH"
FULL_PROJECT_PATH=`cd "$PROJECT_PATH"; pwd`

#############
# Bootstrap #
#############

# Create project structure
if [ ! -z "$COMPOSER_PACKAGE" ]
then
    init_composer_project
else
    init_plain_project
fi

# Make folders writable
if [ $MAKE_FOLDERS_WRITABLE -eq 1 ]
then
    make_folders_writable
fi

# Create frontend folder structure
create_frontend_folder_structure

# Setup virtual host
setup_virtual_host

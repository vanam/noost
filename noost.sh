#!/bin/bash

################################################################################
# FLAGS                                                                        #
################################################################################

NETTE_PROJECT=0

################################################################################
# VARIABLES                                                                    #
################################################################################

PROJECT_PATH=''
FULL_PROJECT_PATH=''
PROJECT_NAME=''

################################################################################
# HELPERS                                                                      #
################################################################################

function check_command {
    command_chunks=( $1 )
    $1 >/dev/null 2>&1 || { errecho "Tool '${command_chunks[0]}' required, but it's not installed. Aborting."; exit 1; }
}

function check_tools {
    check_command "composer -V"
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
    echo "    -n                         creates Standard Nette Web Project"
    echo "    -h                         displays help"
}

################################################################################
# NOOST                                                                        #
################################################################################

function create_frontend_folder_structure {
    # TODO Invesigate why shellcheck displays warning on the next line
    mkdir -p "$FULL_PROJECT_PATH/www/"{"src/"{"font","image","js","style"},"dist/"{"font","image","style","js"}}
}

function init_nette_project {
    echo "Creating Standard Nette Web Project..."
    echo "--------------------------------------"
    echo "Location: '$FULL_PROJECT_PATH'"
    echo ""
    composer create-project nette/web-project "$FULL_PROJECT_PATH"
    # Make log/temp folders writable
    chmod -R a+rw "$FULL_PROJECT_PATH/temp" "$FULL_PROJECT_PATH/log"
}

function init_plain_project {
    echo "Creating plain Web Project..."
    echo "-----------------------------"
    echo "Location: '$PROJECT_PATH'"
    echo ""
}

function setup_virtual_host {
    # Add line 127.0.1.1 project.l into /etc/hosts
    echo "127.0.1.1 $PROJECT_NAME.l" | sudo tee -a /etc/hosts > /dev/null
    # Create entry in server config /etc/apache2/extra/httpd-vhosts.conf
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
    sudo tee -a /etc/apache2/sites-enabled/localhost-site.conf <<< "$VIRTUAL_HOST" > /dev/null

    # Restart apache
    sudo service apache2 restart
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
        -h) shift
            print_help $0
            exit 0
            ;;

        -n) shift
            NETTE_PROJECT=1
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
# TODO validate project name (only [a-z]+)
PROJECT_NAME="$2"

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
if [ $NETTE_PROJECT -eq 1 ]
then
    init_nette_project
else
    init_plain_project
fi

# Create frontend folder structure
create_frontend_folder_structure

# Setup virtual host
setup_virtual_host

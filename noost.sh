#!/bin/bash

################################################################################
# FLAGS                                                                        #
################################################################################

NETTE_PROJECT=0

################################################################################
# VARIABLES                                                                    #
################################################################################

PROJECT_PATH=''

################################################################################
# HELPERS                                                                      #
################################################################################

function check_command {
    command_chunks=( $1 )
    $1 >/dev/null 2>&1 || { echo >&2 "Tool '${command_chunks[0]}' required, but it's not installed. Aborting."; exit 1; }
}

function check_tools {
    check_command "composer -V"
}

function not_implemented_yet {
    echo "'$1' not implented yet."
}

function print_help {
    echo "PHP web project bootstrapping tool"
    echo "=================================="
    echo ""
    echo ""
    echo "Usage: $1 <> [options]"
    echo "Available options"

    echo "    -c                         delete all"
    echo "    -n                         creates Standard Nette Web Project"
    echo "    -h                         displays help"
}

################################################################################
# NOOST                                                                        #
################################################################################

function create_frontend_folder_structure {
    not_implemented_yet "create_frontend_folder_structure"
}

function init_nette_project {
    echo "Creating Standard Nette Web Project..."
    echo "--------------------------------------"
    echo "Location: '$PROJECT_PATH'"
    echo ""
    composer create-project nette/web-project "$PROJECT_PATH"
    # TODO make log/temp folders writable
}

function init_plain_project {
    echo "Creating plain Web Project..."
    echo "-----------------------------"
    echo "Location: '$PROJECT_PATH'"
    echo ""
    mkdir "$PROJECT_PATH"
}

################################################################################
# MAIN LOOP                                                                    #
################################################################################

# Check if prerequisites are met
check_tools

##################
# Load arguments #
##################

# First argument is a project path
if [ -z "$1" ]
then
    echo "No project path provided. Aborting."
    exit 1
fi
PROJECT_PATH="$1"

# Check if project path doesn't collide with existing content
if [ -a "$PROJECT_PATH" ]
then
    echo "Provided path collide with existing file/folder. Aborting."
    exit 1
fi
shift

# Read options
while [ "$1" != "" ]
do
    case $1 in
        -n) shift
            NETTE_PROJECT=1
            ;;

        *)  echo "Skipping unknown option '$1'."
            shift
            ;;
    esac
done

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

#!/bin/sh

################################################################################
# Version 1.1.1-RELEASE (27-01-2023)
################################################################################

################################################################################
# Copyright 2023 Nozel/Sebas Veeke. Licenced under a Creative Commons
# Attribution-NonCommercial-ShareAlike 4.0 International License.
#
# See https://creativecommons.org/licenses/by-nc-sa/4.0/
#
# Contact:
# > e-mail      mail@nozel.org
# > GitHub      onnozel
################################################################################

################################################################################
# VARIABLES
################################################################################

# updatebot version
UPDATEBOT_VERSION='1.1.1'

# commands
FREEBSD_UPDATE="$(command -v freebsd-update)"
IOCAGE="$(command -v iocage)"
PKG="$(command -v pkg)"

# colors
COLOR_RESET="\033[0;0m"
COLOR_BOLD="\033[1m"
COLOR_UNDER="\033[4m"
COLOR_WHITE="\033[1;37m"
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_LIGHT_RED="\033[1;31m"
COLOR_LIGHT_GREEN="\033[1;32m"
COLOR_LIGHT_MAGENTA="\033[1;35m"
COLOR_LIGHT_CYAN="\033[1;36m"

################################################################################
# ARGUMENTS
################################################################################

# enable arguments to updatebot
while test -n "$1"; do
    case "$1" in
        # options
        --version)
            ARGUMENT_VERSION='1'
            shift
            ;;

        --help|-help|help|--h|-h|h)
            ARGUMENT_HELP='1'
            shift
            ;;

        # features
        --freebsd|freebsd|fbsd|f)
            ARGUMENT_FREEBSD='1'
            shift
            ;;
    
        --iocage|iocage|i)
            ARGUMENT_IOCAGE='1'
            shift
            ;;

        # other
        *)
            ARGUMENT_NONE='1'
            shift
            ;;
    esac
done

################################################################################
# ERROR FUNCTIONS
################################################################################

error() {
    printf "${COLOR_LIGHT_RED}$@${COLOR_RESET}\n"
    exit 1
}

################################################################################
# REQUIREMENT FUNCTIONS
################################################################################

requirement_root() {
    # show error when updatebot isn't run with root privileges
    if [ "$(id -u)" -ne '0' ]; then
        error 'updatebot: error: used argument must be run with root privileges.'
    fi
}

requirement_os() {
    # show error when freebsd-version cannot be found
    if [ ! "$(command -v freebsd-version)" ]; then
        error 'updatebot: error: operating system is not supported.'
    fi
}

requirement_iocage() {
    # show error when iocage cannot be found
    if [ ! "$(command -v iocage)" ]; then
        error 'updatebot: error: iocage is required but not installed.'
    fi
}

################################################################################
# GENERAL FUNCTIONS
################################################################################

option_version() {
    printf "${COLOR_BOLD}updatebot version %s${COLOR_RESET}\n" "${UPDATEBOT_VERSION}"
    printf "Copyright (C) 2023 Nozel.\n"
    printf "License CC Attribution-NonCommercial-ShareAlike 4.0 Int.\n\n"
    printf "Written by Sebas Veeke\n"
}

option_help() {
    printf "${COLOR_BOLD}Usage:${COLOR_RESET}\n"
    printf " updatebot [feature/option]...\n\n"
    printf "${COLOR_BOLD}Features:${COLOR_RESET}\n"
    printf " -f, --freebsd        Update FreeBSD and its packages\n"
    printf " -i, --iocage         Update all iocage jails\n\n"
    printf "${COLOR_BOLD}Options:${COLOR_RESET}\n"
    printf " --help               Display this help and exit\n"
    printf " --version            Display version information and exit\n"
}

################################################################################
# FEATURE FUNCTIONS
################################################################################

feature_freebsd() {
    printf "${COLOR_BOLD}updatebot will update this FreeBSD system.${COLOR_RESET}\n"
    printf "\n${COLOR_BOLD}(1/3) updating base operating system to latest patch level:${COLOR_RESET}\n"
    ${FREEBSD_UPDATE} fetch install
    printf "\n${COLOR_BOLD}(2/3) updating local package repository to latest version:${COLOR_RESET}\n"
    ${PKG} update
    printf "\n${COLOR_BOLD}(3/3) upgrading packages to latest versions:${COLOR_RESET}\n"
    ${PKG} upgrade --yes
    printf "\n${COLOR_BOLD}All done! \\\( ^ ᴗ ^ )/${COLOR_RESET}\n\n"
    printf "${COLOR_YELLOW}Do not forget to restart the server if the kernel was updated!${COLOR_RESET}\n"
    printf "${COLOR_YELLOW}Do not forget to restart services that were updated!${COLOR_RESET}\n"
}

feature_iocage() {
    printf "${COLOR_BOLD}updatebot will update the following jails:${COLOR_RESET}\n"
    printf "${COLOR_YELLOW}"
    ${IOCAGE} list --quick --header | awk '{print $1;}'
    printf "${COLOR_RESET}"
    printf "\n${COLOR_BOLD}(1/4) updating base jail systems to latest patch level:${COLOR_RESET}\n"
    ${IOCAGE} update ALL
    printf "\n${COLOR_BOLD}(2/4) updating local package repositories to latest version:${COLOR_RESET}\n"
    ${IOCAGE} exec ALL ${PKG} update
    printf "\n${COLOR_BOLD}(3/4) upgrading packages to latest versions:${COLOR_RESET}\n"
    ${IOCAGE} exec ALL ${PKG} upgrade --yes
    printf "\n${COLOR_BOLD}(4/4) restarting jails:${COLOR_RESET}\n"
    ${IOCAGE} stop ALL
    sleep 2
    ${IOCAGE} start ALL
    printf "\n${COLOR_BOLD}All done! \\\( ^ ᴗ ^ )/${COLOR_RESET}\n"
    printf "\n${COLOR_BOLD}Jail overview:${COLOR_RESET}\n"
    ${IOCAGE} list --long
}

################################################################################
# MAIN FUNCTION
################################################################################

updatebot_main() {
    # check whether requirements are met
    requirement_root
    requirement_os

    # call option based on arguments
    if [ "${ARGUMENT_VERSION}" = '1' ]; then
        option_version
        exit 0
    elif [ "${ARGUMENT_HELP}" = '1' ]; then
        option_help
        exit 0
    # call feature based on arguments
    elif [ "${ARGUMENT_FREEBSD}" = '1' ]; then
        feature_freebsd
        exit 0
        
    elif [ "${ARGUMENT_IOCAGE}" = '1' ]; then
        requirement_iocage
        feature_iocage
        exit 0
    
    # return error on invalid argument
    elif [ "${ARGUMENT_NONE}" = '1' ]; then
        error "updatebot: error: used argument is invalid, use updatebot --help for proper usage.\n"
    fi
}

# call main function
updatebot_main

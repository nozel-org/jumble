#!/bin/bash

#############################################################################
# Version 0.1.0-UNSTABLE (28-03-2020)
#############################################################################

#############################################################################
# Copyright 2016-2020 Nozel/Sebas Veeke. Licenced under a Creative Commons
# Attribution-NonCommercial-ShareAlike 4.0 International License.
#
# See https://creativecommons.org/licenses/by-nc-sa/4.0/
#
# Contact:
# > e-mail      mail@nozel.org
# > GitHub      nozel-org
#############################################################################

#############################################################################
# VARIABLES
#############################################################################

# remindbot version
REMINDBOT_VERSION='0.1.0'

# check whether remindbot.conf is available and source it
if [ -f /etc/remindbot/remindbot.conf ]; then
    source /etc/remindbot/remindbot.conf
    # check whether method telegram has been configured
    if [ "${TELEGRAM_TOKEN}" == 'telegram_token_here' ]; then
        METHOD_TELEGRAM='disabled'
    fi
else
    # otherwise exit
    echo 'remindbot: cannot find /etc/remindbot/remindbot.conf'
    echo "Install the configuration file to use remindbot."
    exit 1
fi

#############################################################################
# ARGUMENTS
#############################################################################

# save amount of arguments for validity check
ARGUMENTS="${#}"

# populate validation variables with zero
ARGUMENT_OPTION='0'
ARGUMENT_FEATURE='0'
ARGUMENT_METHOD='0'

# enable help, version and a cli option
while test -n "$1"; do
    case "$1" in
        # options
        --version|-version|version|--v|-v)
            ARGUMENT_VERSION='1'
            ARGUMENT_OPTION='1'
            shift
            ;;

        --help|-help|help|--h|-h)
            ARGUMENT_HELP='1'
            ARGUMENT_OPTION='1'
            shift
            ;;

        --cron)
            ARGUMENT_CRON='1'
            ARGUMENT_OPTION='1'
            shift
            ;;

        --retrieve|retrieve)
            ARGUMENT_RETRIEVE='1'
            ARGUMENT_OPTION='1'
            shift
            ;;

        # features
        --overview|overview)
            ARGUMENT_OVERVIEW='1'
            ARGUMENT_FEATURE='1'
            shift
            ;;

        --remind|remind)
            ARGUMENT_REMIND='1'
            ARGUMENT_FEATURE='1'
            shift
            ;;

        # methods
        --cli|cli)
            ARGUMENT_CLI='1'
            ARGUMENT_METHOD='1'
            shift
            ;;

        --telegram|telegram)
            ARGUMENT_TELEGRAM='1'
            ARGUMENT_METHOD='1'
            shift
            ;;

        # other
        *)
            ARGUMENT_NONE='1'
            shift
            ;;
    esac
done

#############################################################################
# MANAGEMENT FUNCTIONS
#############################################################################

remindbot_version() {
    echo "Remindbot ${REMINDBOT_VERSION}"
    echo "Copyright (C) 2016-2020 Nozel."
    echo "License CC Attribution-NonCommercial-ShareAlike 4.0 Int."
    echo
    echo "Written by Sebas Veeke"
}

remindbot_help() {
    echo "Usage:"
    echo " remindbot [feature]... [method]..."
    echo " remindbot [option]..."
    echo
    echo "Features:"
    echo " --overview        Show reminders overview"
    echo " --remind          Show reminders"
    echo
    echo "Methods:"
    echo " --cli             Output [feature] to command line"
    echo " --telegram        Output [feature] to Telegram bot"
    echo
    echo "Options:"
    echo " --retrieve        Retrieve reminders from link"
    echo " --cron            Effectuate cron changes from remindbot config"
    echo " --validate        Check validity of remindbot.conf"
    echo " --help            Display this help and exit"
    echo " --version         Display version information and exit"
}

remindbot_cron() {
    # function requirements
    requirement_root
    remindbot_validate

    # return error when config file isn't installed on the system
    if [ "${REMINDBOT_CONFIG}" == 'disabled' ]; then
        error_not_available
    fi

    echo '*** UPDATING CRONJOBS ***'
    # remove cronjobs so automated tasks can also be deactivated
    echo '[-] Removing old remindbot cronjobs...'
    rm -f /etc/cron.d/remindbot_*
    # update cronjobs automated tasks
    if [ "${OVERVIEW_TELEGRAM}" == 'yes' ]; then
        echo '[+] Updating cronjob for automated reminder overviews on Telegram...'
        echo -e "# This cronjob activates a automated reminder overview on Telegram on the chosen schedule\n${OVERVIEW_CRON} root /usr/bin/remindbot --overview --telegram" > /etc/cron.d/remindbot_overview_telegram
    fi
    if [ "${REMINDER_TELEGRAM}" == 'yes' ]; then
        echo '[+] Updating cronjob for automated reminders on Telegram...'
        echo -e "# This cronjob activates automated reminders on Telegram on the chosen schedule\n${REMINDER_CRON}_CRON} root /usr/bin/remindbot --metrics --telegram" > /etc/cron.d/remindbot_remind_telegram
    fi
    if [ "${RETRIEVE_REMINDERS}" == 'yes' ]; then
        echo '[+] Updating cronjob for automated retrieval of reminders...'
        echo -e "# This cronjob activates automated retrieval of reminders on the chosen schedule\n${RETRIEVE_CRON}_CRON} root /usr/bin/remindbot --retrieve" > /etc/cron.d/remindbot_retrieve_reminders
    fi

    # give user feedback when all automated tasks are disabled
    if [ "${OVERVIEW_TELEGRAM}" != 'yes' ] && \
    [ "${REMINDER_TELEGRAM}" != 'yes' ] && \
    [ "${RETRIEVE_REMINDERS}" != 'yes' ]; then
        echo '[i] All automated tasks are disabled, no cronjobs to update...'
        exit 0
    fi

    # restart cron to really effectuate the new cronjobs
    echo '[+] Restart the cron service to effectuate the changes...'
    exit 0
}

remindbot_retrieve() {
    wget --quiet ${RETRIEVE_URL} -O /etc/remindbot/reminders.list
}

#############################################################################
# FEATURE FUNCTIONS
#############################################################################

gather_eol() {
    # modify basic distro information to upper case
    EOL_OS="$(echo ${DISTRO_ID}${DISTRO_VERSION} | tr '[:lower:]' '[:upper:]')"
    EOL_OS_NAME="EOL_${EOL_OS}"

    # source database with eol data
    source <(curl --silent https://raw.githubusercontent.com/nozel-org/serverbot/${SERVERBOT_BRANCH}/resources/eol.list | tr -d '.')

    # calculate epoch difference between current date and eol date
    EPOCH_EOL="$(date --date=$(echo "${!EOL_OS_NAME}") +%s)"
    EPOCH_CURRENT="$(date +%s)"
    EPOCH_DIFFERENCE="$(( ${EPOCH_EOL} - ${EPOCH_CURRENT} ))"
}

feature_overview_cli() {
    # probationary period
    echo
    echo "PROEFTIJD:"
    while IFS= read -r line; do
        # ignore lines starting with #
        [[ "${line}" =~ ^#.*$ ]] && continue

        # create relevant variables
        CATEGORY="$(echo ${line} | awk '{print $1}')"
        DATE="$(echo ${line} | awk '{print $2}')"
        DATE_PRETTY="$(date --date=${DATE} +%d-%m-%Y)"
        NAME="$(echo ${line} | awk '{print $3}')"

        # only use category 'PROEFTIJD'
        if [ "${CATEGORY}" == 'PROEFTIJD' ]; then
            echo -e "- ${NAME}\t\t${DATE_PRETTY}"
        fi
    done < "/etc/remindbot/reminders.list"

    # temporary contracts
    echo
    echo "TIJDELIJK:"
    while IFS= read -r line; do
        # ignore lines starting with #
        [[ "${line}" =~ ^#.*$ ]] && continue

        # create relevant variables
        CATEGORY="$(echo ${line} | awk '{print $1}')"
        DATE="$(echo ${line} | awk '{print $2}')"
        DATE_PRETTY="$(date --date=${DATE} +%d-%m-%Y)"
        NAME="$(echo ${line} | awk '{print $3}')"

        # only use category 'TIJDELIJK'
        if [ "${CATEGORY}" == 'TIJDELIJK' ]; then
            echo -e "- ${NAME}\t\t${DATE_PRETTY}"
        fi
    done < "/etc/remindbot/reminders.list"

    # exit when done
    exit 0
}

feature_overview_telegram() {
    # create temp file for telegram message
    TEMP_FILE="$(mktemp)"

    # add some general text
    echo "Het wekelijkse overzicht van einddata van proefperiodes en tijdelijke arbeidsovereenkomsten staat voor u klaar." >> ${TEMP_FILE}
    echo "" >> ${TEMP_FILE}
    
    # probationary period
    echo "<b>PROEFTIJD:</b>" >> ${TEMP_FILE}
    while IFS= read -r line; do
        # ignore lines starting with #
        [[ "${line}" =~ ^#.*$ ]] && continue

        # create relevant variables
        CATEGORY="$(echo ${line} | awk '{print $1}')"
        DATE="$(echo ${line} | awk '{print $2}')"
        DATE_PRETTY="$(date --date=${DATE} +%d-%m-%Y)"
        NAME="$(echo ${line} | awk '{print $3}')"

        # only use category 'PROEFTIJD'
        if [ "${CATEGORY}" == 'PROEFTIJD' ]; then
            echo -e "<code>- ${DATE_PRETTY}      ${NAME}</code>" >> ${TEMP_FILE}
        fi
    done < "/etc/remindbot/reminders.list"

    # add break to temp file
    echo "" >> ${TEMP_FILE}

    # temporary contracts
    echo "<b>TIJDELIJK:</b>" >> ${TEMP_FILE}
    while IFS= read -r line; do
        # ignore lines starting with #
        [[ "${line}" =~ ^#.*$ ]] && continue

        # create relevant variables
        CATEGORY="$(echo ${line} | awk '{print $1}')"
        DATE="$(echo ${line} | awk '{print $2}')"
        DATE_PRETTY="$(date --date=${DATE} +%d-%m-%Y)"
        NAME="$(echo ${line} | awk '{print $3}')"

        # only use category 'TIJDELIJK'
        if [ "${CATEGORY}" == 'TIJDELIJK' ]; then
            echo -e "<code>- ${DATE_PRETTY}      ${NAME}</code>" >> ${TEMP_FILE}
        fi
    done < "/etc/remindbot/reminders.list"

    # create message for telegram
    TELEGRAM_MESSAGE="$(cat ${TEMP_FILE})"

    # call method_telegram
    method_telegram

    # remove temp file
    rm ${TEMP_FILE}

    # exit when done
    exit 0
}

feature_remind_cli() {
    # check whether the current server load exceeds the threshold and alert if true. Output server alert status to shell.
    if [ "${CURRENT_LOAD_PERCENTAGE_ROUNDED}" -ge "${THRESHOLD_LOAD_NUMBER}" ]; then
        echo -e "[!] SERVER LOAD:\\tA current server load of ${CURRENT_LOAD_PERCENTAGE_ROUNDED}% exceeds the threshold of ${THRESHOLD_LOAD}."
    else
        echo -e "[i] SERVER LOAD:\\tA current server load of ${CURRENT_LOAD_PERCENTAGE_ROUNDED}% does not exceed the threshold of ${THRESHOLD_LOAD}."
    fi

    if [ "${CURRENT_MEMORY_PERCENTAGE_ROUNDED}" -ge "${THRESHOLD_MEMORY_NUMBER}" ]; then
        echo -e "[!] SERVER MEMORY:\\tA current memory usage of ${CURRENT_MEMORY_PERCENTAGE_ROUNDED}% exceeds the threshold of ${THRESHOLD_MEMORY}."
    else
        echo -e "[i] SERVER MEMORY:\\tA current memory usage of ${CURRENT_MEMORY_PERCENTAGE_ROUNDED}% does not exceed the threshold of ${THRESHOLD_MEMORY}."
    fi

    if [ "${CURRENT_DISK_PERCENTAGE}" -ge "${THRESHOLD_DISK_NUMBER}" ]; then
        echo -e "[!] DISK USAGE:\\t\\tA current disk usage of ${CURRENT_DISK_PERCENTAGE}% exceeds the threshold of ${THRESHOLD_DISK}."
    else
        echo -e "[i] DISK USAGE:\\t\\tA current disk usage of ${CURRENT_DISK_PERCENTAGE}% does not exceed the threshold of ${THRESHOLD_DISK}."
    fi

    # exit when done
    exit 0
}

feature_remind_telegram() {
    # check whether the current server load exceeds the threshold and alert if true
    if [ "${CURRENT_LOAD_PERCENTAGE_ROUNDED}" -ge "${THRESHOLD_LOAD_NUMBER}" ]; then
        # create message for Telegram
        TELEGRAM_MESSAGE="$(echo -e "\xE2\x9A\xA0 <b>ALERT: SERVER LOAD</b>\\n\\nThe server load (<code>${CURRENT_LOAD_PERCENTAGE_ROUNDED}%</code>) on <b>${HOSTNAME}</b> exceeds the threshold of <code>${THRESHOLD_LOAD}</code>\\n\\n<b>Load average:</b>\\n<code>${COMPLETE_LOAD}</code>")"

        # call method_telegram
        method_telegram
    fi

    # exit when done
    exit 0
}

feature_eol_cli() {
    # function requirements
    gather_eol

    # first check on TBA entries, then check whether epoch difference is positive or negative
    if [ "${!EOL_OS_NAME}" == 'TBA' ]; then
        echo '[i] The EOL date of this operating system has not been added to the database yet. Try again later.'
    else
        if [[ "${EPOCH_DIFFERENCE}" -lt '0' ]]; then
            echo "[!] This operating system is end-of-life since ${!EOL_OS_NAME}."
        elif [[ "${EPOCH_DIFFERENCE}" -gt '0' ]]; then
            echo "[i] This operating system is supported $(( ${EPOCH_DIFFERENCE} / 86400 )) more days (until ${!EOL_OS_NAME})."
        fi
    fi
}

feature_eol_telegram() {
    # function requirements
    gather_information_server
    gather_eol

    # do nothing if eol date isn't in database
    if [ "${!EOL_OS_NAME}" == 'TBA' ]; then
        exit 0
    else
        # give eol notice around 6, 3 and 1 month before eol, and more frequently if its less than 1 month (depends on EOL_CRON parameter)
        if [[ "${EPOCH_DIFFERENCE}" -lt '0' ]]; then
            TELEGRAM_MESSAGE="$(echo -e "\xE2\x9A\xA0 <b>EOL NOTICE: ${HOSTNAME}</b>\\nThis operating system is end-of-life since ${!EOL_OS_NAME}.")"
        elif [[ "${EPOCH_DIFFERENCE}" -ge '14802000' ]] && [[ "${EPOCH_DIFFERENCE}" -lt '15552000' ]]; then
            TELEGRAM_MESSAGE="$(echo -e "\xE2\x9A\xA0 <b>EOL NOTICE: ${HOSTNAME}</b>\\nThis operating system will be end-of-life in $(( ${EPOCH_DIFFERENCE} / 86400 )) days (on ${!EOL_OS_NAME}).")"
        elif [[ "${EPOCH_DIFFERENCE}" -ge '7026000' ]] && [[ "${EPOCH_DIFFERENCE}" -lt '7776000' ]]; then
            TELEGRAM_MESSAGE="$(echo -e "\xE2\x9A\xA0 <b>EOL NOTICE: ${HOSTNAME}</b>\\nThis operating system will be end-of-life in $(( ${EPOCH_DIFFERENCE} / 86400 )) days (on ${!EOL_OS_NAME}).")"
        elif [[ "${EPOCH_DIFFERENCE}" -ge '1' ]] && [[ "${EPOCH_DIFFERENCE}" -lt '5184000' ]]; then
            TELEGRAM_MESSAGE="$(echo -e "\xE2\x9A\xA0 <b>EOL NOTICE: ${HOSTNAME}</b>\\nThis operating system will be end-of-life in $(( ${EPOCH_DIFFERENCE} / 86400 )) days (on ${!EOL_OS_NAME}).")"
        fi
    fi

    # call method_telegram
    method_telegram

    # exit when done
    exit 0
}

#############################################################################
# METHOD FUNCTIONS
#############################################################################

method_telegram() {
    # return error when telegram is unavailable
    if [ "${METHOD_TELEGRAM}" == 'disabled' ]; then
        error_not_available
    fi

    # create payload for Telegram
    TELEGRAM_PAYLOAD="chat_id=${TELEGRAM_CHAT}&text=${TELEGRAM_MESSAGE}&parse_mode=HTML&disable_web_page_preview=true"

    # sent payload to Telegram API and exit
    curl --silent --max-time 10 --retry 5 --retry-delay 2 --retry-max-time 10 -d "${TELEGRAM_PAYLOAD}" "${TELEGRAM_URL}" > /dev/null 2>&1 &
}

#############################################################################
# MAIN FUNCTION
#############################################################################

remindbot_main() {
    # check argument validity
    #requirement_argument_validity

    # call relevant functions based on arguments
    if [ "${ARGUMENT_VERSION}" == '1' ]; then
        remindbot_version
    elif [ "${ARGUMENT_HELP}" == '1' ]; then
        remindbot_help
    elif [ "${ARGUMENT_CRON}" == '1' ]; then
        remindbot_cron
    elif [ "${ARGUMENT_RETRIEVE}" == '1' ]; then
        remindbot_retrieve
    elif [ "${ARGUMENT_OVERVIEW}" == '1' ] && [ "${ARGUMENT_CLI}" == '1' ]; then
        feature_overview_cli
    elif [ "${ARGUMENT_OVERVIEW}" == '1' ] && [ "${ARGUMENT_TELEGRAM}" == '1' ]; then
        feature_overview_telegram
    elif [ "${ARGUMENT_OVERVIEW}" == '1' ] && [ "${ARGUMENT_EMAIL}" == '1' ]; then
        error_not_yet_implemented
    elif [ "${ARGUMENT_REMIND}" == '1' ] && [ "${ARGUMENT_CLI}" == '1' ]; then
        feature_remind_cli
    elif [ "${ARGUMENT_REMIND}" == '1' ] && [ "${ARGUMENT_TELEGRAM}" == '1' ]; then
        feature_remind_telegram
    elif [ "${ARGUMENT_REMIND}" == '1' ] && [ "${ARGUMENT_EMAIL}" == '1' ]; then
        error_not_yet_implemented
    elif [ "${ARGUMENT_NONE}" == '1' ]; then
        error_invalid_option
    fi
}

#############################################################################
# CALL MAIN FUNCTION
#############################################################################

remindbot_main

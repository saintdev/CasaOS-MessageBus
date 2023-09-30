#!/bin/sh

set -e

readonly CASA_SERVICES="casaos-message-bus"

readonly CASA_EXEC=casaos-message-bus
readonly CASA_CONF=/etc/casaos/message-bus.conf
readonly CASA_DB=/var/lib/casaos/db/message-bus.db

readonly COLOUR_GREEN='\e[38;5;154m' # green  		| Lines, bullets and separators
readonly COLOUR_WHITE='\e[1m'        # Bold white	| Main descriptions
readonly COLOUR_GREY='\e[90m'        # Grey  		| Credits
readonly COLOUR_RED='\e[91m'         # Red   		| Update notifications Alert
readonly COLOUR_YELLOW='\e[33m'      # Yellow		| Emphasis

Show() {
    case $1 in
        0 ) echo -e "${COLOUR_GREY}[$COLOUR_RESET${COLOUR_GREEN}  OK  $COLOUR_RESET${COLOUR_GREY}]$COLOUR_RESET $2";;  # OK
        1 ) echo -e "${COLOUR_GREY}[$COLOUR_RESET${COLOUR_RED}FAILED$COLOUR_RESET${COLOUR_GREY}]$COLOUR_RESET $2";;    # FAILED
        2 ) echo -e "${COLOUR_GREY}[$COLOUR_RESET${COLOUR_GREEN} INFO $COLOUR_RESET${COLOUR_GREY}]$COLOUR_RESET $2";;  # INFO
        3 ) echo -e "${COLOUR_GREY}[$COLOUR_RESET${COLOUR_YELLOW}NOTICE$COLOUR_RESET${COLOUR_GREY}]$COLOUR_RESET $2";; # NOTICE
    esac
}

Warn() {
    echo -e "${COLOUR_RED}$1$COLOUR_RESET"
}

trap 'onCtrlC' INT
onCtrlC() {
    echo -e "${COLOUR_RESET}"
    exit 1
}

if [ ! -x "$(command -v ${CASA_EXEC})" ]; then
    Show 2 "${CASA_EXEC} is not detected, exit the script."
    exit 1
fi

while true; do
    echo -n -e "         ${COLOUR_YELLOW}Do you want delete message bus database? Y/n :${COLOUR_RESET}"
    read -r input
    case $input in
    [yY][eE][sS] | [yY])
        REMOVE_LOCAL_STORAGE_DATABASE=true
        break
        ;;
    [nN][oO] | [nN])
        REMOVE_LOCAL_STORAGE_DATABASE=false
        break
        ;;
    *)
        Warn "         Invalid input..."
        ;;
    esac
done

for SERVICE in ${CASA_SERVICES}; do
    Show 2 "Stopping ${SERVICE}..."
    {
        rc-update del "${SERVICE}"
        rc-service --ifexists "${SERVICE}" stop
    } || Show 3 "Failed to disable ${SERVICE}"
done

rm -rvf "$(which ${CASA_EXEC})" || Show 3 "Failed to remove ${CASA_EXEC}"
rm -rvf "${CASA_CONF}" || Show 3 "Failed to remove ${CASA_CONF}"

if [ "${REMOVE_LOCAL_STORAGE_DATABASE}" = "true" ]; then
    rm -rvf "${CASA_DB}" || Show 3 "Failed to remove ${CASA_DB}"
fi

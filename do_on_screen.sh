#! /bin/bash
# TODO:
# - option to create missing windows
#       actually, this is a bug
#       it should ensure that all windows requested
#       are available.
#
# - Should clear the current line before sending a command
#   since there could be junk on the command line.

function print_usage() {
    echo "$0 -S <screen_name> -w <windows,> <-c <command> || -r>"
    echo "Send a command to multiple windows of a Screen session"
    echo "Required Params:"
    echo "-S the name of the screen to affect"
    echo "-w a comma separated list of windows to send input to"
    echo "One of the following"
    echo "-c the command to send to each window"
    echo "-r read stdin and send to each window"
}

NAME=
WINDOWS=
COMMAND=
READ=

while getopts ":S:w:c:r" OPTION; do
    case $OPTION in 
        S)
            NAME=$OPTARG
            ;;
        w)
            WINDOWS=$OPTARG
            ;;
        c)
            COMMAND=$OPTARG
            ;;
        r)
            READ=true
            ;;
        ?)
            print_usage
            exit
            ;;
    esac
done

if [[ -z "$NAME" ]] || [[ -z "$WINDOWS" ]] || [ -z "$COMMAND" -a -z "$READ" ] || [ -n "$COMMAND" -a -n "$READ" ]
then
    print_usage
    exit
fi

# check that a screen session with name $NAME exists
screen -S $NAME -X -p 0 wall "$0 is running on windows $WINDOWS"
if [[ $? -ne 0 ]] ; then
    echo "Error: Screen with name $NAME not found"
    exit
fi

function run_on_screen() {
    # $1 screen name
    # $2 screen window
    # rest: command to send to that screen
    name=$1
    window=$2
    shift 2
    command="${*}" #  to run the command
    screen -S $name -X -p $window stuff "${command[*]}"
}

if [[ -n "$READ" ]] ; then
    read COMMAND
fi

for w in ${WINDOWS//,/ }; do
    run_on_screen $NAME $w $COMMAND
done

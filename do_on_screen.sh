#! /bin/bash
# TODO:
# - Should clear the current line before sending a command
#   since there could be junk on the command line.

function print_usage() {
    echo "$0 -S <screen_name> [-C number of windows] -w <windows,> <-c <command> || -r>"
    echo "Send a command to multiple windows of a Screen session"
    echo "Required Params:"
    echo "-S the name of the screen to affect"
    echo "-w a comma separated list of windows to send input to"
    echo "One of the following"
    echo "-c the command to send to each window"
    echo "-r read stdin and send to each window"
    echo "Optional Params:"
    echo "-C how many windows to initialize. (initializes a new session)"
}

NAME=
WINDOWS=
COMMAND=
READ=
SHOULD_INITIALIZE=
INITIALIZE=

while getopts ":S:w:c:rC:" OPTION; do
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
        C)
            SHOULD_INITIALIZE=true
            INITIALIZE=$OPTARG
            ;;
        ?)
            print_usage
            exit
            ;;
    esac
done

if [[ -z "$NAME" ]] || [[ -z "$WINDOWS" ]] || [ -z "$COMMAND" -a -z "$READ" ] || 
[ -n "$COMMAND" -a -n "$READ" ] || [ -n "$SHOULD_INITIALIZE" -a -z "$INITIALIZE" ] ; then
    print_usage
    exit
fi

if [[ -n "$SHOULD_INITIALIZE" ]] ; then
    # create a new, detatched, session
    screen -S $NAME -dm
    # and open up some windows
    for a in `seq 1 $INITIALIZE`; do
        screen -S $NAME -X screen $a
    done
else
    # check that a screen session with name $NAME exists
    screen -S $NAME -X -p 0 wall "$0 is running on windows $WINDOWS"
    if [[ $? -ne 0 ]] ; then
        echo "Error: Screen with name $NAME not found"
        exit
    fi
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

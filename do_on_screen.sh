#! /bin/bash
# TODO:
# - Should clear the current line before sending a command
#   since there could be junk on the command line.

function print_usage() {
    echo "$0 -S <screen_name> [-C number of windows] [-w <windows,>] [-c <command> || -r] [-n <window name>]"
    echo "Send a command to multiple windows of a Screen session"
    echo "Required Params:"
    echo "-S the name of the screen to affect"
    echo "-w a comma separated list of windows to send input to"
    echo "One of the following"
    echo "-c the command to send to each window"
    echo "-r read stdin and send to each window"
    echo "-n set the title of windows to the param. Can be used with -c or -r"
    echo "Both -c & -r can't be used at the same time."
    echo "Optional Params:"
    echo "-C initialize a new screen session. Specify how many windows it should have."
}

NAME=
WINDOWS=
COMMAND=
READ=
INITIALIZE=
WINDOW_NAME=

while getopts ":S:w:c:rC:n:" OPTION; do
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
            INITIALIZE=$OPTARG
            ;;
        n)
            WINDOW_NAME=$OPTARG
            ;;
        ?)
            print_usage
            exit
            ;;
    esac
done

if [[ -z "$NAME" ]] || [[ -z "$WINDOWS" ]] || [ -z "$COMMAND" -a -z "$READ" -a -z "$WINDOW_NAME" ] || 
[ -n "$COMMAND" -a -n "$READ" ] ; then
    print_usage
    exit
fi

if [[ -n "$INITIALIZE" ]] ; then
    # create a new, detatched, session
    screen -S $NAME -dm
    # and open up some windows
    a=1
    while [[ $a -lt $INITIALIZE ]] ; do
        screen -S $NAME -X screen $a
        a=$((a+1))
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
    if [[ -n "$WINDOW_NAME" ]] ; then
        screen -S $NAME -X -p $w title $WINDOW_NAME
    fi
    if [[ -n "$COMMAND" ]] ; then
        run_on_screen $NAME $w $COMMAND
    fi
done

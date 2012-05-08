#! /bin/bash
# TODO: multi pass? so can validate a script before executing
# TODO: debug output, the command and windows it will affect

function print_usage() {
    echo "$0: screen_name <script_file>"
    echo "Run script_file on screen_name"
    echo "If script_file isn't passsed, commands will be read off stdin"
    echo "A new screen session with the name screen_name will"
    echo "be created if it doesn't exit."
}

function print_dsl_spec() {
    echo "DSL spec:"
    echo "The first line should contain the number of windows to be created"
    echo "in the screen session. Remember screen windows are 0-indexed."
    echo "Following lines should be of this format:"
    echo "1,2,3 echo hi # run 'echo hi' on windows 1,2,3"
    echo "2,3 -r Prompt Text # read and send to windows 2 & 3"
    echo "3 -n alice # window 3 will be named alice"
}

DO_ON_SCREEN="do_on_screen.sh"
SCREEN_NAME=$1
SCRIPT_NAME=$2

if [[ -z "$SCREEN_NAME" ]] || [ -n "$SCRIPT_NAME" -a ! -r "$SCRIPT_NAME" ]
then
    print_usage
    exit 1
fi

which $DO_ON_SCREEN &>/dev/null
if [[ $? -ne 0 ]] ; then
    echo "Error: can't find $DO_ON_SCREEN in path"
    exit 1
fi

function exit_with_parse_error() {
    error="$1"
    line_text="$2"
    echo "Error: $error"
    if [[ -n "$line_text" ]] ; then
        echo "Line $line_num >>"
        echo "$line_text"
        echo "<<"
    fi
    print_dsl_spec
    exit 1
}

function parse_and_run_line() {
    line=( ${@} )
    if [[ "${#line[@]}" -lt 2 ]] ; then
        exit_with_parse_error "malformed line, missing command" "${line[@]}"
    fi
    windows="${line[0]}" # TODO: validate all are numbers
    case "${line[1]}" in
        -r)
            # TODO: migrate read prompt to do_on_screen.sh?
            if [[ -n "${line[@]:2}" ]] ; then
                prompt="${line[@]:2} "
            fi
            echo -n "$prompt"
            read cmd < /dev/tty
            command="-c $cmd"
            ;;
        -n)
            name=${line[@]:2}
            if [[ -z "$name" ]] ; then
                ERROR="missing name"
            else
                command="-n $name"
            fi
            ;;
        *) # just a regular command
            if [[ -z "${line[@]:1}" ]] ; then
                ERROR="missing command (right hand side)"
            else
                command="-c ${line[@]:1}"
            fi
            ;;
    esac
    if [[ -n "$ERROR" ]] ; then
        exit_with_parse_error "${ERROR[@]}" "${line[@]}"
    fi

    if [[ $line_num -eq 2 ]] ; then # first line is # of windows
        create="-C $NUM_WINDOWS"
    fi
    $DO_ON_SCREEN -S $SCREEN_NAME $create -w $windows "$command"
    unset command ERROR create
}

if [[ -n "$SCRIPT_NAME" ]] ; then # load script from file
    NUM_WINDOWS=`head -n 1 "$SCRIPT_NAME"`
    if [[ ! "$NUM_WINDOWS"  =~ [0-9] ]] ; then
        exit_with_parse_error "first line should be the number of windows" $NUM_WINDOWS
    fi

    line_num=2
    tail -n +2 "$SCRIPT_NAME" | while read line; do
        parse_and_run_line $line
        line_num=$((line_num+1))
    done
else # accept script from stdin
   line_num=1
    while read line; do
        if [[ $line_num -eq 1 ]] ; then
            NUM_WINDOWS=$line
            if [[ "$NUM_WINDOWS"  != ?(+|-)+([0-9]) ]] ; then
                exit_with_parse_error "first line should be the number of windows" $line
            fi
        else
            parse_and_run_line $line
        fi
       line_num=$((line_num+1))
    done
fi

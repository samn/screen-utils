# -= Screen Utils =-
### A couple of scripts for automating workflows with GNU Screen.
#### Version 0.1.0

###`do_on_screen.sh`: run a command on several windows of a screen session
_Required Arguments_

- -S <name> the name of the screen session to interact with
- -w <windows> a comma separated list of windows to send input to
- -c <cmd> the command to send to each window
- -r read stdin and send to each window

Both -c & -r can't be used at the same time.

_Optional Arguments_

- -C <num> initialize a new screen session with num windows
- -n <name> set the title of windows. Can be used without -c or -r


###`setup_screen.sh`: A DSL for `do_on_screen.sh`

_Usage_

`setup_screen.sh screen_name [script_file]`

Run script_file on screen_name.  If script_file isn't passsed, commands will be read off stdin.  A new screen session with the name screen_name will be created.

_DSL Spec_

The first line should contain the number of windows to be created in the screen session. Remember screen windows are 0-indexed.
Following lines should be of this format:

```
1,2,3 echo hi # run 'echo hi' on windows 1,2,3
2,3 -r Prompt Text # read and send to windows 2 & 3
3 -n alice # window 3 will be named alice
```

_Example Script_

This script will setup a new screen session with 3 windows
The first one named deploy with an ssh-agent running and a key unlocked
The second one named aux, also with ssh-agent & key
The third named guide running less deployment-guide.txt

```
3
0,1 ssh-agent bash
0,1 ssh-add
0,1 -r Enter phrase for key
0 -n deploy
1 -n aux
2 -n guide
2 less deployment-guide.txt
```
  

#!/usr/bin/env python3

import os
import sys
import subprocess
import time
import argparse


## =============================== VARIABLES ================================ ##
v_max_args      = 2
v_install_tools = False
v_install_force = False
v_swu_tmpfile   = "/tmp/.macOS_softwareupdate_tempfile"
v_cli_tmpfile   = "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"


## =============================== FUNCTIONS ================================ ##
def f_check_root():
    '''
    Checks to see if user is root.
    If not, exit the script.
    '''
    v_euid = os.geteuid()
    if v_euid != 0:
        print("\nMust be run as root...\n")
        exit(10)


def f_args_count():
    '''
    Checks the number of arguments.
    '''
    if len(sys.argv) == 1:
        return False
    elif len(sys.argv) > 1 and len(sys.argv) < (v_max_args + 2):
        return True
    else:
        print(f"""\nInvalid Number of arguments:
        - Arguments passed: {len(sys.argv) - 1}
        - Arguments allowed: {v_max_args}""")
        exit(20)


def f_args_check():
    '''
    Checks for optional arguments.
    '''
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--force', help='Installs updates with no confirmation',
                        action='store_true')
    parser.add_argument('-t', '--tools', help='Installs Command Line Tools',
                        action='store_true')
    args = parser.parse_args()

    if args.tools:
        global v_install_tools
        v_install_tools = True

    if args.force:
        global v_install_force
        v_install_force = True

    return(v_install_tools, v_install_force)


def f_install_tools():
    '''
    If [-t|--tools] is passed, install Command Line Tools.
    '''
    print("\nChecking for latest version of Command Line Tools...")

    open(v_cli_tmpfile, 'w').close()

    result = subprocess.run("softwareupdate -l | grep '* Command Line Tools' | \
        tail -n 1 | awk -F'*' '{print $2}' | sed -e 's/^ //g' | tr -d '\n'",
        shell=True, stdout=subprocess.PIPE)
    v_cli_check = (result.stdout).decode('ascii')

    print(f"\nInstalling {v_cli_check}...\n")

    subprocess.run(["softwareupdate", "--install", v_cli_check, "--verbose"])

    print(f"\n{v_cli_check} installed.")

    os.remove(v_cli_tmpfile)


## ================================ RUN IT! ================================= ##
if __name__ == "__main__":
    ## Due to the use of f-strings, Python 3.6 is required. Sorry.
    if sys.version_info[:2] == (3, 6):
        pass
    else:
        print("\nPython 3.6 required.\nExiting...")
        exit(9)

    # f_check_root()

    ## Ensure tmp CommandLineTools file does NOT exist.
    ## It will be created if needed.
    try:
        os.remove(v_cli_tmpfile)
    except Exception as e:
        if e.errno == 2:
            ## If the file doesn't exist,
            ## that's good, so pass.
            pass
        elif e.errno == 13:
            ## If permission to delete file is denied, exit.
            ## This won't happen if run as root,
            ## but catching it anyway, just in case.
            print(f"\nDelete {v_cli_tmpfile} first, then try again.")
            exit(99)
        else:
            ## If something else happens, hold your horses.
            print(e)
            exit(999)

    if f_args_count():
        if f_args_check()[0]:
            ## If v_install_tools is True,
            ## install Command Line tools
            print("tools is true")
            #f_install_tools()

        if f_args_check()[1]:
            ## If v_install_force is True,
            ## install all updates without confirmation.
            print("force is true")
    else:
        print("Do more stuff here.")

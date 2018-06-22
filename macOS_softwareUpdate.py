#!/usr/bin/env python3

import os
import sys
import subprocess
import time
import argparse


## =============================== VARIABLES ================================ ##
v_max_args  = 2
v_cli_tmp   = "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"


## =============================== FUNCTIONS ================================ ##
def f_check_root():
    """
    If script is not run as root, exit.
    """
    v_euid = os.geteuid()
    if v_euid != 0:
        print("\nMust be run as root...\n")
        sys.exit(10)


def f_args_count():
    """
    Checks the number of arguments.
    """
    if len(sys.argv) == 1:
        pass
    elif len(sys.argv) > 1 and len(sys.argv) < (v_max_args + 2):
        return True
    else:
        print(f"""\nInvalid Number of arguments:
        - Arguments passed: {len(sys.argv) - 1}
        - Arguments allowed: {v_max_args}""")
        sys.exit(20)


def f_args_check():
    """
    Checks for optional arguments.
    """
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--force',
                        help='Install updates with no confirmation',
                        action='store_true')
    parser.add_argument('-t', '--tools',
                        help='Install Command Line Tools',
                        action='store_true')
    args = parser.parse_args()
    return(args.tools, args.force)


def f_install_tools():
    """
    If [-t|--tools] is passed, install Command Line Tools.
    """
    print("\nChecking for latest version of Command Line Tools...")
    open(v_cli_tmp, 'w').close()

    result = subprocess.run("softwareupdate -l | grep '* Command Line Tools' | \
        tail -n 1 | awk -F'*' '{print $2}' | sed -e 's/^ //g' | tr -d '\n'",
        shell=True, stdout=subprocess.PIPE)
    v_cli_check = (result.stdout).decode('ascii')

    print(f"\nInstalling {v_cli_check} in 10 seconds.\nTo cancel, press CTRL+C...\n")
    time.sleep(10)

    subprocess.run(["softwareupdate", "--install", v_cli_check, "--verbose"])

    print(f"\n{v_cli_check} installed.")
    os.remove(v_cli_tmp)


def f_install_force():
    """
    If [-f|--force] is passed, install updates with no confirmation.
    """
    print("\nInstalling ALL software update(s) in 10 seconds, followed by a reboot. \
        \nTo cancel, press CTRL+C...\n")
    time.sleep(10)
    subprocess.run(["softwareupdate", "--install", "--all", "--verbose", "&&", "reboot"])

    print("\nInstallation of ALL software update(s) complete. Rebooting in 10 seconds. \
    \nTo cancel, press CTRL+C...\n")
    time.sleep(10)
    subprocess.run("reboot")

def f_check_for_software_updates():
    """
    Checks for available software updates.
    """
    recommended = False
    restart     = False

    print("\nChecking for software updates. Please wait...\n")

    result  = subprocess.run(["softwareupdate", "--list"], stdout=subprocess.PIPE)
    swu_chk = (result.stdout).decode('ascii')

    chk_rec = [line for line in swu_chk.split('\n') if 'recommended' in line.lower()
        and 'restart' not in line.lower()]
    chk_res = [line for line in swu_chk.split('\n') if 'restart' in line.lower()]

    if len(chk_rec) != 0:
        print("\n\nRECOMMENDED Update(s):\n")
        print(*chk_rec, sep='\n')
        recommended = True

    if len(chk_res) != 0:
        print("\n\nRESTART REQUIRED Update(s):\n")
        print(*chk_res, sep='\n')
        restart = True

    return(recommended, restart, swu_chk)


def f_make_update_list(text, type):
    lines = text.splitlines()

    list_tmp0 = []
    for i, line in enumerate(lines):
        if type == 'recommended':
            if 'recommended' in line and 'restart' not in line:
                list_tmp0.append(lines[i - 1])
        elif type == 'restart':
            if 'restart' in line:
                list_tmp0.append(lines[i - 1])

    list_tmp1 = []

    for i in list_tmp0:
        s = i.split('* ')
        list_tmp1.append(s[1])

    list_result = " ".join(list_tmp1)

    return list_result


def f_prompt_user(text, type):
    if type == 'recommended':
        index  = 0
        prompt = 'RECOMMENDED'
    elif type == 'restart':
        index  = 1
        prompt = 'RESTART REQUIRED'
    else:
        print('WTF MATE')
        sys.exit(9000)

    user_chk = False
    while user_chk == False:
        print(f"\n\n---\nInstall {prompt} software update(s)?")
        v_user_input = input("YES | NO: ")
        if v_user_input.upper() == 'YES' or v_user_input.upper() == 'Y':
            user_chk = True

            return(text, type)
        elif v_user_input.upper() == 'NO' or v_user_input.upper() == 'N':
            print(f"\nInstallation of {prompt} software updates(s) cancelled.")
            user_chk = True
        else:
            print(f"\nInvalid response: {v_user_input}\nExpected Response: YES or NO\n\n")



def f_delete_tmp(file):
    """
    Ensure tmp files do NOT exist.
    They will be created as needed.
    """
    try:
        os.remove(file)
    except KeyboardInterrupt as eki:
        print("\n\nReceived CTRL+C.\nExiting...\n")
        sys.exit(0)
    except Exception as e:
        ## If the file doesn't exist, that's good, so pass.
        if e.errno == 2:
            pass
        ## If permission to delete file is denied, exit.
        ## This won't happen if run as root, but catching it anyway.
        elif e.errno == 13:
            print(f"\nDelete {file} first, then try again.")
            sys.exit(99)
        ## If something else happens, hold your horses.
        else:
            print(e)
            sys.exit(999)


def main():
    ## Due to the use of f-strings, Python 3.6 is required. Sorry.
    if sys.version_info[:2] == (3, 6):
        pass
    else:
        print("\nPython 3.6 required.\nExiting...")
        sys.exit(9)

    # f_check_root()
    f_delete_tmp(v_cli_tmp)

    if f_args_count():
        v_args_check = f_args_check()
        ## If args.tools is True, install Command Line tools
        if v_args_check[0]:
            f_install_tools()

        ## If args.force is True, install all updates without confirmation.
        if v_args_check[1]:
            f_install_force()
    ## If no args passed, continue on to interactive section
    else:
        pass

    v_swu_check = f_check_for_software_updates()
    if v_swu_check[0] == False and v_swu_check[1] == False:
        ## No message to user required, as macOS automatically outputs
        ## "No new software available" if there is no new software available.
        sys.exit(0)

    ## Prompt user to install updates
    if v_swu_check[0] or v_swu_check[1]:
        try:
            if v_swu_check[0]:
                v_prompt_user = f_prompt_user(v_swu_check[2], 'recommended')
                v_update_list = f_make_update_list(v_prompt_user[0], v_prompt_user[1])
                subprocess.run(["softwareupdate", "--install", v_update_list, "--verbose"])

            if v_swu_check[1]:
                v_prompt_user = f_prompt_user(v_swu_check[2], 'restart')
                v_update_list = f_make_update_list(v_prompt_user[0], v_prompt_user[1])
                subprocess.run(["softwareupdate", "--install", v_update_list, "--verbose"])
                subprocess.run("reboot")
        except KeyboardInterrupt as eki:
            print("\n\nReceived CTRL+C.\nExiting...\n")
            sys.exit(0)
        except Exception as e:
            pass


## ================================ RUN IT! ================================= ##
if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt as eki:
        print("\n\nReceived CTRL+C.\nExiting...\n")
        sys.exit(0)
    except Exception as e:
        print(e)
        sys.exit(1)
    finally:
        f_delete_tmp(v_cli_tmp)

#!/bin/bash


## =============================== VARIABLES ================================ ##
v_max_args=2
v_swu_tmpfile="/tmp/.macOS_softwareupdate_tempfile"
v_cli_tmpfile="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
v_force_install=0

## =============================== FUNCTIONS ================================ ##
## Check to see if user is root.
## If not, exit the script.
function f_check_root() {
	if [[ "$EUID" -ne 0 ]]; then
		echo
		echo "Must be run as root..."
		echo
		exit 10
	fi
}


## Check the number of passed arguments.
function f_args_count() {
  if [[ $# -eq 0 ]]; then
		:
	elif [[ $# -gt 0 ]] && [[ $# -lt $(($v_max_args + 1)) ]]; then
		f_args_check "$@"
	else
		echo
		echo "Invalid number of arguments:"
		echo "- Arugments passed: $#"
		echo "- Arguments allowed: $v_max_args"
		echo
		exit 20
  fi
}


## Check that arg includes '-'
function f_args_check() {
	for v_arg in "$@";
	do
		if [[ $v_arg =~ ^\-.$ ]]; then
			:
		else
			echo
			echo "Invalid argument: $v_arg. Must include: - "
			echo
			exit 30
	  fi
	done
}


## Check to see if -x switch was used.
## If so, install Command Line Tools.
## If not, do not install Command Line Tools.
## Modifed from: https://stackoverflow.com/a/14447471
function f_getopts_check() {
	while getopts ":fx" opts
	do
		case $opts in
			f)
				v_force_install=1
			;;
			x)
				touch $v_cli_tmpfile
				echo
				echo "Checking for latest version of Command Line Tools..."

				v_cli_check=$(softwareupdate -l | grep "\* Command Line Tools" |
					tail -n 1 | awk -F"*" '{print $2}' | sed -e 's/^ //g' | tr -d '\n')

				echo "Installing $v_cli_check..."
				echo
				softwareupdate --install "$v_cli_check" --verbose
				echo
				echo "$v_cli_check installed."
				rm -f $v_cli_tmpfile
			;;
			\?)
				echo
				echo "Invalid option: $OPTARG"
				echo
				exit 40
			;;
		esac
	done
}


## Check for available software updates.
## Confirm if user wishes to proceed, if restart is required.
## If none, exit the script.
function f_check_for_software_updates() {
	echo
	echo "Checking for software updates. Please wait..."
	echo

	softwareupdate --list > $v_swu_tmpfile
	v_sw_check_rec=$(cat $v_swu_tmpfile | grep -i "recommended")
	v_sw_check_res=$(cat $v_swu_tmpfile | grep -i "restart")

	if [[ $v_sw_check_rec ]]; then
		if [[ $v_sw_check_res ]]; then
			if [[ $v_force_install -eq 1 ]]; then
				:
			else
				echo "==================================================================="
				echo "The following updates are RECOMMENDED:"
				echo "$v_sw_check_rec"
				echo "==================================================================="
				echo
				echo
				echo "==================================================================="
				echo "The following updates require a RESTART of your computer:"
				echo "$v_sw_check_res"
				echo "==================================================================="
				echo
				echo
				echo "To continue with the software update, WHICH WILL REQUIRE A RESTART, press Enter."
				echo "If you DO NOT WISH TO RESTART your computer at this time, press CTRL+C."
				echo
				read -p "Enter or CTRL+C...? "
			fi
		else
			echo "The following recommended updates are available:"
			echo "$v_sw_check_rec"
			echo
		fi
	elif [[ $v_force_install -eq 1 ]]; then
		:
	else
		rm -f $v_swu_tmpfile
		echo "Exiting..."
		echo
		exit 50
	fi
}


## Set softwareupdate recommended status
function f_sw_update_status_rec() {
	v_sw_update_status_rec=$(cat $v_swu_tmpfile | grep -i "recommended")

	if [ -z "$v_sw_update_status_rec" ]; then
		echo "false"
	else
		echo "true"
	fi
}


## Set softwareupdate restart status
function f_sw_update_status_res() {
	v_sw_update_status_res=$(cat $v_swu_tmpfile | grep -i "restart")

	if [ -z "$v_sw_update_status_res" ]; then
		echo "false"
	else
		echo "true"
	fi
}


## Check current version of macOS for FDE AuthRestart support.
function f_check_authrestart_status() {
	v_authrestart_check=$(fdesetup supportsauthrestart)

	if [ -z "$v_authrestart_check" ]; then
		echo "false"
	else
		echo "true"
	fi
}


## Check FileVault (ON/OFF) status.
function f_check_filevault_status() {
	v_fde_status=$(fdesetup status)

	if [ "$v_fde_status" == "FileVault is On." ]; then
		echo "true"
	elif [ "$v_fde_status" == "FileVault is Off." ]; then
		echo "false"
	fi
}


## Check if user wishes to proceed with software update with no AuthRestart.
function f_sw_update_no_authrestart() {
	choices=("Yes" "No")
	echo "Proceed with software update?"
	select choice in "${choices[@]}";
	do
		case $choice in
			Yes)
				echo "Software update will begin..."
				echo
				bash -c "softwareupdate --install --all --verbose && reboot"
				;;
			No)
				echo "Software update will not begin..."
				echo "Exiting..."
				echo
				exit 60
				;;
		esac
	done
}


## Check how user wants to unlock FileVault, then update and restart.
function f_check_filevault_unlock_and_update_all() {
	choices=("automatically" "manually")
	echo
	echo "After installing updates, would you like to unlock FileVault: "
	echo
	echo "	automatically:"
	echo "		You will be prompted for your passphrase prior to restart. Upon"
	echo "		completion of the software update and restart, FileVault will"
	echo "		unlock automatically, bringing you straight to the login screen."
	echo
	echo "	manually:"
	echo "		You will not be prompted for your passphrase prior to restart."
	echo "		Upon completion of the software update and restart, FileVault must"
	echo "		unlocked manually, prior to landing at the login screen."
	echo
	select choice in "${choices[@]}"
	do
		case $choice in
			"automatically")
				echo
				echo "FileVault will be unlocked automatically."
				echo
				echo "Software update will begin in 10 seconds..."
				echo "To cancel and exit, press CTRL+C."
				echo
				sleep 10
				bash -c "softwareupdate --install --all --verbose && fdesetup authrestart"
				;;
			"manually")
				echo
				echo "FileVault will not be unlocked automatically."
				echo
				echo "Software update will begin in 10 seconds..."
				echo "To cancel and exit, press CTRL+C."
				echo
				sleep 10
				bash -c "softwareupdate --install --all --verbose && reboot"
				;;
		esac
	done
}


## Install recommended updates only.
function f_install_recommended_updates_only() {
	choices=("Yes" "No")
	echo
	echo "Install RECOMMENDED software update(s)?"
	select choice in "${choices[@]}";
	do
		case $choice in
			Yes)
				echo
				echo "Installating RECOMMENDED software update(s)..."
				echo
				sleep 2
				bash -c "softwareupdate --install --recommended --verbose"
				echo
				exit 70
				;;
			No)
				echo
				echo "Installation of RECOMMENDED software updates(s) cancelled."
				echo
				echo "Exiting..."
				echo
				sleep 2
				exit 80
				;;
		esac
	done
}


f_force_install_res() {
	echo
	echo "Installing ALL software update(s) in 10 seconds, followed by a reboot."
	echo "To cancel, press CTRL+C..."
	echo
	sleep 10
	softwareupdate --install --all --verbose && reboot
}


f_force_install_rec() {
	echo
	echo "Installating RECOMMENDED software update(s) in 10 seconds."
	echo "To cancel, press CTRL+C..."
	echo
	sleep 10
	softwareupdate --install --recommended --verbose
	exit 90
}


## ================================ RUN IT! ================================= ##
f_check_root
f_args_count "$@"
f_getopts_check "$@"
f_check_for_software_updates


v_authrestart=$(f_check_authrestart_status)	## true or false
v_filevault=$(f_check_filevault_status)			## true or false
v_update_rec=$(f_sw_update_status_rec)			## true or false
v_update_res=$(f_sw_update_status_res)			## true or false

rm -f $v_swu_tmpfile


if [[ $v_update_res == true ]] && [[ $v_force_install -eq 1 ]]; then
	f_force_install_res
elif [[ $v_update_rec == true ]] && [[ $v_force_install -eq 1 ]]; then
	f_force_install_rec
else
	:
fi


if [ "$v_authrestart" == true ]; then
	if [ "$v_filevault" == true ]; then
		if [ "$v_update_rec" == true ]; then
			if [ "$v_update_res" == true ]; then
				f_check_filevault_unlock_and_update_all
			elif [ "$v_update_res" == false ]; then
				f_install_recommended_updates_only
			fi
		## no elif, because there won't be a situation where an
		## update that requires a restart won't be recommended.
		fi
	elif [ "$v_filevault" == false ]; then
		f_sw_update_no_authrestart
	fi
elif [ "$v_authrestart" == false ]; then
	f_sw_update_no_authrestart
fi

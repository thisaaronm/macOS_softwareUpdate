#!/bin/bash


################################################################################
## Check to see if user is root.
## If not, exit the script.
################################################################################
function f_check_root() {
	if [[ "$EUID" -ne 0 ]]; then
		echo "Must be run as root."
		echo "Exiting..."
		sleep 3
		exit 10
	fi
}

################################################################################
## Check to see if -x switch was used.
## If so, install Command Line Tools.
## If not, do not install Command Line Tools.
## Modifed from: https://stackoverflow.com/a/14447471
################################################################################
function f_check_getops() {
	while getopts ":x" opts
	do
		case $opts in
			x)
				if xcode-select --install 2>&1 | grep -i "installed"; then
					echo
					sleep 3
				else
					echo
					echo "Installing Command Line Tools..."
					sleep 3
					touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
					xcode-select --install
				fi
			;;
			\?)
				echo
				echo "Invalid option: $OPTARG"
				echo
				exit 20
			;;
		esac
	done
}

################################################################################
## Check for available software updates.
## Confirm if user wishes to proceed, if restart is required.
## If none exit the script.
################################################################################
function f_check_for_software_updates() {
	echo
	echo "Checking for software updates. Please wait..."
	echo

	softwareupdate --list > /tmp/softwareupdate_tempfile
	v_sw_check_rec=$(cat /tmp/softwareupdate_tempfile | grep -i "recommended")
	v_sw_check_res=$(cat /tmp/softwareupdate_tempfile | grep -i "restart")

	if [ "$v_sw_check_rec" ]; then
		if [ "$v_sw_check_res" ]; then
			echo "==================================================================="
			echo "The following updates are RECOMMENDED: "
			echo "$v_sw_check_rec"
			echo "==================================================================="
			echo
			echo
			echo "==================================================================="
			echo "The following updates require a RESTART of your computer: "
			echo "$v_sw_check_res"
			echo "==================================================================="
			echo
			echo
			echo "If you wish to continue with the software update, WHICH WILL REQUIRE A RESTART, press Enter."
			echo "Otherwise, if you DO NOT WISH TO RESTART your computer at this time, press CTRL+C."
			echo
			read -p "Enter or CTRL+C...? "
		else
			echo "The following recommended updates are available: "
			echo "$v_sw_check_rec"
			echo
		fi
	else
		echo "There are no updates available."
		echo "Exiting..."
		echo
		sleep 3
		exit
	fi
}


################################################################################
## Set softwareupdate recommended status
################################################################################
function f_sw_update_status_rec() {
	v_sw_update_status_rec=$(cat /tmp/softwareupdate_tempfile | grep -i "recommended")

	if [ "$v_sw_update_status_rec" == true ]; then
		echo "true"
	elif [ "$v_sw_update_status_rec" == false ]; then
		echo "false"
	fi
}


################################################################################
## Set softwareupdate restart status
################################################################################
function f_sw_update_status_res() {
	v_sw_update_status_res=$(cat /tmp/softwareupdate_tempfile | grep -i "restart")

	if [ "$v_sw_update_status_res" == true ]; then
		echo "true"
	elif [ "$v_sw_update_status_res" == false ]; then
		echo "false"
	fi
}


################################################################################
## Check current version of macOS for FDE AuthRestart support.
################################################################################
function f_check_authrestart_status() {
	v_authrestart_check=$(fdesetup supportsauthrestart)

	if [ "$v_authrestart_check" == true ]; then
		echo "true"
	elif [ "$v_authrestart_check" == false ]; then
		echo "false"
	fi
}


################################################################################
## Check FileVault (ON/OFF) status.
################################################################################
function f_check_filevault_status() {
	v_fde_status=$(fdesetup status)

	if [ "$v_fde_status" == "FileVault is On." ]; then
		echo "true"
	elif [ "$v_fde_status" == "FileVault is Off." ]; then
		echo "false"
	fi
}


################################################################################
## Check if user wishes to proceed with software update with no AuthRestart.
################################################################################
function f_sw_update_no_authrestart() {
	choices=("Yes" "No")
	echo "Proceed with software update?"
	select choice in "${choices[@]}";
	do
		case $choice in
			Yes)
				echo "Software update will begin..."
				echo
				bash -c "softwareupdate --install --all && reboot"
				;;
			No)
				echo "Software update will not begin..."
				sleep 1
				echo "Exiting..."
				echo
				sleep 3
				exit
				;;
		esac
	done
}


################################################################################
## Check how user wants to unlock FileVault, then update and restart.
################################################################################
function f_check_filevault_unlock_and_update_all() {
	choices=("automatically" "manually")
	echo "After installing updates, would you like to unlock FileVault: "
	select choice in "${choices[@]}"
	do
		case $choice in
			"automatically")
				echo "You will be prompted for your passphrase prior to reboot. This will,"
				echo "upon completion of the software update installation, automatically"
				echo "unlock FileVault, bringing you straight to the login screen."
				echo
				echo "If you want to cancel, press CTRL+C to EXIT."
				echo "Otherwise, the software update will begin in 10 seconds..."
				echo
				sleep 10
				bash -c "softwareupdate --install --all && fdesetup authrestart"
				;;
			"manually")
				echo "You will not be prompted for your passphrase prior to reboot."
				echo "This means that you will not skip the unlock screen, and will,"
				echo "upon completion of the software update installation, be required"
				echo "to manually unlock FileVault, prior to arriving at the login screen."
				echo
				echo "If you want to cancel, press CTRL+C to EXIT."
				echo "Otherwise, the software update will begin in 10 seconds..."
				echo
				sleep 10
				bash -c "softwareupdate --install --all && reboot"
				;;
		esac
	done
}


################################################################################
## Install recommended updates only.
################################################################################
function f_install_recommended_updates_only() {
	choices=("Yes" "No")
	echo "Proceed with installation of RECOMMENDED software update(s)?"
	select choice in "${choices[@]}";
	do
		case $choice in
			Yes)
				echo "Software update will begin..."
				echo
				sleep 2
				bash -c "softwareupdate --install --recommended"
				;;
			No)
				echo "Software update will not begin..."
				echo
				echo "Exiting..."
				echo
				sleep 2
				exit 30
				;;
		esac
	done
}


################################################################################
## RUN IT!
################################################################################
f_check_root
f_check_getops
f_check_for_software_updates

v_update_rec=$(f_sw_update_status_rec) ## true or false
v_update_res=$(f_sw_update_status_res) ## true or false
v_authrestart=$(f_check_authrestart_status) ## true or false
v_filevault=$(f_check_filevault_status) ## true or false


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

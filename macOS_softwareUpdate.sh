#!/bin/bash


################################################################################
# Check to see if user is root.
# If not, exit the script.
################################################################################
if [[ "$EUID" -ne 0 ]]; then
	echo "Must be run as root."
	echo "Exiting..."
	sleep 3
	exit 1
fi


################################################################################
# Check for available software updates.
# Confirm if user wishes to proceed, if restart is required.
# If none exit the script.
################################################################################
function f_check_for_software_updates() {
	echo
	echo "Checking for software updates. Please wait..."
	echo

	v_sw_check=$(softwareupdate --list | grep -i "recommended")
	v_sw_check_restart=$(softwareupdate --list | grep -i "restart")

	if [ "$v_sw_check" ]; then
		if [ "$v_sw_check_restart" ]; then
			echo "============================================================"
			echo "The following recommended updates are available: "
			echo "$v_sw_check"
			echo
			echo "============================================================"
			echo
			echo
			echo "============================================================"
			echo "The following updates require a restart of your computer: "
			echo "$v_sw_check_restart"
			echo
			echo "============================================================"
			echo
			echo
			echo "If you wish to continue with the software update, press Enter."
			echo "Otherwise, if you do not wish to restart your computer now,"
			read -p "press CTRL+C to cancel the script... "
		else
			echo "The following recommended updates are available: "
			echo "$v_sw_check"
			echo
		fi
	else
		echo "There are no updates available."
		echo "Exiting..."
		sleep 3
		echo
		exit
	fi
}


################################################################################
# Set softwareupdate recommended status
################################################################################
function f_sw_update_status_rec() {
	v_sw_update_status_rec=$(softwareupdate --list | grep -i "recommended")

	if [ "$v_sw_update_status_rec" == true ]; then
		echo "true"
	elif [ "$v_sw_update_status_rec" == false ]; then
		echo "false"
	fi
}


################################################################################
# Set softwareupdate restart status
################################################################################
function f_sw_update_status_res() {
	v_sw_update_status_res=$(softwareupdate --list | grep -i "restart")

	if [ "$v_sw_update_status_res" == true ]; then
		echo "true"
	elif [ "$v_sw_update_status_res" == false ]; then
		echo "false"
	fi
}


################################################################################
# Check current version of macOS for FDE AuthRestart support.
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
# Check FileVault (ON/OFF) status.
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
# Check if user wishes to proceed with software update with no AuthRestart.
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
# Check how user wants to unlock FileVault, then update accordingly.
################################################################################
function f_check_filevault_unlock_and_update() {
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
# RUN IT!
################################################################################
f_check_for_software_updates
v_authrestart=$(f_check_authrestart_status) # true or false
v_filevault=$(f_check_filevault_status) # true or false

if [ "$v_authrestart" == true ]; then
	if [ "$v_filevault" == true ]; then
		f_check_filevault_unlock_and_update
	elif [ "$v_filevault" == false ]; then
		f_sw_update_no_authrestart
	fi
elif [ "$v_authrestart" == false ]; then
	f_sw_update_no_authrestart
fi

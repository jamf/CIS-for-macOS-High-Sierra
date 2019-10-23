#!/bin/bash


####################################################################################################
#
# Copyright (c) 2017, Jamf, LLC.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the JAMF Software, LLC nor the
#                 names of its contributors may be used to endorse or promote products
#                 derived from this software without specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
####################################################################################################

# written by Katie English, Jamf October 2016
# updated for 10.12 CIS benchmarks by Katie English, Jamf February 2017
# updated to use configuration profiles by Apple Professional Services, January 2018
# github.com/jamfprofessionalservices
# Updated for 10.13 CIS benchmarks by Erin McDonald, Jamf Jan 2019

# USAGE
# Reads from plist at /Library/Application Support/SecurityScoring/org_security_score.plist by default.
# For "true" items, runs query for current computer/user compliance.
# Non-compliant items are logged to /Library/Application Support/SecurityScoring/org_audit

plistlocation="/Library/Application Support/SecurityScoring/org_security_score.plist"
auditfilelocation="/Library/Application Support/SecurityScoring/org_audit"
currentUser="$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')"
hardwareUUID="$(/usr/sbin/system_profiler SPHardwareDataType | grep "Hardware UUID" | awk -F ": " '{print $2}' | xargs)"

logFile="/Library/Application Support/SecurityScoring/remediation.log"


if [[ $(tail -n 1 "$logFile") = *"Remediation complete" ]]; then
	echo "Append to existing logFile"
 	echo "$(date -u)" "Beginning Audit" >> "$logFile"; else
 	echo "Create new logFile"
 	echo "$(date -u)" "Beginning Audit" > "$logFile"	
fi

if [[ ! -e $plistlocation ]]; then
	echo "No scoring file present"
	exit 0
fi

# Cleanup audit file to start fresh
[ -f "$auditfilelocation" ] && rm "$auditfilelocation"
touch "$auditfilelocation"


# 1.1 Verify all Apple provided software is current
# Verify organizational score
Audit1_1="$(defaults read "$plistlocation" OrgScore1_1)"
# If organizational score is 1 or true, check status of client
if [ "$Audit1_1" = "1" ]; then
	countAvailableSUS="$(softwareupdate -l | grep "*" | wc -l | tr -d ' ')"
	# If client fails, then note category in audit file
	if [ "$countAvailableSUS" = "0" ]; then
		echo "$(date -u)" "1.1 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore1_1 -bool false; else
		echo "* 1.1 Verify all Apple provided software is current" >> "$auditfilelocation"
		echo "$(date -u)" "1.1 fix" | tee -a "$logFile"
	fi
fi

# 1.2 Enable Auto Update
# Configuration Profile - Custom payload > com.apple.SoftwareUpdate.plist > AutomaticCheckEnabled=true, AutomaticDownload=true
# Verify organizational score
Audit1_2="$(defaults read "$plistlocation" OrgScore1_2)"
# If organizational score is 1 or true, check status of client
if [ "$Audit1_2" = "1" ]; then
	# Check to see if the preference and key exist. If not, write to audit log. Presuming: Unset = not secure state.
		automaticUpdates="$(/usr/bin/defaults read /Library/Preferences/com.apple.SoftwareUpdate | /usr/bin/grep -c 'AutomaticCheckEnabled = 1')"
		if [[ "$automaticUpdates" -gt "0" ]]; then
			echo "$(date -u)" "1.2 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore1_2 -bool false; else
			echo "* 1.2 Enable Auto Update" >> "$auditfilelocation"
			echo "$(date -u)" "1.2 fix" | tee -a "$logFile"
		fi	
	fi

# 1.3 Enable app update installs
# Does not work as a Configuration Profile - Custom payload > com.apple.commerce
# Verify organizational score
Audit1_3="$(defaults read "$plistlocation" OrgScore1_3)"
# If organizational score is 1 or true, check status of client
if [ "$Audit1_3" = "1" ]; then
	automaticAppUpdates="$(defaults read /Library/Preferences/com.apple.commerce AutoUpdate)"
	# If client fails, then note category in audit file
	if [ "$automaticAppUpdates" = "1" ]; then
		echo "$(date -u)" "1.3 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore1_3 -bool false; else
		echo "* 1.3 Enable app update installs" >> "$auditfilelocation"
		echo "$(date -u)" "1.3 fix" | tee -a "$logFile"
	fi
fi

# 1.4 Enable system data files and security update installs 
# Configuration Profile - Custom payload > com.apple.SoftwareUpdate.plist > ConfigDataInstall=true, CriticalUpdateInstall=true
# Verify organizational score
Audit1_4="$(defaults read "$plistlocation" OrgScore1_4)"
# If organizational score is 1 or true, check status of client
if [ "$Audit1_4" = "1" ]; then
	# Check to see if the preference and key exist. If not, write to audit log. Presuming: Unset = not secure state.
		criticalUpdates="$(/usr/bin/defaults read /Library/Preferences/com.apple.SoftwareUpdate | /usr/bin/grep -c 'ConfigDataInstall = 1')"
		if [[ "$criticalUpdates" -gt "0" ]]; then
			echo "$(date -u)" "1.4 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore1_4 -bool false; else
			echo "* 1.4 Enable system data files and security update installs" >> "$auditfilelocation"
			echo "$(date -u)" "1.4 fix" | tee -a "$logFile"
		fi
	fi

# 1.5 Enable OS X update installs 
# Does not work as a Configuration Profile - Custom payload > com.apple.commerce
# Verify organizational score
Audit1_5="$(defaults read "$plistlocation" OrgScore1_5)"
# If organizational score is 1 or true, check status of client
if [ "$Audit1_5" = "1" ]; then
	updateRestart="$(defaults read /Library/Preferences/com.apple.commerce AutoUpdateRestartRequired)"
	# If client fails, then note category in audit file
	if [ "$updateRestart" = "1" ]; then
		echo "$(date -u)" "1.5 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore1_5 -bool false; else
		echo "* 1.5 Enable OS X update installs" >> "$auditfilelocation"
		echo "$(date -u)" "1.5 fix" | tee -a "$logFile"
	fi
fi

# 2.1.1 Turn off Bluetooth, if no paired devices exist
# Verify organizational score
Audit2_1_1="$(defaults read "$plistlocation" OrgScore2_1_1)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_1_1" = "1" ]; then
	btPowerState="$(defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState)"
	# If client fails, then note category in audit file
	if [ "$btPowerState" = "0" ]; then
		echo "$(date -u)" "2.1.1 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore2_1_1 -bool false; else
		connectable="$(system_profiler SPBluetoothDataType | grep Connectable | awk '{print $2}' | head -1)"
		if [ "$connectable" = "Yes" ]; then
			echo "$(date -u)" "2.1.1 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore2_1_1 -bool false; else
			echo "* 2.1.1 Turn off Bluetooth, if no paired devices exist" >> "$auditfilelocation"
			echo "$(date -u)" "2.1.1 fix" | tee -a "$logFile"
		fi
	fi
fi

# 2.1.3 Show Bluetooth status in menu bar
# Verify organizational score
Audit2_1_3="$(defaults read "$plistlocation" OrgScore2_1_3)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_1_3" = "1" ]; then
	btMenuBar="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.systemuiserver menuExtras | grep -c Bluetooth.menu)"
	# If client fails, then note category in audit file
	if [ "$btMenuBar" = "0" ]; then
		echo "* 2.1.3 Show Bluetooth status in menu bar" >> "$auditfilelocation"
		echo "$(date -u)" "2.1.3 fix" | tee -a "$logFile"; else
		echo "$(date -u)" "2.1.3 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore2_1_3 -bool false
	fi
fi

### 2.2.1 Enable "Set time and date automatically" (Not Scored)
# Verify organizational score
Audit2_2_1="$(defaults read "$plistlocation" OrgScore2_2_1)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_2_1" = "1" ]; then
	SetTimeAndDateAutomatically="$(systemsetup -getusingnetworktime | awk '{print $3}')"
	# If client fails, then note category in audit file
	if [ "$SetTimeAndDateAutomatically" = "On" ]; then
	 	echo "$(date -u)" "2.2.1 passed" | tee -a "$logFile"
	 	defaults write "$plistlocation" OrgScore2_2_1 -bool false; else
		echo "* 2.2.1 Enable Set time and date automatically" >> "$auditfilelocation"
		echo "$(date -u)" "2.2.1 fix" | tee -a "$logFile"
	fi
fi

# 2.2.2 Ensure time set is within appropriate limits
# Not audited - only enforced if identified as priority
# Verify organizational score
Audit2_2_2="$(defaults read "$plistlocation" OrgScore2_2_2)"
# If organizational score is 1 or true, check status of client
# if [ "$Audit2_2_2" = "1" ]; then
# sync time 
# fi

# 2.3.1 Set an inactivity interval of 20 minutes or less for the screen saver 
# Configuration Profile - LoginWindow payload > Options > Start screen saver after: 20 Minutes of Inactivity
# Verify organizational score
Audit2_3_1="$(defaults read "$plistlocation" OrgScore2_3_1)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_3_1" = "1" ]; then
		screenSaverTime="$(defaults read /Users/"$currentUser"/Library/Preferences/ByHost/com.apple.screensaver."$hardwareUUID".plist idleTime)"
		if [[ "$screenSaverTime" -le "1200" ]] && [[ "$screenSaverTime" != "" ]]; then
			echo "$(date -u)" "2.3.1 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore2_3_1 -bool false; else
			echo "* 2.3.1 Set an inactivity interval of 20 minutes or less for the screen saver" >> "$auditfilelocation"
			echo "$(date -u)" "2.3.1 fix" | tee -a "$logFile"
		fi
	fi

# 2.3.2 Secure screen saver corners 
# Configuration Profile - Custom payload > com.apple.dock > wvous-tl-corner=0, wvous-br-corner=5, wvous-bl-corner=0, wvous-tr-corner=0
# Verify organizational score
Audit2_3_2="$(defaults read "$plistlocation" OrgScore2_3_2)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_3_2" = "1" ]; then
		bl_corner="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-bl-corner)"
		tl_corner="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-tl-corner)"
		tr_corner="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-tr-corner)"
		br_corner="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-br-corner)"
		if [[ "$bl_corner" != "6" ]] && [[ "$tl_corner" != "6" ]] && [[ "$tr_corner" != "6" ]] && [[ "$br_corner" != "6" ]]; then
			echo "$(date -u)" "2.3.2 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore2_3_2 -bool false; else
			echo "* 2.3.2 Secure screen saver corners" >> "$auditfilelocation"
			echo "$(date -u)" "2.3.2 fix" | tee -a "$logFile"
		fi
	fi

# 2.3.3 Familiarize users with screen lock tools or corner to Start Screen Saver 
# Configuration Profile - Custom payload > com.apple.dock > wvous-tl-corner=0, wvous-br-corner=5, wvous-bl-corner=0, wvous-tr-corner=0
# Verify organizational score
Audit2_3_3="$(defaults read "$plistlocation" OrgScore2_3_3)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_3_3" = "1" ]; then
	# If client fails, then note category in audit file
		bl_corner="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-bl-corner)"
		tl_corner="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-tl-corner)"
		tr_corner="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-tr-corner)"
		br_corner="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-br-corner)"
		if [ "$bl_corner" = "5" ] || [ "$tl_corner" = "5" ] || [ "$tr_corner" = "5" ] || [ "$br_corner" = "5" ]; then
			echo "$(date -u)" "2.3.3 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore2_3_3 -bool false; else
			echo "* 2.3.3 Familiarize users with screen lock tools or corner to Start Screen Saver" >> "$auditfilelocation"
			echo "$(date -u)" "2.3.3 fix" | tee -a "$logFile"
		fi
	fi


# 2.4.1 Disable Remote Apple Events 
# Verify organizational score
Audit2_4_1="$(defaults read "$plistlocation" OrgScore2_4_1)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_4_1" = "1" ]; then
	remoteAppleEvents="$(systemsetup -getremoteappleevents | awk '{print $4}')"
	# If client fails, then note category in audit file
	if [ "$remoteAppleEvents" = "Off" ]; then
	 	echo "$(date -u)" "2.4.1 passed" | tee -a "$logFile"
	 	defaults write "$plistlocation" OrgScore2_4_1 -bool false; else
		echo "* 2.4.1 Disable Remote Apple Events" >> "$auditfilelocation"
		echo "$(date -u)" "2.4.1 fix" | tee -a "$logFile"
	fi
fi

# 2.4.2 Disable Internet Sharing 
# Verify organizational score
Audit2_4_2="$(defaults read "$plistlocation" OrgScore2_4_2)"
# If organizational score is 1 or true, check status of client
# If client fails, then note category in audit file
if [ "$Audit2_4_2" = "1" ]; then
	if [ -e /Library/Preferences/SystemConfiguration/com.apple.nat.plist ]; then
		natAirport="$(/usr/libexec/PlistBuddy -c "print :NAT:AirPort:Enabled" /Library/Preferences/SystemConfiguration/com.apple.nat.plist)"
		natEnabled="$(/usr/libexec/PlistBuddy -c "print :NAT:Enabled" /Library/Preferences/SystemConfiguration/com.apple.nat.plist)"
		natPrimary="$(/usr/libexec/PlistBuddy -c "print :NAT:PrimaryInterface:Enabled" /Library/Preferences/SystemConfiguration/com.apple.nat.plist)"
		if [ "$natAirport" = "true" ] || [ "$natEnabled" = "true" ] || [ "$natPrimary" = "true" ]; then
			echo "* 2.4.2 Disable Internet Sharing"  >> "$auditfilelocation"
			echo "$(date -u)" "2.4.2 fix" | tee -a "$logFile"; else
			echo "$(date -u)" "2.4.2 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore2_4_2 -bool false
		fi; else
		echo "$(date -u)" "2.4.2 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore2_4_2 -bool false
	fi
fi

# 2.4.3 Disable Screen Sharing 
# Verify organizational score
Audit2_4_3="$(defaults read "$plistlocation" OrgScore2_4_3)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_4_3" = "1" ]; then
	# If client fails, then note category in audit file
	screenSharing="$(launchctl list | egrep screensharing)"
	if [ "$screenSharing" = "1" ]; then
		echo "* 2.4.3 Disable Screen Sharing" >> "$auditfilelocation"
		echo "$(date -u)" "2.4.3 fix" | tee -a "$logFile"; else
	 	echo "$(date -u)" "2.4.3 passed" | tee -a "$logFile"
	 	defaults write "$plistlocation" OrgScore2_4_3 -bool false
	fi
fi

# 2.4.4 Disable Printer Sharing 
# Verify organizational score
Audit2_4_4="$(defaults read "$plistlocation" OrgScore2_4_4)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_4_4" = "1" ]; then
	# If client fails, then note category in audit file
	printerSharing="$(/usr/sbin/cupsctl | grep -c "share_printers=0")"
	if [ "$printerSharing" != "0" ]; then
	 	echo "$(date -u)" "2.4.4 passed" | tee -a "$logFile"
	 	defaults write "$plistlocation" OrgScore2_4_4 -bool false; else
		echo "* 2.4.4 Disable Printer Sharing" >> "$auditfilelocation"
		echo "$(date -u)" "2.4.4 fix" | tee -a "$logFile"
	fi
fi

# 2.4.5 Disable Remote Login 
# Verify organizational score
Audit2_4_5="$(defaults read "$plistlocation" OrgScore2_4_5)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_4_5" = "1" ]; then
	remoteLogin="$(systemsetup -getremotelogin | awk '{print $3}')"
	# If client fails, then note category in audit file
	if [ "$remoteLogin" = "Off" ]; then
	 	echo "$(date -u)" "2.4.5 passed" | tee -a "$logFile"
	 	defaults write "$plistlocation" OrgScore2_4_5 -bool false; else
		echo "* 2.4.5 Disable Remote Login" >> "$auditfilelocation"
		echo "$(date -u)" "2.4.5 fix" | tee -a "$logFile"
	fi
fi

# 2.4.6 Disable DVD or CD Sharing 
# Verify organizational score
Audit2_4_6="$(defaults read "$plistlocation" OrgScore2_4_6)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_4_6" = "1" ]; then
	discSharing="$(launchctl list | egrep ODSAgent)"
	# If client fails, then note category in audit file
	if [ "$discSharing" = "" ]; then
	 	echo "$(date -u)" "2.4.6 passed" | tee -a "$logFile"
	 	defaults write "$plistlocation" OrgScore2_4_6 -bool false; else
		echo "* 2.4.6 Disable DVD or CD Sharing" >> "$auditfilelocation"
		echo "$(date -u)" "2.4.6 fix" | tee -a "$logFile"
	fi
fi

# 2.4.7 Disable Bluetooth Sharing
# Verify organizational score
Audit2_4_7="$(defaults read "$plistlocation" OrgScore2_4_7)"
# If organizational score is 1 or true, check status of client and user
if [ "$Audit2_4_7" = "1" ]; then
	btSharing="$(/usr/libexec/PlistBuddy -c "print :PrefKeyServicesEnabled"  /Users/"$currentUser"/Library/Preferences/ByHost/com.apple.Bluetooth."$hardwareUUID".plist)"
	# If client fails, then note category in audit file
	if [ "$btSharing" = "true" ]; then
		echo "* 2.4.7 Disable Bluetooth Sharing" >> "$auditfilelocation"
		echo "$(date -u)" "2.4.7 fix" | tee -a "$logFile"; else
	 	echo "$(date -u)" "2.4.7 passed" | tee -a "$logFile"
	 	defaults write "$plistlocation" OrgScore2_4_7 -bool false
	fi
fi

# 2.4.8 Disable File Sharing
# Verify organizational score
Audit2_4_8="$(defaults read "$plistlocation" OrgScore2_4_8)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_4_8" = "1" ]; then
	afpEnabled="$(launchctl list | egrep AppleFileServer)"
	smbEnabled="$(launchctl list | egrep smbd)"
	# If client fails, then note category in audit file
	if [ "$afpEnabled" = "" ] && [ "$smbEnabled" = "" ]; then
 		echo "$(date -u)" "2.4.8 passed" | tee -a "$logFile"
 		defaults write "$plistlocation" OrgScore2_4_8 -bool false; else
		echo "* 2.4.8 Disable File Sharing" >> "$auditfilelocation"
		echo "$(date -u)" "2.4.8 fix" | tee -a "$logFile"
	fi
fi

# 2.4.9 Disable Remote Management
# Verify organizational score
Audit2_4_9="$(defaults read "$plistlocation" OrgScore2_4_9)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_4_9" = "1" ]; then
	remoteManagement="$(ps -ef | egrep ARDAgent | grep -c "/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/MacOS/ARDAgent")"
	# If client fails, then note category in audit file
	if [ "$remoteManagement" = "1" ]; then
 		echo "$(date -u)" "2.4.9 passed" | tee -a "$logFile"
 		defaults write "$plistlocation" OrgScore2_4_9 -bool false; else
		echo "* 2.4.9 Disable Remote Management" >> "$auditfilelocation"
		echo "$(date -u)" "2.4.9 fix" | tee -a "$logFile"
	fi
fi

# 2.5.1 Disable "Wake for network access"
# Verify organizational score
Audit2_5_1="$(defaults read "$plistlocation" OrgScore2_5_1)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_5_1" = "1" ]; then
			wompEnabled="$(pmset -g | grep womp | awk '{print $2}')"
			if [ "$wompEnabled" = "0" ]; then
				echo "$(date -u)" "2.5.1 passed" | tee -a "$logFile"
				defaults write "$plistlocation" OrgScore2_5_1 -bool false; else
				echo "* 2.5.1 Disable Wake for network access" >> "$auditfilelocation"
				echo "$(date -u)" "2.5.1 fix" | tee -a "$logFile"
			fi
		fi

# 2.6.1.1 Enable FileVault 
# Verify organizational score
# Audit only.  Does not remediate
Audit2_6_1_1="$(defaults read "$plistlocation" OrgScore2_6_1_1)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_6_1_1" = "1" ]; then
	filevaultEnabled="$(fdesetup status | awk '{print $3}')"
	# If client fails, then note category in audit file
	if [ "$filevaultEnabled" = "Off." ]; then
		echo "* 2.6.1.1 Enable FileVault" >> "$auditfilelocation"
		echo "$(date -u)" "2.6.1.1 fix" | tee -a "$logFile"; else
		echo "$(date -u)" "2.6.1.1 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore2_6_1_1 -bool false	
	fi
fi

# 2.6.1.2 Ensure all user storage APFS Volumes are encrypted
# Verify organizational score
# Audit only.  Does not remediate
Audit2_6_1_2="$(defaults read "$plistlocation" OrgScore2_6_1_2)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_6_1_2" = "1" ]; then
	apfsyes="$(diskutil ap list)"
	if [ "$apfsyes" != "No APFS Containers found" ]; then
		DUINFO=$(diskutil info /)
		LV_UUID=$(echo "$DUINFO" | awk '/\/ Partition UUID/ {print $5;exit}')
					# Get the APFS Container ID for the boot drive's APFS volume.
					CONTAINER_ID=$(echo "$DUINFO" | awk '/Part of Whole/ {print $4;exit}')
					APFSINFO=$(diskutil ap list "$CONTAINER_ID")
					APVOLINFO=$(echo "$APFSINFO" | grep -A7 "$LV_UUID")
					ENCRYPTION=$(echo "$APVOLINFO" | awk '/FileVault/ {print $3;exit}')
					if [ "$ENCRYPTION" != "Yes" ]; then
						echo "* 2.6.1.2 Ensure all user storage APFS Volumes are encrypted" >> "$auditfilelocation"
						echo "$(date -u)" "2.6.1.2 fix" | tee -a "$logFile"; else 
						echo "$(date -u)" "2.6.1.2 passed" | tee -a "$logFile"
						defaults write "$plistlocation" OrgScore2_6_1_2 -bool false	
						fi
					else 
					echo "$(date -u)" "2.6.1.2 not applicable, CoreStorage storage enabled" | tee -a "$logFile"
					fi
				fi

	

# 2.6.1.3 Ensure all user storage CoreStorage Volumes are encyrpted
# Verify organizational score
# Audit only.  Does not remediate
Audit2_6_1_3="$(defaults read "$plistlocation" OrgScore2_6_1_3)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_6_1_3" = "1" ]; then
	apfsyes="$(diskutil ap list)"
	if [ "$apfsyes" == "No APFS Containers found" ]; then
		# get Logical Volume Family
		LFV="$(diskutil cs list | grep "Logical Volume Family" | awk '/Logical Volume Family/ {print $5}')"
		# Check encryption status is complete
		EncryptStatus="$( diskutil cs "$LFV" | awk '/Conversion Status/ {print $3}')"
		if [ "$EncryptStatus" != "Complete" ]; then
		echo "* 2.6.1.3 Ensure all user CoreStorage volumes encrypted" >> "$auditfilelocation"
		echo "$(date -u)" "2.6.1.3 fix" | tee -a "$logFile"; else 
		echo "$(date -u)" "2.6.1.3 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore2_6_1_3 -bool false	
		fi
	else 
	echo "$(date -u)" "2.6.1.3 not applicable, APFS storage enabled" | tee -a "$logFile"
	fi
fi
	

# 2.6.2 Enable Gatekeeper 
# Verify organizational score
Audit2_6_2="$(defaults read "$plistlocation" OrgScore2_6_2)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_6_2" = "1" ]; then
		gatekeeperEnabled="$(spctl --status | grep -c "assessments enabled")"
		if [ "$gatekeeperEnabled" = "1" ]; then
			echo "$(date -u)" "2.6.2 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore2_6_2 -bool false; else
			echo "* 2.6.2 Enable Gatekeeper" >> "$auditfilelocation"
			echo "$(date -u)" "2.6.2 fix" | tee -a "$logFile"
		fi
	fi

# 2.6.3 Enable Firewall 
# Verify organizational score
Audit2_6_3="$(defaults read "$plistlocation" OrgScore2_6_3)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_6_3" = "1" ]; then
		firewallEnabled="$(defaults read /Library/Preferences/com.apple.alf globalstate)"
		if [ "$firewallEnabled" = "0" ]; then
			echo "* 2.6.3 Enable Firewall" >> "$auditfilelocation"
			echo "$(date -u)" "2.6.3 fix" | tee -a "$logFile"; else
			echo "$(date -u)" "2.6.3 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore2_6_3 -bool false
		fi
	fi

# 2.6.4 Enable Firewall Stealth Mode 
# Verify organizational score
Audit2_6_4="$(defaults read "$plistlocation" OrgScore2_6_4)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_6_4" = "1" ]; then
		stealthEnabled="$(/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode | awk '{print $3}')"
		if [ "$stealthEnabled" = "enabled" ]; then
			echo "$(date -u)" "2.6.4 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore2_6_4 -bool false; else
			echo "* 2.6.4 Enable Firewall Stealth Mode" >> "$auditfilelocation"
			echo "$(date -u)" "2.6.4 fix" | tee -a "$logFile"
		fi
	fi

# 2.6.5 Review Application Firewall Rules
# Verify organizational score
Audit2_6_5="$(defaults read "$plistlocation" OrgScore2_6_5)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_6_5" = "1" ]; then
	appsInbound="$(/usr/libexec/ApplicationFirewall/socketfilterfw --listapps | grep ALF | awk '{print $7}')" # this shows the true state of the config profile too.
	# If client fails, then note category in audit file
	if [[ "$appsInbound" -le "10" ]] || [ -z "$appsInbound" ]; then
		echo "$(date -u)" "2.6.5 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore2_6_5 -bool false; else
		echo "* 2.6.5 Review Application Firewall Rules" >> "$auditfilelocation"
		echo "$(date -u)" "2.6.5 fix" | tee -a "$logFile"
	fi
fi

# 2.6.8 Disable sending diagnostic and usage data to Apple
# Verify organizational score
Audit2_6_8="$(defaults read "$plistlocation" OrgScore2_6_8)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_6_8" = "1" ]; then
	AppleDiagn=$(defaults read /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit)
	if [ "$AppleDiagn" == 1 ]; then 
		/bin/echo "* 2.6.8 Disable sending diagnostic and usage data to Apple" >> "$auditfilelocation"
		echo "$(date -u)" "2.6.8 fix Disable sending diagnostic and usage data to Apple" | tee -a "$logFile"; else
		echo "$(date -u)" "2.6.8 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore2_6_8 -bool false
		fi
	fi

# 2.7.1 iCloud configuration (Check for iCloud accounts) (Not Scored)
# Verify organizational score
Audit2_7_1="$(defaults read "$plistlocation" OrgScore2_7_1)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_7_1" = "1" ]; then
	over500=$( /usr/bin/dscl . list /Users UniqueID | /usr/bin/awk '$2 > 500 { print $1 }' )
	for EachUser in $over500 ;
	do
		UserHomeDirectory=$(/usr/bin/dscl . -read /Users/"$EachUser" NFSHomeDirectory | /usr/bin/awk '{print $2}')
		CheckForiCloudAccount="$(/usr/bin/defaults read "$UserHomeDirectory/Library/Preferences/MobileMeAccounts" Accounts | /usr/bin/grep -c 'AccountDescription = iCloud')"
		# If client fails, then note category in audit file
		if [[ "$CheckForiCloudAccount" -gt "0" ]] ; then
			/bin/echo "* 2.7.1 $EachUser has an iCloud account configured" >> "$auditfilelocation"
			echo "$(date -u)" "2.7.1 fix $EachUser iCloud account" | tee -a "$logFile"; else
			echo "$(date -u)" "2.7.1 passed $EachUser" #| tee -a "$logFile"
		fi
	done
fi

# 2.7.2 Disable iCloud keychain (Not Scored) - 
# Configuration Profile - Restrictions payload > Functionality > Allow iCloud Keychain (unchecked)
# Best remediated via Configuration Profile
# Verify organizational score
Audit2_7_2="$(defaults read "$plistlocation" OrgScore2_7_2)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_7_2" = "1" ]; then
	CP_iCloudKeychain="$(/usr/sbin/system_profiler SPConfigurationProfileDataType | /usr/bin/grep -c 'allowCloudKeychainSync = 0')"
	# If client fails, then note category in audit file
	if [[ "$CP_iCloudKeychain" -gt "0" ]] ; then
		echo "$(date -u)" "2.7.2 passed CP" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore2_7_2 -bool false; else
		echo "* 2.7.2 Disable iCloud Keychain with configuration profile" >> "$auditfilelocation"
		echo "$(date -u)" "2.7.2 fix" | tee -a "$logFile"
	fi
fi

# 2.7.3 Disable iCloud Drive (Not Scored)
# Configuration Profile - Restrictions payload > Functionality > Allow iCloud Drive (unchecked)
# Best remediated via Configuration Profile
# Verify organizational score
Audit2_7_3="$(defaults read "$plistlocation" OrgScore2_7_3)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_7_3" = "1" ]; then
	CP_iCloudDrive="$(/usr/sbin/system_profiler SPConfigurationProfileDataType | /usr/bin/grep -c 'allowCloudDocumentSync = 0')"
	# If client fails, then note category in audit file
	if [[ "$CP_iCloudDrive" -gt "0" ]] ; then
		echo "$(date -u)" "2.7.3 passed CP" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore2_7_3 -bool false; else
		echo "* 2.7.3 Disable iCloud Drive with configuration profile" >> "$auditfilelocation"
		echo "$(date -u)" "2.7.3 fix" | tee -a "$logFile"
	fi
fi

# 2.7.4 iCloud Drive Document sync
# Configuration Profile - Restrictions payload - > Functionality > Allow iCloud Desktop & Documents (unchecked)
# Best remediated via Configuration Profile
# Verify organizational score
Audit2_7_4="$(defaults read "$plistlocation" OrgScore2_7_4)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_7_4" = "1" ]; then
	# If client fails, then note category in audit file
	CP_icloudDriveDocSync="$(/usr/sbin/system_profiler SPConfigurationProfileDataType | /usr/bin/grep -c 'allowCloudDesktopAndDocuments = 0')"
	if [[ "$CP_icloudDriveDocSync" -gt "0" ]] ; then
		echo "$(date -u)" "2.7.4 passed CP" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore2_7_4 -bool false; else
		echo "* 2.7.4 Disable iCloud Drive Document sync with configuration profile" >> "$auditfilelocation"
		echo "$(date -u)" "2.7.4 fix" | tee -a "$logFile"
	fi
fi

# 2.7.5 iCloud Drive Desktop sync
# Configuration Profile - Restrictions payload - > Functionality > Allow iCloud Desktop & Documents (unchecked)
# Best remediated via Configuration Profile
# Verify organizational score
Audit2_7_5="$(defaults read "$plistlocation" OrgScore2_7_5)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_7_5" = "1" ]; then
	# If client fails, then note category in audit file
	CP_icloudDriveDocSync="$(/usr/sbin/system_profiler SPConfigurationProfileDataType | /usr/bin/grep -c 'allowCloudDesktopAndDocuments = 0')"
	if [[ "$CP_icloudDriveDocSync" -gt "0" ]] ; then
		echo "$(date -u)" "2.7.5 passed CP" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore2_7_5 -bool false; else
		echo "* 2.7.5 Disable iCloud Drive Desktop sync with configuration profile" >> "$auditfilelocation"
		echo "$(date -u)" "2.7.5 fix" | tee -a "$logFile"
	fi
fi

# 2.8.1 Time Machine Auto-Backup
# Verify organizational score
Audit2_8_1="$(defaults read "$plistlocation" OrgScore2_8_1)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_8_1" = "1" ]; then
	timeMachineAuto="$( defaults read /Library/Preferences/com.apple.TimeMachine.plist AutoBackup )"
	# If client fails, then note category in audit file
	if [ "$timeMachineAuto" != "1" ]; then
		echo "* 2.8.1 Time Machine Auto-Backup" >> "$auditfilelocation"
		echo "$(date -u)" "2.8.1 fix" | tee -a "$logFile"; else
		echo "$(date -u)" "2.8.1 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore2_8_1 -bool false
	fi
fi

# 2.9 Pair the remote control infrared receiver if enabled
# Verify organizational score
Audit2_9="$(defaults read "$plistlocation" OrgScore2_9)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_9" = "1" ]; then
	IRPortDetect="$(system_profiler SPUSBDataType | egrep "IR Receiver" -c)"
	# If client fails, then note category in audit file
	if [ "$IRPortDetect" = "0" ]; then
		echo "$(date -u)" "2.9 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore2_9 -bool false; else
		echo "* 2.9 Pair the remote control infrared receiver if enabled" >> "$auditfilelocation"
		echo "$(date -u)" "2.9 fix" | tee -a "$logFile"
	fi
fi

# 2.10 Enable Secure Keyboard Entry in terminal.app 
# Verify organizational score
Audit2_10="$(defaults read "$plistlocation" OrgScore2_10)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_10" = "1" ]; then
		secureKeyboard="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.Terminal SecureKeyboardEntry)"
		if [ "$secureKeyboard" = "1" ]; then
			echo "$(date -u)" "2.10 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore2_10 -bool false; else
			echo "* 2.10 Enable Secure Keyboard Entry in terminal.app" >> "$auditfilelocation"
			echo "$(date -u)" "2.10 fix" | tee -a "$logFile"
		fi
	fi

# 2.11 Java 6 is not the default Java runtime 
# Verify organizational score
Audit2_11="$(defaults read "$plistlocation" OrgScore2_11)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_11" = "1" ]; then
	# If client fails, then note category in audit file
	if [ -f "/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Enabled.plist" ] ; then
		javaVersion="$( defaults read "/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Enabled.plist" CFBundleVersion )"
		javaMajorVersion="$(echo "$javaVersion" | awk -F'.' '{print $2}')"
		if [ "$javaMajorVersion" -lt "7" ]; then
			echo "* 2.11 Java 6 is not the default Java runtime" >> "$auditfilelocation"
			echo "$(date -u)" "2.11 fix" | tee -a "$logFile"; else
			echo "$(date -u)" "2.11 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore2_11 -bool false
		fi
	fi
	if [ ! -f "/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Enabled.plist" ] ; then
		echo "$(date -u)" "2.11 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore2_11 -bool false
	fi
fi

# 2.13 Ensure EFI version is valid and being regularly checked
# Audit only.  T2 chip Macs do not allow for use of eficheck
# Verify organizational score
Audit2_13="$(defaults read "$plistlocation" OrgScore2_13)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_13" = "1" ]; then
# Check for T2 chip.  
if system_profiler SPiBridgeDataType | grep 'Model Name:' | grep -q 'T2'; then 
	echo "* 2.13 Check EFI Firmware Integrity is not supported by this Mac. T2 Chip found." >> "$auditfilelocation"
	defaults write "$plistlocation" OrgScore2_13 -bool false
	echo "$(date -u)" "2.13 passed" | tee -a "$logFile"
	else
		efiStatus="$(/usr/libexec/firmwarecheckers/eficheck/eficheck --integrity-check | grep -c "No changes detected")"
		if [ "$efiStatus" -gt 0 ]; then
			echo "$(date -u)" "2.13 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore2_13 -bool false
			else
				echo "* 2.13 Ensure EFI version is valid and being regularly checked" >> "$auditfilelocation"
				echo "$(date -u)" "2.13 fix" | tee -a "$logFile"
				fi
fi
fi


# 3.1 Enable security auditing
# Verify organizational score
Audit3_1="$(defaults read "$plistlocation" OrgScore3_1)"
# If organizational score is 1 or true, check status of client
if [ "$Audit3_1" = "1" ]; then
	auditdEnabled="$(launchctl list | grep -c auditd)"
	# If client fails, then note category in audit file
	if [ "$auditdEnabled" -gt "0" ]; then
		echo "$(date -u)" "3.1 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore3_1 -bool false; else
		echo "* 3.1 Enable security auditing" >> "$auditfilelocation"
		echo "$(date -u)" "3.1 fix" | tee -a "$logFile"
	fi
fi

# 3.2 Configure Security Auditing Flags
# Verify organizational score
Audit3_2="$(defaults read "$plistlocation" OrgScore3_2)"
# If organizational score is 1 or true, check status of client
if [ "$Audit3_2" = "1" ]; then
	auditFlags="$(egrep "^flags:" /etc/security/audit_control)"
	# If client fails, then note category in audit file
	if [[ ${auditFlags} != *"ad"* ]];then
		echo "* 3.2 Configure Security Auditing Flags" >> "$auditfilelocation"
		echo "$(date -u)" "3.2 fix" | tee -a "$logFile"; else
		echo "$(date -u)" "3.2 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore3_2 -bool false
	fi
fi

# 3.3 Ensure security auditing retention
# Verify organizational score
Audit3_3="$(defaults read "$plistlocation" OrgScore3_3)"
# If organizational score is 1 or true, check status of client
if [ "$Audit3_3" = "1" ]; then
	auditRetention="$(cat /etc/security/audit_control | egrep expire-after)"
	if [ "$auditRetention" = "expire-after:60D OR 1G" ]; then
		echo "$(date -u)" "3.3 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore3_3 -bool false; else
		echo "* 3.3 Ensure security auditing retention" >> "$auditfilelocation"
		echo "$(date -u)" "3.3 fix" | tee -a "$logFile"
		fi
	fi
		

# 3.4 Control access to audit records
# Audit only.  Remediation requires system inspection.
# Verify organizational score
Audit3_4="$(defaults read "$plistlocation" OrgScore3_4)"
# If organizational score is 1 or true, check status of client
if [ "$Audit3_4" = "1" ]; then
	etccheck=$(ls -le /etc/security/audit_control | awk '{print $3 $4}' | awk 'NF' | grep -v "root wheel")
	varcheck=$(ls -le /var/audit | awk '{print $3 $4}' | awk 'NF' | grep -v "root wheel")
	if [[ "$etccheck" != "" ]] && [[ "$varcheck" != "" ]]; then
		echo "$(date -u)" "3.4 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore3_4 -bool false; else
		echo "* 3.4 Control access to audit records" >> "$auditfilelocation"
		echo "$(date -u)" "3.4 fix" | tee -a "$logFile"
		fi
	fi
	
# 3.5 Retain install.log for 365 or more days 
# Verify organizational score
Audit3_5="$(defaults read "$plistlocation" OrgScore3_5)"
# If organizational score is 1 or true, check status of client
if [ "$Audit3_5" = "1" ]; then
	installRetention="$(grep -i ttl /etc/asl/com.apple.install | awk -F'ttl=' '{print $2}')"
	# If client fails, then note category in audit file
	if [[ "$installRetention" = "" ]] || [[ "$installRetention" -lt "365" ]]; then
		echo "* 3.5 Retain install.log for 365 or more days" >> "$auditfilelocation"
		echo "$(date -u)" "3.5 fix" | tee -a "$logFile"; else
		echo "$(date -u)" "3.5 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore3_5 -bool false
	fi
fi

# 3.6 Ensure Firewall is configured to log
# Verify organizational score
Audit3_6="$(defaults read "$plistlocation" OrgScore3_6)"
# If organizational score is 1 or true, check status of client
if [ "$Audit3_6" = "1" ]; then
	FWlog=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getloggingmode | sed -e 's/[[:space:]]*$//')
	if [ "$FWlog" = "Log mode is on" ]; then
		echo "$(date -u)" "3.6 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore3_6 -bool false; else
		echo "* 3.6 Ensure Firewall is configured to log" >> "$auditfilelocation"
		echo "$(date -u)" "3.6 fix" | tee -a "$logFile"
	fi
fi

# 4.1 Disable Bonjour advertising service 
# Verify organizational score
Audit4_1="$(defaults read "$plistlocation" OrgScore4_1)"
# If organizational score is 1 or true, check status of client
if [ "$Audit4_1" = "1" ]; then
		bonjourAdvertise="$( defaults read /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements )"
		if [ "$bonjourAdvertise" != "1" ]; then
			echo "* 4.1 Disable Bonjour advertising service" >> "$auditfilelocation"
			echo "$(date -u)" "4.1 fix" | tee -a "$logFile"; else
			echo "$(date -u)" "4.1 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore4_1 -bool false
		fi
	fi

# 4.2 Enable "Show Wi-Fi status in menu bar" 
# Verify organizational score
Audit4_2="$(defaults read "$plistlocation" OrgScore4_2)"
# If organizational score is 1 or true, check status of client
if [ "$Audit4_2" = "1" ]; then
	wifiMenuBar="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.systemuiserver menuExtras | grep -c AirPort.menu)"
	# If client fails, then note category in audit file
	if [ "$wifiMenuBar" = "0" ]; then
		echo "* 4.2 Enable Show Wi-Fi status in menu bar" >> "$auditfilelocation"
		echo "$(date -u)" "4.2 fix" | tee -a "$logFile"; else
		echo "$(date -u)" "4.2 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore4_2 -bool false
	fi
fi

# 4.4 Ensure http server is not running 
# Verify organizational score
Audit4_4="$(defaults read "$plistlocation" OrgScore4_4)"
# If organizational score is 1 or true, check status of client
# Code fragment from https://github.com/krispayne/CIS-Settings/blob/master/ElCapitan_CIS.sh
if [ "$Audit4_4" = "1" ]; then
	if /bin/launchctl list | egrep httpd > /dev/null; then
		echo "* 4.4 Ensure http server is not running" >> "$auditfilelocation"
		echo "$(date -u)" "4.4 fix" | tee -a "$logFile"; else
		echo "$(date -u)" "4.4 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore4_4 -bool false
	fi
fi

# 4.5 Ensure nfs server is not running
# Verify organizational score
Audit4_5="$(defaults read "$plistlocation" OrgScore4_5)"
# If organizational score is 1 or true, check status of client
if [ "$Audit4_5" = "1" ]; then
	# If client fails, then note category in audit file
	if [ -e /etc/exports  ]; then
		echo "4.5 Ensure nfs server is not running" >> "$auditfilelocation"
		echo "$(date -u)" "4.5 fix" | tee -a "$logFile"; else
		echo "$(date -u)" "4.5 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore4_5 -bool false
	fi
fi

# 5.1.1 Secure Home Folders
# Verify organizational score
Audit5_1_1="$(defaults read "$plistlocation" OrgScore5_1_1)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_1_1" = "1" ]; then
	homeFolders="$(find /Users -mindepth 1 -maxdepth 1 -type d -perm -1 | grep -v "Shared" | grep -v "Guest" | wc -l | xargs)"
	# If client fails, then note category in audit file
	if [ "$homeFolders" = "0" ]; then
		echo "$(date -u)" "5.1.1 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore5_1_1 -bool false; else
		echo "* 5.1.1 Secure Home Folders" >> "$auditfilelocation"
		echo "$(date -u)" "5.1.1 fix" | tee -a "$logFile"
	fi
fi

# 5.1.2 Check System Wide Applications for appropriate permissions
# Verify organizational score
Audit5_1_2="$(defaults read "$plistlocation" OrgScore5_1_2)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_1_2" = "1" ]; then
	appPermissions="$(find /Applications -iname "*\.app" -type d -perm -2 -ls | wc -l | xargs)"
	# If client fails, then note category in audit file
	if [ "$appPermissions" = "0" ]; then
		echo "$(date -u)" "5.1.2 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore5_1_2 -bool false; else
		echo "* 5.1.2 Check System Wide Applications for appropriate permissions" >> "$auditfilelocation"
		echo "$(date -u)" "5.1.2 fix" | tee -a "$logFile"
	fi
fi

# 5.1.3 Check System folder for world writable files
# Verify organizational score
Audit5_1_3="$(defaults read "$plistlocation" OrgScore5_1_3)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_1_3" = "1" ]; then
	sysPermissions="$(find /System -type d -perm -2 -ls | grep -v "Public/Drop Box" | wc -l | xargs)"
	# If client fails, then note category in audit file
	if [ "$sysPermissions" = "0" ]; then
		echo "$(date -u)" "5.1.3 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore5_1_3 -bool false; else
		echo "* 5.1.3 Check System folder for world writable files" >> "$auditfilelocation"
		echo "$(date -u)" "5.1.3 fix" | tee -a "$logFile"
	fi
fi

# 5.1.4 Check Library folder for world writable files
# Verify organizational score
Audit5_1_4="$(defaults read "$plistlocation" OrgScore5_1_4)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_1_4" = "1" ]; then
	libPermissions="$(find /Library -type d -perm -2 -ls | grep -v Caches | grep -v Adobe | grep -v VMware | wc -l | xargs)"
	# If client fails, then note category in audit file
	if [ "$libPermissions" = "0" ]; then
		echo "$(date -u)" "5.1.4 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore5_1_4 -bool false; else
		echo "* 5.1.4 Check Library folder for world writable files" >> "$auditfilelocation"
		echo "$(date -u)" "5.1.4 fix" | tee -a "$logFile"
	fi
fi

# 5.3 Reduce the sudo timeout period
# Verify organizational score
Audit5_3="$(defaults read "$plistlocation" OrgScore5_3)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_3" = "1" ]; then
	sudoTimeout="$(cat /etc/sudoers | grep timestamp)"
	# If client fails, then note category in audit file
	if [ "$sudoTimeout" = "" ]; then
		echo "* 5.3 Reduce the sudo timeout period" >> "$auditfilelocation"
		echo "$(date -u)" "5.3 fix" | tee -a "$logFile"; else
		echo "$(date -u)" "5.3 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore5_3 -bool false
	fi
fi

# 5.4 Use a separate timestamp for each user/tty combo
# Verify organizational score
Audit5_4="$(defaults read "$plistlocation" OrgScore5_4)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_4" = "1" ]; then
	ttyTimestamp="$(cat /etc/sudoers | egrep tty_tickets)"
	# If client fails, then note category in audit file
	if [ "$ttyTimestamp" != "" ]; then
		echo "* 5.4 Use a separate timestamp for each user/tty combo" >> "$auditfilelocation"
		echo "$(date -u)" "5.4 fix" | tee -a "$logFile"; else
		echo "$(date -u)" "5.4 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore5_4 -bool false
	fi
fi

# 5.7 Automatically lock the login keychain for inactivity
# Verify organizational score
Audit5_7="$(defaults read "$plistlocation" OrgScore5_7)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_7" = "1" ]; then
	keyTimeout="$(security show-keychain-info /Users/"$currentUser"/Library/Keychains/login.keychain 2>&1 | grep -c "no-timeout")"
	# If client fails, then note category in audit file
	if [ "$keyTimeout" -gt 0 ]; then
		echo "* 5.7 Automatically lock the login keychain for inactivity" >> "$auditfilelocation"
		echo "$(date -u)" "5.7 fix" | tee -a "$logFile"; else
		echo "$(date -u)" "5.7 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore5_7 -bool false
	fi
fi

# 5.8 Ensure login keychain is locked when the computer sleeps
# Verify organizational score
Audit5_8="$(defaults read "$plistlocation" OrgScore5_8)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_8" = "1" ]; then
	lockSleep="$(security show-keychain-info /Users/"$currentUser"/Library/Keychains/login.keychain 2>&1 | grep -c "lock-on-sleep")"
	# If client fails, then note category in audit file
	if [ "$lockSleep" = 0 ]; then
		echo "* 5.8 Ensure login keychain is locked when the computer sleeps" >> "$auditfilelocation"
		echo "$(date -u)" "5.8 fix" | tee -a "$logFile"; else
		echo "$(date -u)" "5.8 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore5_8 -bool false
	fi
fi

# 5.9 Enable OCSP and CRL certificate checking
# Does not work as a Configuration Profile - Custom payload > com.apple.security.revocation
# Verify organizational score
Audit5_9="$(defaults read "$plistlocation" OrgScore5_9)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_9" = "1" ]; then
	certificateCheckOCSP="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.security.revocation OCSPStyle)"
	certificateCheckCRL="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.security.revocation CRLStyle)"
	# If client fails, then note category in audit file
	if [ "$certificateCheckOCSP" != "RequireIfPresent" ] || [ "$certificateCheckCRL" != "RequireIfPresent" ]; then
		echo "* 5.9 Enable OCSP and CRL certificate checking" >> "$auditfilelocation"
		echo "$(date -u)" "5.9 fix" | tee -a "$logFile"; else
		echo "$(date -u)" "5.9 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore5_9 -bool false
	fi
fi

# 5.11 Do not enable the "root" account
# Verify organizational score
Audit5_11="$(defaults read "$plistlocation" OrgScore5_11)"
if [ "$Audit5_11" = "1" ]; then
	#echo "$(date -u)" "Checking 5.7" | tee -a "$logFile"
	rootEnabled="$(dscl . -read /Users/root AuthenticationAuthority 2>&1 | grep -c "No such key")"
	rootEnabledRemediate="$(dscl . -read /Users/root UserShell 2>&1 | grep -c "/usr/bin/false")"
	if [ "$rootEnabled" = "1" ]; then
		echo "$(date -u)" "5.11 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore5_11 -bool false; elif
		[ "$rootEnabledRemediate" = "1" ]; then
		   echo "$(date -u)" "5.11 passed due to remediation" | tee -a "$logFile"
		   defaults write "$plistlocation" OrgScore5_11 -bool false
	else
	echo "* 5.11 Do Not enable the "root" account" >> "$auditfilelocation"
	echo "$(date -u)" "5.11 fix" | tee -a "$logFile"

	fi
fi

# 5.12 Disable automatic login
# Verify organizational score
Audit5_12="$(defaults read "$plistlocation" OrgScore5_12)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_12" = "1" ]; then
		autologinEnabled="$(defaults read /Library/Preferences/com.apple.loginwindow | grep -Fx "autoLoginUser")"
		if [ "$autologinEnabled" = "" ]; then
			echo "$(date -u)" "5.12 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore5_12 -bool false; else
			echo "* 5.12 Disable automatic login" >> "$auditfilelocation"
			echo "$(date -u)" "5.12 fix" | tee -a "$logFile"
		fi
	fi

# 5.13 Require a password to wake the computer from sleep or screen saver
# Verify organizational score
Audit5_13="$(defaults read "$plistlocation" OrgScore5_13)"
# If organizational score is 1 or true, check status of client
# If client fails, then note category in audit file
if [ "$Audit5_13" = "1" ]; then
		screensaverPwd="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.screensaver askForPassword)"
		if [ "$screensaverPwd" = "1" ]; then
			echo "$(date -u)" "5.13 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore5_13 -bool false; else
			echo "* 5.13 Require a password to wake the computer from sleep or screen saver" >> "$auditfilelocation"
			echo "$(date -u)" "5.13 fix" | tee -a "$logFile"
		fi
	fi

# 5.14 Ensure system is set to hibernate
# Verify organizational score
Audit5_14="$(defaults read "$plistlocation" OrgScore5_14)"
# If client fails, then note category in audit file
if [ "$Audit5_14" = "1" ]; then
	macType=$(system_profiler SPHardwareDataType | egrep -c "Model Identifier: MacBook")
	if [[ "$macType" -ge 0 ]]; then
		hibernateValue=$(pmset -g | egrep standbydelay | awk '{print $2}')
		if [[ "$hibernateValue" == "" ]] || [[ "$hibernateValue" -gt 900 ]]; then
			echo "$(date -u)" "5.14 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore5_14 -bool false; else
			echo "* 5.14 Require a password to wake the computer from sleep or screen saver" >> "$auditfilelocation"
			echo "$(date -u)" "5.14 fix" | tee -a "$logFile"
			fi
	else
		echo "$(date -u)" "5.14 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore5_14 -bool false
				fi
	fi

# 5.15 Require an administrator password to access system-wide preferences
# Verify organizational score
Audit5_15="$(defaults read "$plistlocation" OrgScore5_15)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_15" = "1" ]; then
	adminSysPrefs="$(security authorizationdb read system.preferences 2> /dev/null | grep -A1 shared | grep -E '(true|false)' | grep -c "true")"
	# If client fails, then note category in audit file
	if [ "$adminSysPrefs" = "1" ]; then
		echo "* 5.15 Require an administrator password to access system-wide preferences" >> "$auditfilelocation"
		echo "$(date -u)" "5.15 fix" | tee -a "$logFile"; else
		echo "$(date -u)" "5.15 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore5_15 -bool false
	fi
fi

# 5.16 Disable ability to login to another user's active and locked session
# Verify organizational score
Audit5_16="$(defaults read "$plistlocation" OrgScore5_16)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_16" = "1" ]; then
	screensaverRules="$(/usr/bin/security authorizationdb read system.login.screensaver | grep -c 'se-login-window-ui')"
	# If client fails, then note category in audit file
	if [ "$screensaverRules" = "1" ]; then
		echo "$(date -u)" "5.16 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore5_16 -bool false; else
		echo "* 5.16 Disable ability to login to another user's active and locked session" >> "$auditfilelocation"
		echo "$(date -u)" "5.16 fix" | tee -a "$logFile"
	fi
fi

# 5.17 Create a custom message for the Login Screen
# Verify organizational score
Audit5_17="$(defaults read "$plistlocation" OrgScore5_17)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_17" = "1" ]; then
		loginMessage="$(defaults read /Library/Preferences/com.apple.loginwindow.plist LoginwindowText)"
		if [[ $loginMessage = "" ]] || [[ $loginMessage = *"does not exist"* ]]; then
			echo "* 5.17 Create a custom message for the Login Screen" >> "$auditfilelocation"
			echo "$(date -u)" "5.17 fix" | tee -a "$logFile"; else
			echo "$(date -u)" "5.17 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore5_17 -bool false
		fi
	fi

# 5.18 Create a Login window banner
# Policy Banner https://support.apple.com/en-us/HT202277
# Verify organizational score
Audit5_18="$(defaults read "$plistlocation" OrgScore5_18)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_18" = "1" ]; then
	# If client fails, then note category in audit file
	if [ -e /Library/Security/PolicyBanner.txt ] || [ -e /Library/Security/PolicyBanner.rtf ] || [ -e /Library/Security/PolicyBanner.rtfd ]; then
		echo "$(date -u)" "5.18 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore5_18 -bool false; else
		echo "* 5.18 Create a Login window banner" >> "$auditfilelocation"
		echo "$(date -u)" "5.18 fix" | tee -a "$logFile"
	fi
fi

# 5.20 Disable Fast User Switching (Not Scored)
# Verify organizational score
Audit5_20="$(defaults read "$plistlocation" OrgScore5_20)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_20" = "1" ]; then
		FastUserSwitching="$(defaults read /Library/Preferences/.GlobalPreferences MultipleSessionEnabled)"
		if [ "$FastUserSwitching" = "0" ]; then
			echo "$(date -u)" "5.20 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore5_20 -bool false; else
			echo "* 5.20 Disable Fast User Switching" >> "$auditfilelocation"
			echo "$(date -u)" "5.20 fix" | tee -a "$logFile"
		fi
	fi

# 5.23 System Integrity Protection status
# Verify organizational score
Audit5_23="$(defaults read "$plistlocation" OrgScore5_23)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_23" = "1" ]; then
	sipEnabled="$(/usr/bin/csrutil status | awk '{print $5}')"
	# If client fails, then note category in audit file
	if [ "$sipEnabled" = "enabled." ]; then
		echo "$(date -u)" "5.23 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore5_23 -bool false; else
		echo "* 5.23 System Integrity Protection status - not enabled" >> "$auditfilelocation"
		echo "$(date -u)" "5.23 fix" | tee -a "$logFile"
	fi
fi

# 6.1.1 Display login window as name and password
# Verify organizational score
Audit6_1_1="$(defaults read "$plistlocation" OrgScore6_1_1)"
# If organizational score is 1 or true, check status of client
if [ "$Audit6_1_1" = "1" ]; then
		loginwindowFullName="$(defaults read /Library/Preferences/com.apple.loginwindow SHOWFULLNAME)"
		if [ "$loginwindowFullName" != "1" ]; then
			echo "* 6.1.1 Display login window as name and password" >> "$auditfilelocation"
			echo "$(date -u)" "6.1.1 fix" | tee -a "$logFile"; else
			echo "$(date -u)" "6.1.1 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore6_1_1 -bool false
		fi
	fi

# 6.1.2 Disable "Show password hints"
# Verify organizational score
Audit6_1_2="$(defaults read "$plistlocation" OrgScore6_1_2)"
# If organizational score is 1 or true, check status of client
if [ "$Audit6_1_2" = "1" ]; then
		passwordHints="$(defaults read /Library/Preferences/com.apple.loginwindow RetriesUntilHint)"
		if [ "$passwordHints" -gt 0 ] || [ "$passwordHints" = *exist* ]; then
			echo "* 6.1.2 Disable Show password hints" >> "$auditfilelocation"
			echo "$(date -u)" "6.1.2 fix" | tee -a "$logFile"; else
			echo "$(date -u)" "6.1.2 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore6_1_2 -bool false
		fi
	fi

# 6.1.3 Disable guest account
# Verify organizational score
Audit6_1_3="$(defaults read "$plistlocation" OrgScore6_1_3)"
# If organizational score is 1 or true, check status of client
if [ "$Audit6_1_3" = "1" ]; then
		guestEnabled="$(defaults read /Library/Preferences/com.apple.loginwindow.plist GuestEnabled)"
		if [ "$guestEnabled" = 1 ]; then
			echo "* 6.1.3 Disable guest account" >> "$auditfilelocation"
			echo "$(date -u)" "6.1.3 fix" | tee -a "$logFile"; else
			echo "$(date -u)" "6.1.3 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore6_1_3 -bool false
		fi
	fi

# 6.1.4 Disable "Allow guests to connect to shared folders"
# Verify organizational score
Audit6_1_4="$(defaults read "$plistlocation" OrgScore6_1_4)"
# If organizational score is 1 or true, check status of client
if [ "$Audit6_1_4" = "1" ]; then
		afpGuestEnabled="$(defaults read /Library/Preferences/com.apple.AppleFileServer guestAccess)"
		smbGuestEnabled="$(defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess)"
		if [ "$afpGuestEnabled" = "1" ] || [ "$smbGuestEnabled" = "1" ]; then
			echo "* 6.1.4 Disable Allow guests to connect to shared folders" >> "$auditfilelocation"
			echo "$(date -u)" "6.1.4 fix" | tee -a "$logFile"; else
			echo "$(date -u)" "6.1.4 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore6_1_4 -bool false
		fi
	fi

# 6.1.5 Remove Guest home folder
# Verify organizational score
Audit6_1_5="$(defaults read "$plistlocation" OrgScore6_1_5)"
# If organizational score is 1 or true, check status of client
if [ "$Audit6_1_5" = "1" ]; then
	# If client fails, then note category in audit file
	if [ -e /Users/Guest ]; then
		echo "* 6.1.5 Remove Guest home folder" >> "$auditfilelocation"
		echo "$(date -u)" "6.1.5 fix" | tee -a "$logFile"; else
		echo "$(date -u)" "6.1.5 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore6_1_5 -bool false
	fi
fi

# 6.2 Turn on filename extensions
# Does not work as a Configuration Profile - .GlobalPreferences.plist
# Verify organizational score
Audit6_2="$(defaults read "$plistlocation" OrgScore6_2)"
# If organizational score is 1 or true, check status of client
if [ "$Audit6_2" = "1" ]; then
		filenameExt="$(defaults read /Users/"$currentUser"/Library/Preferences/.GlobalPreferences.plist AppleShowAllExtensions)"
	# If client fails, then note category in audit file
	if [ "$filenameExt" = "1" ]; then
		echo "$(date -u)" "6.2 passed" | tee -a "$logFile"
		defaults write "$plistlocation" OrgScore6_2 -bool false; else
		echo "* 6.2 Turn on filename extensions" >> "$auditfilelocation"
		echo "$(date -u)" "6.2 fix" | tee -a "$logFile"
	fi
fi

# 6.3 Disable the automatic run of safe files in Safari
# Configuration Profile - Custom payload > com.apple.Safari > AutoOpenSafeDownloads=false
# Best remeidated with a configuration profile
# Verify organizational score
Audit6_3="$(defaults read "$plistlocation" OrgScore6_3)"
# If organizational score is 1 or true, check status of client
if [ "$Audit6_3" = "1" ]; then
		safariSafe="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.Safari AutoOpenSafeDownloads)"
		if [ "$safariSafe" = "1" ]; then
			echo "* 6.3 Disable the automatic run of safe files in Safari" >> "$auditfilelocation"
			echo "$(date -u)" "6.3 fix" | tee -a "$logFile"; else
			echo "$(date -u)" "6.3 passed" | tee -a "$logFile"
			defaults write "$plistlocation" OrgScore6_3 -bool false
		fi
	fi

echo "$(date -u)" "Audit complete" | tee -a "$logFile"
exit 0


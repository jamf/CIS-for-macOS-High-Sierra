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
# updated for 10.13 CIS benchmarks by Erin McDonald, Jamf Jan 2019

# USAGE
# Reads from plist at /Library/Application Support/SecurityScoring/org_security_score.plist by default.
# For "true" items, runs query for current computer/user compliance.
# Non-compliant items are logged to /Library/Application Support/SecurityScoring/org_audit

plistlocation="/Library/Application Support/SecurityScoring/org_security_score.plist"
currentUser="$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')"
hardwareUUID="$(/usr/sbin/system_profiler SPHardwareDataType | grep "Hardware UUID" | awk -F ": " '{print $2}' | xargs)"

logFile="/Library/Application Support/SecurityScoring/remediation.log"
# Append to existing logFile
echo "$(date -u)" "Beginning remediation" >> "$logFile"
# Create new logFile
# echo "$(date -u)" "Beginning remediation" > "$logFile"	

if [[ ! -e $plistlocation ]]; then
	echo "No scoring file present"
	exit 0
fi

# 1.1 Verify all Apple provided software is current
# Verify organizational score
Audit1_1="$(defaults read "$plistlocation" OrgScore1_1)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit1_1" = "1" ]; then
	echo "$(date -u)" "1.1 remediated" | tee -a "$logFile"
	# NOTE: INSTALLS ALL RECOMMENDED SOFTWARE UPDATES FROM CLIENT'S CONFIGURED SUS SERVER
	softwareupdate -i -r
fi

# 1.2 Enable Auto Update
# Verify organizational score
Audit1_2="$(defaults read "$plistlocation" OrgScore1_2)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit1_2" = "1" ]; then
	defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
	echo "$(date -u)" "1.2 remediated" | tee -a "$logFile"
fi

# 1.3 Enable app update installs
# Verify organizational score
Audit1_3="$(defaults read "$plistlocation" OrgScore1_3)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit1_3" = "1" ]; then
	defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool true
	echo "$(date -u)" "1.3 remediated" | tee -a "$logFile"
fi

# 1.4 Enable system data files and security update installs 
# Verify organizational score
Audit1_4="$(defaults read "$plistlocation" OrgScore1_4)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit1_4" = "1" ]; then
	defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true
	defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
	echo "$(date -u)" "1.4 remediated" | tee -a "$logFile"
fi

# 1.5 Enable OS X update installs 
# Verify organizational score
Audit1_5="$(defaults read "$plistlocation" OrgScore1_5)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit1_5" = "1" ]; then
	defaults write /Library/Preferences/com.apple.commerce AutoUpdateRestartRequired -bool true
	echo "$(date -u)" "1.5 remediated" | tee -a "$logFile"
fi

# 2.1.1 Turn off Bluetooth, if no paired devices exist
# Verify organizational score
Audit2_1_1="$(defaults read "$plistlocation" OrgScore2_1_1)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_1_1" = "1" ]; then
	echo "$(date -u)" "Checking 2.1.1" | tee -a "$logFile"
	connectable="$( system_profiler SPBluetoothDataType | grep Connectable | awk '{print $2}' | head -1 )"
	if [ "$connectable" = "Yes" ]; then
		echo "$(date -u)" "2.1.1 passed" | tee -a "$logFile"; else
		defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -bool false
		killall -HUP blued
		echo "$(date -u)" "2.1.1 remediated" | tee -a "$logFile"
	fi
fi

# 2.1.3 Show Bluetooth status in menu bar
# Verify organizational score
Audit2_1_3="$(defaults read "$plistlocation" OrgScore2_1_3)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_1_3" = "1" ]; then
	open "/System/Library/CoreServices/Menu Extras/Bluetooth.menu"
	echo "$(date -u)" "2.1.3 remediated" | tee -a "$logFile"
fi

## 2.2.1 Enable "Set time and date automatically" (Not Scored)
# Verify organizational score
Audit2_2_1="$(defaults read "$plistlocation" OrgScore2_2_1)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_2_1" = "1" ]; then
	systemsetup -setusingnetworktime on
	echo "$(date -u)" "2.4.1 remediated" | tee -a "$logFile"
fi

# 2.2.2 Ensure time set is within appropriate limits
# Not audited - only enforced if identified as priority
# Verify organizational score
Audit2_2_2="$(defaults read "$plistlocation" OrgScore2_2_2)"
# If organizational score is 1 or true, check status of client
if [ "$Audit2_2_2" = "1" ]; then
	systemsetup -setusingnetworktime off
	systemsetup -setusingnetworktime on
#	timeServer="$(systemsetup -getnetworktimeserver | awk '{print $4}')"
#	ntpdate -sv "$timeServer"
	echo "$(date -u)" "2.2.2 enforced" | tee -a "$logFile"
fi

# 2.3.1 Set an inactivity interval of 20 minutes or less for the screen saver 
# Verify organizational score
Audit2_3_1="$(defaults read "$plistlocation" OrgScore2_3_1)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_3_1" = "1" ]; then
	defaults write /Users/"$currentUser"/Library/Preferences/ByHost/com.apple.screensaver."$hardwareUUID".plist idleTime -int 1200
	echo "$(date -u)" "2.3.1 remediated" | tee -a "$logFile"
fi

# 2.3.2 Secure screen saver corners 
# Verify organizational score
Audit2_3_2="$(defaults read "$plistlocation" OrgScore2_3_2)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_3_2" = "1" ]; then
	bl_corner="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-bl-corner)"
	tl_corner="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-tl-corner)"
	tr_corner="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-tr-corner)"
	br_corner="$(defaults read /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-br-corner)"
	if [ "$bl_corner" = "6" ]; then
		echo "Disabling hot corner"
		defaults write /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-bl-corner 1
		/usr/bin/killall Dock
		echo "$(date -u)" "2.3.2 remediated" | tee -a "$logFile"
	fi
	if [ "$tl_corner" = "6" ]; then
		echo "Disabling hot corner"
		defaults write /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-tl-corner 1
		/usr/bin/killall Dock
		echo "$(date -u)" "2.3.2 remediated" | tee -a "$logFile"
	fi
	if [ "$tr_corner" = "6" ]; then
		echo "Disabling hot corner"
		defaults write /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-tr-corner 1
		/usr/bin/killall Dock
		echo "$(date -u)" "2.3.2 remediated" | tee -a "$logFile"
	fi
	if [ "$br_corner" = "6" ]; then
		echo "Disabling hot corner"
		defaults write /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-br-corner 1
		/usr/bin/killall Dock
		echo "$(date -u)" "2.3.2 remediated" | tee -a "$logFile"
	fi
fi

# 2.3.3 Familiarize users with screen lock tools or corner to Start Screen Saver  
# Verify organizational score
Audit2_3_3="$(defaults read "$plistlocation" OrgScore2_3_3)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
# Sets bottom left corner to start screen saver
if [ "$Audit2_3_3" = "1" ]; then
		defaults write /Users/"$currentUser"/Library/Preferences/com.apple.dock wvous-bl-corner 5
		echo "$(date -u)" "2.3.3 remediated" | tee -a "$logFile"
fi

# 2.4.1 Disable Remote Apple Events 
# Verify organizational score
Audit2_4_1="$(defaults read "$plistlocation" OrgScore2_4_1)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_4_1" = "1" ]; then
		systemsetup -setremoteappleevents off
		echo "$(date -u)" "2.4.1 remediated" | tee -a "$logFile"
fi

# 2.4.2 Disable Internet Sharing 
# Verify organizational score
Audit2_4_2="$(defaults read "$plistlocation" OrgScore2_4_2)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_4_2" = "1" ]; then
	/usr/libexec/PlistBuddy -c "Delete :NAT:AirPort:Enabled"  /Library/Preferences/SystemConfiguration/com.apple.nat.plist
	/usr/libexec/PlistBuddy -c "Add :NAT:AirPort:Enabled bool false" /Library/Preferences/SystemConfiguration/com.apple.nat.plist
	/usr/libexec/PlistBuddy -c "Delete :NAT:Enabled"  /Library/Preferences/SystemConfiguration/com.apple.nat.plist
	/usr/libexec/PlistBuddy -c "Add :NAT:Enabled bool false" /Library/Preferences/SystemConfiguration/com.apple.nat.plist
	/usr/libexec/PlistBuddy -c "Delete :NAT:PrimaryInterface:Enabled"  /Library/Preferences/SystemConfiguration/com.apple.nat.plist
	/usr/libexec/PlistBuddy -c "Add :NAT:PrimaryInterface:Enabled bool false" /Library/Preferences/SystemConfiguration/com.apple.nat.plist
	echo "$(date -u)" "2.4.2 enforced" | tee -a "$logFile"
fi

# 2.4.3 Disable Screen Sharing 
# Verify organizational score
Audit2_4_3="$(defaults read "$plistlocation" OrgScore2_4_3)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_4_3" = "1" ]; then
	launchctl unload -w /System/Library/LaunchDaemons/com.apple.screensharing.plist
	/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -stop
	echo "$(date -u)" "2.4.3 remediated" | tee -a "$logFile"
fi

# 2.4.4 Disable Printer Sharing 
# Verify organizational score
Audit2_4_4="$(defaults read "$plistlocation" OrgScore2_4_4)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_4_4" = "1" ]; then
	/usr/sbin/cupsctl --no-share-printers
	while read -r _ _ printer _; do
		/usr/sbin/lpadmin -p "${printer/:}" -o printer-is-shared=false
	done < <(/usr/bin/lpstat -v)
	echo "$(date -u)" "2.4.4 remediated" | tee -a "$logFile"
fi

# 2.4.5 Disable Remote Login 
# Verify organizational score
Audit2_4_5="$(defaults read "$plistlocation" OrgScore2_4_5)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_4_5" = "1" ]; then
	systemsetup -f -setremotelogin off
	echo "$(date -u)" "2.4.5 remediated" | tee -a "$logFile"
fi

# 2.4.6 Disable DVD or CD Sharing 
# Verify organizational score
Audit2_4_6="$(defaults read "$plistlocation" OrgScore2_4_6)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_4_6" = "1" ]; then
	launchctl unload -w /System/Library/LaunchDaemons/com.apple.ODSAgent.plist
	echo "$(date -u)" "2.4.6 remediated" | tee -a "$logFile"
fi

# 2.4.7 Disable Bluetooth Sharing
# Verify organizational score
Audit2_4_7="$(defaults read "$plistlocation" OrgScore2_4_7)"
# If organizational score is 1 or true, check status of client and user
# If client fails, then remediate
if [ "$Audit2_4_7" = "1" ]; then
	/usr/libexec/PlistBuddy -c "Delete :PrefKeyServicesEnabled"  /Users/"$currentUser"/Library/Preferences/ByHost/com.apple.Bluetooth."$hardwareUUID".plist
	/usr/libexec/PlistBuddy -c "Add :PrefKeyServicesEnabled bool false"  /Users/"$currentUser"/Library/Preferences/ByHost/com.apple.Bluetooth."$hardwareUUID".plist
	echo "$(date -u)" "2.4.7 remediated" | tee -a "$logFile"
fi

# 2.4.8 Disable File Sharing
# Verify organizational score
Audit2_4_8="$(defaults read "$plistlocation" OrgScore2_4_8)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_4_8" = "1" ]; then
	launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist
	launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist
	echo "$(date -u)" "2.4.8 remediated" | tee -a "$logFile"
fi

# 2.4.9 Disable Remote Management
# Verify organizational score
Audit2_4_9="$(defaults read "$plistlocation" OrgScore2_4_9)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_4_9" = "1" ]; then
	launchctl unload -w /System/Library/LaunchDaemons/com.apple.screensharing.plist
	/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -stop
	echo "$(date -u)" "2.4.9 remediated" | tee -a "$logFile"
fi

# 2.5.1 Disable "Wake for network access"
# Verify organizational score
Audit2_5_1="$(defaults read "$plistlocation" OrgScore2_5_1)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_5_1" = "1" ]; then
	pmset -a womp 0
	echo "$(date -u)" "2.5.1 remediated" | tee -a "$logFile"
fi

# 2.6.2 Enable Gatekeeper 
# Verify organizational score
Audit2_6_2="$(defaults read "$plistlocation" OrgScore2_6_2)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_6_2" = "1" ]; then
	spctl --master-enable
	echo "$(date -u)" "2.6.2 remediated" | tee -a "$logFile"
fi

# 2.6.3 Enable Firewall 
# Verify organizational score
Audit2_6_3="$(defaults read "$plistlocation" OrgScore2_6_3)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_6_3" = "1" ]; then
	defaults write /Library/Preferences/com.apple.alf globalstate -int 2
	echo "$(date -u)" "2.6.3 remediated" | tee -a "$logFile"
fi

# 2.6.4 Enable Firewall Stealth Mode 
# Verify organizational score
Audit2_6_4="$(defaults read "$plistlocation" OrgScore2_6_4)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_6_4" = "1" ]; then
	/usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
	echo "$(date -u)" "2.6.4 remediated" | tee -a "$logFile"
fi

# 2.6.5 Review Application Firewall Rules
# Verify organizational score
Audit2_6_5="$(defaults read "$plistlocation" OrgScore2_6_5)"
# If organizational score is 1 or true, check status of client
# If client fails, then alert to need of remediation
if [ "$Audit2_6_5" = "1" ]; then
	echo "$(date -u)" "2.6.5 not remediated" | tee -a "$logFile"
fi

# 2.6.8 Disable sending diagnostic and usage data to Apple
# Verify Organizational score
Audit2_6_8="$(defaults read "$plistlocation" OrgScore2_6_8)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_6_8" = "1" ]; then
	AppleDiagn=$(defaults read /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit)
		if [ $AppleDiagn == 1 ]; then 
	defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit -int 0
	echo "$(date -u)" "2.6.8 remediated" | tee -a "$logFile"
fi
fi

# 2.8.1 Time Machine Auto-Backup
# Verify organizational score
Audit2_8_1="$(defaults read "$plistlocation" OrgScore2_8_1)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_8_1" = "1" ]; then
	defaults write /Library/Preferences/com.apple.TimeMachine.plist AutoBackup 1
	echo "$(date -u)" "2.8.1 remediated" | tee -a "$logFile"
fi

# 2.9 Pair the remote control infrared receiver if enabled
# Verify organizational score
Audit2_9="$(defaults read "$plistlocation" OrgScore2_9)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_9" = "1" ]; then
	defaults write /Library/Preferences/com.apple.driver.AppleIRController DeviceEnabled -bool false
	echo "$(date -u)" "2.9 remediated" | tee -a "$logFile"
fi

# 2.10 Enable Secure Keyboard Entry in terminal.app 
# Verify organizational score
Audit2_10="$(defaults read "$plistlocation" OrgScore2_10)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit2_10" = "1" ]; then
	defaults write /Users/"$currentUser"/Library/Preferences/com.apple.Terminal SecureKeyboardEntry -bool true
	echo "$(date -u)" "2.10 remediated" | tee -a "$logFile"
fi

# 3.1 Enable security auditing
# Verify organizational score
Audit3_1="$(defaults read "$plistlocation" OrgScore3_1)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit3_2" = "1" ]; then
	echo "$(date -u)" "Checking 3.2" | tee -a "$logFile"
	auditdEnabled=$(launchctl list | grep -c auditd)
	if [ "$auditdEnabled" -gt "0" ]; then
		echo "$(date -u)" "3.1.3 passed" | tee -a "$logFile"; else
		launchctl load -w /System/Library/LaunchDaemons/com.apple.auditd.plist
		echo "$(date -u)" "3.2 remediated" | tee -a "$logFile"
	fi
fi

# 3.2 Configure Security Auditing Flags
# Verify organizational score
Audit3_2="$(defaults read "$plistlocation" OrgScore3_2)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit3_2" = "1" ]; then
	cp /etc/security/audit_control /etc/security/audit_control_old
	sed "s/"flags:lo,aa"/"flags:lo,ad,fd,fm,-all"/g" /etc/security/audit_control_old > /etc/security/audit_control
	chmod 644 /etc/security/audit_control
	chown root:wheel /etc/security/audit_control
	echo "$(date -u)" "3.2 remediated" | tee -a "$logFile"
fi

# 3.3 Ensure security auditing retention
# Verify organizational score
Audit3_3="$(defaults read "$plistlocation" OrgScore3_3)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit3_3" = "1" ]; then
	cp /etc/security/audit_control /etc/security/audit_control_old
	oldExpireAfter=$(cat /etc/security/audit_control | egrep expire-after)
	sed "s/${oldExpireAfter}/expire-after:60d OR 1G" /etc/security/audit_control_old > /etc/security/audit_control
	chmod 644 /etc/security/audit_control
	chown root:wheel /etc/security/audit_control
	echo "$(date -u)" "3.3 remediated" | tee -a "$logFile"	
    fi

# 3.5 Retain install.log for 365 or more days 
# Verify organizational score
Audit3_5="$(defaults read "$plistlocation" OrgScore3_5)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit3_5" = "1" ]; then
	installRetention="$(grep -i ttl /etc/asl/com.apple.install | awk -F'ttl=' '{print $2}')"
	if [[ "$installRetention" = "" ]]; then
		mv /etc/asl/com.apple.install /etc/asl/com.apple.install.old
		sed '$s/$/ ttl=365/' /etc/asl/com.apple.install.old > /etc/asl/com.apple.install
		chmod 644 /etc/asl/com.apple.install
		chown root:wheel /etc/asl/com.apple.install
		echo "$(date -u)" "3.5 remediated" | tee -a "$logFile"	
	else
	if [[ "$installRetention" -lt "365" ]]; then
		mv /etc/asl/com.apple.install /etc/asl/com.apple.install.old
		sed "s/"ttl=$installRetention"/"ttl=365"/g" /etc/asl/com.apple.install.old > /etc/asl/com.apple.install
		chmod 644 /etc/asl/com.apple.install
		chown root:wheel /etc/asl/com.apple.install
		echo "$(date -u)" "3.5 remediated" | tee -a "$logFile"	
	fi
	fi
fi

# 3.6 Ensure firewall is configured to log
# Verify organizational score
Audit3_6="$(defaults read "$plistlocation" OrgScore3_6)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit3_6" = "1" ]; then
	/usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on
	echo "$(date -u)" "3.6 remediated" | tee -a "$logFile"
fi

# 4.1 Disable Bonjour advertising service 
# Verify organizational score
Audit4_1="$(defaults read "$plistlocation" OrgScore4_1)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit4_1" = "1" ]; then
	defaults write /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements -bool YES
	echo "$(date -u)" "4.1 remediated" | tee -a "$logFile"
fi

# 4.2 Enable "Show Wi-Fi status in menu bar" 
# Verify organizational score
Audit4_2="$(defaults read "$plistlocation" OrgScore4_2)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit4_2" = "1" ]; then
	open "/System/Library/CoreServices/Menu Extras/AirPort.menu"
	echo "$(date -u)" "4.2 remediated" | tee -a "$logFile"
fi

# 4.4 Ensure http server is not running 
# Verify organizational score
Audit4_4="$(defaults read "$plistlocation" OrgScore4_4)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit4_4" = "1" ]; then
	apachectl stop
	defaults write /System/Library/LaunchDaemons/org.apache.httpd Disabled -bool true
	echo "$(date -u)" "4.4 remediated" | tee -a "$logFile"
fi

# 4.5 Ensure nfs server is not running
# Verify organizational score
Audit4_5="$(defaults read "$plistlocation" OrgScore4_5)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit4_5" = "1" ]; then
	nfsd disable
	rm -rf /etc/export
	echo "$(date -u)" "4.5 remediated" | tee -a "$logFile"
fi

# 5.1.1 Secure Home Folders
# Verify organizational score
Audit5_1_1="$(defaults read "$plistlocation" OrgScore5_1_1)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_1_1" = "1" ]; then
	# If client fails, then remediate
	IFS=$'\n'
	for userDirs in $( find /Users -mindepth 1 -maxdepth 1 -type d -perm -1 | grep -v "Shared" | grep -v "Guest" ); do
		chmod og-rwx "$userDirs"
	done
	echo "$(date -u)" "5.1.1 enforced" | tee -a "$logFile"
	unset IFS
fi

# 5.1.2 Check System Wide Applications for appropriate permissions
# Verify organizational score
Audit5_1_2="$(defaults read "$plistlocation" OrgScore5_1_2)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit5_1_2" = "1" ]; then
	IFS=$'\n'
	for apps in $( find /Applications -iname "*\.app" -type d -perm -2 ); do
		chmod -R o-w "$apps"
	done
	echo "$(date -u)" "5.1.2 enforced" | tee -a "$logFile"
	unset IFS
fi

# 5.1.3 Check System folder for world writable files
# Verify organizational score
Audit5_1_3="$(defaults read "$plistlocation" OrgScore5_1_3)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit5_1_3" = "1" ]; then
	IFS=$'\n'
	for sysPermissions in $( find /System -type d -perm -2 | grep -v "Public/Drop Box" ); do
		chmod -R o-w "$sysPermissions"
	done
	echo "$(date -u)" "5.1.3 enforced" | tee -a "$logFile"
	unset IFS
fi

# 5.1.4 Check Library folder for world writable files
# Verify organizational score
Audit5_1_4="$(defaults read "$plistlocation" OrgScore5_1_4)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit5_1_4" = "1" ]; then
	# Exempts Adobe files by default!
	# for libPermissions in $( find /Library -type d -perm -2 -ls | grep -v Caches ); do
	IFS=$'\n'
	for libPermissions in $( find /Library -type d -perm -2 | grep -v Caches | grep -v Adobe | grep -v VMware); do
		chmod -R o-w "$libPermissions"
	done
	echo "$(date -u)" "5.1.4 enforced" | tee -a "$logFile"
	unset IFS
fi

# 5.3 Reduce the sudo timeout period
# Verify organizational score
Audit5_3="$(defaults read "$plistlocation" OrgScore5_3)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit5_3" = "1" ]; then
	echo "Defaults timestamp_timeout=0" >> /etc/sudoers
	echo "$(date -u)" "5.3 remediated" | tee -a "$logFile"
fi

# 5.4 Use a separate timestamp for each user/tty combo
# Verify organizational score
Audit5_4="$(defaults read "$plistlocation" OrgScore5_4)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit5_4" = "1" ]; then
	sed -i ".old" '/Default !tty_tickets/d' /etc/sudoers
	chmod 644 /etc/sudoers
	chown root:wheel /etc/sudoers
	echo "$(date -u)" "5.4 remediated" | tee -a "$logFile"
fi

# 5.7 Automatically lock the login keychain for inactivity
# 5.8 Ensure login keychain is locked when the computer sleeps
# If both 5.7 and 5.8 need to be set, both commands must be run at the same time
# Verify organizational score
Audit5_7="$(defaults read "$plistlocation" OrgScore5_7)"
Audit5_8="$(defaults read "$plistlocation" OrgScore5_8)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit5_7" = "1" ] && [ "$Audit5_8" = 1 ]; then
echo "$(date -u)" "Checking 5.7 and 5.8" | tee -a "$logFile"
	security set-keychain-settings -l -u -t 21600s /Users/"$currentUser"/Library/Keychains/login.keychain
	echo "$(date -u)" "5.7 and 5.8 remediated" | tee -a "$logFile"
	elif [ "$Audit5_7" = "1" ] && [ "$Audit5_8" = 0 ]; then
		echo "$(date -u)" "Checking 5.7" | tee -a "$logFile"
		security set-keychain-settings -u -t 21600s /Users/"$currentUser"/Library/Keychains/login.keychain
		echo "$(date -u)" "5.7 remediated" | tee -a "$logFile"
		elif [ "$Audit5_7" = "0" ] && [ "$Audit5_8" = 1 ]; then
			echo "$(date -u)" "Checking 5.8" | tee -a "$logFile"
			security set-keychain-settings -l /Users/"$currentUser"/Library/Keychains/login.keychain
			echo "$(date -u)" "5.8 remediated" | tee -a "$logFile"
fi


# 5.9 Enable OCSP and CRL certificate checking
# Verify organizational score
Audit5_9="$(defaults read "$plistlocation" OrgScore5_9)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit5_9" = "1" ]; then
	defaults write com.apple.security.revocation OCSPStyle -string RequireIfPresent
	defaults write com.apple.security.revocation CRLStyle -string RequireIfPresent
	defaults write /Users/"$currentUser"/Library/Preferences/com.apple.security.revocation OCSPStyle -string RequireIfPresent
	defaults write /Users/"$currentUser"/Library/Preferences/com.apple.security.revocation CRLStyle -string RequireIfPresent
	echo "$(date -u)" "5.9 remediated" | tee -a "$logFile"
fi

# 5.11 Do not enable the "root" account
# Verify organizational score
Audit5_11="$(defaults read "$plistlocation" OrgScore5_11)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit5_11" = "1" ]; then
	dscl . -create /Users/root UserShell /usr/bin/false
	echo "$(date -u)" "5.11 remediated" | tee -a "$logFile"
fi

# 5.12 Disable automatic login
# Verify organizational score
Audit5_12="$(defaults read "$plistlocation" OrgScore5_12)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit5_12" = "1" ]; then
	defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser
	echo "$(date -u)" "5.12 remediated" | tee -a "$logFile"
fi

# 5.13 Require a password to wake the computer from sleep or screen saver
# Verify organizational score
Audit5_13="$(defaults read "$plistlocation" OrgScore5_13)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit5_13" = "1" ]; then
	defaults write /Users/"$currentUser"/Library/Preferences/com.apple.screensaver askForPassword -int 1
	echo "$(date -u)" "5.13 remediated" | tee -a "$logFile"
fi

# 5.14 Ensure system is set to hibernate
# Verify organizational score
Audit5_14="$(defaults read "$plistlocation" OrgScore5_14)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit5_14" = "1" ]; then
	pmset -a standbydelay 900
	echo "$(date -u)" "5.14 remediated" | tee -a "$logFile"
fi


# 5.15 Require an administrator password to access system-wide preferences
# Verify organizational score
Audit5_15="$(defaults read "$plistlocation" OrgScore5_15)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit5_15" = "1" ]; then
	security authorizationdb read system.preferences > /tmp/system.preferences.plist
	/usr/libexec/PlistBuddy -c "Set :shared false" /tmp/system.preferences.plist
	security authorizationdb write system.preferences < /tmp/system.preferences.plist
	echo "$(date -u)" "5.15 remediated" | tee -a "$logFile"
fi

# 5.16 Disable ability to login to another user's active and locked session
# Verify organizational score
Audit5_16="$(defaults read "$plistlocation" OrgScore5_16)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit5_16" = "1" ]; then
	/usr/bin/security authorizationdb write system.login.screensaver "use-login-window-ui"
	echo "$(date -u)" "5.16 remediated" | tee -a "$logFile"
fi

# 5.17 Create a custom message for the Login Screen
# Verify organizational score
Audit5_17="$(defaults read "$plistlocation" OrgScore5_17)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_17" = "1" ]; then
	PolicyBannerText="CIS mandated Login Window banner"
	defaults write /Library/Preferences/com.apple.loginwindow.plist LoginwindowText -string "$PolicyBannerText"
	echo "$(date -u)" "5.17 remediated" | tee -a "$logFile"
fi

# 5.18 Create a Login window banner
# Policy Banner https://support.apple.com/en-us/HT202277
# Verify organizational score
Audit5_18="$(defaults read "$plistlocation" OrgScore5_18)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_18" = "1" ]; then
	PolicyBannerText="CIS mandated Login Window banner"
	/bin/echo "$PolicyBannerText" > "/Library/Security/PolicyBanner.txt"
	/bin/chmod 755 "/Library/Security/PolicyBanner."* 
	echo "$(date -u)" "5.18 remediated" | tee -a "$logFile"
fi

# 5.20 Disable Fast User Switching (Not Scored)
# Verify organizational score
Audit5_20="$(defaults read "$plistlocation" OrgScore5_20)"
# If organizational score is 1 or true, check status of client
if [ "$Audit5_20" = "1" ]; then
	defaults write /Library/Preferences/.GlobalPreferences MultipleSessionEnabled -bool false
	echo "$(date -u)" "5.20 remediated" | tee -a "$logFile"
fi

# 5.23 System Integrity Protection status
# Verify organizational score
Audit5_23="$(defaults read "$plistlocation" OrgScore5_23)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit5_23" = "1" ]; then
	echo "This tool needs to be executed from the Recovery OS."
	#/usr/bin/csrutil enable
	#echo "$(date -u)" "5.18 remediated" | tee -a "$logFile"
fi

# 6.1.1 Display login window as name and password
# Verify organizational score
Audit6_1_1="$(defaults read "$plistlocation" OrgScore6_1_1)"
# If organizational score is 1 or true, check status of client
if [ "$Audit6_1_1" = "1" ]; then
	defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true
	echo "$(date -u)" "6.1.1 remediated" | tee -a "$logFile"
fi

# 6.1.2 Disable "Show password hints"
# Verify organizational score
Audit6_1_2="$(defaults read "$plistlocation" OrgScore6_1_2)"
# If organizational score is 1 or true, check status of client
if [ "$Audit6_1_2" = "1" ]; then
	defaults write /Library/Preferences/com.apple.loginwindow RetriesUntilHint -int 0
	echo "$(date -u)" "6.1.2 remediated" | tee -a "$logFile"
fi

# 6.1.3 Disable guest account
# Verify organizational score
Audit6_1_3="$(defaults read "$plistlocation" OrgScore6_1_3)"
# If organizational score is 1 or true, check status of client
if [ "$Audit6_1_3" = "1" ]; then
	defaults write /Library/Preferences/com.apple.loginwindow.plist GuestEnabled -bool false
	echo "$(date -u)" "6.1.3 remediated" | tee -a "$logFile"
fi

# 6.1.4 Disable "Allow guests to connect to shared folders"
# Verify organizational score
Audit6_1_4="$(defaults read "$plistlocation" OrgScore6_1_4)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit6_1_4" = "1" ]; then
echo "$(date -u)" "Checking 6.1.4" | tee -a "$logFile"
	afpGuestEnabled="$(defaults read /Library/Preferences/com.apple.AppleFileServer guestAccess)"
	smbGuestEnabled="$(defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess)"
	if [ "$afpGuestEnabled" = "1" ]; then
		defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool no
		echo "$(date -u)" "6.1.4 remediated" | tee -a "$logFile";
	fi
	if [ "$smbGuestEnabled" = "1" ]; then
		defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -bool no
		echo "$(date -u)" "6.1.4 remediated" | tee -a "$logFile";
	fi
fi

# 6.1.5 Remove Guest home folder
# Verify organizational score
Audit6_1_5="$(defaults read "$plistlocation" OrgScore6_1_5)"
# If organizational score is 1 or true, check status of client
if [ "$Audit6_1_5" = "1" ]; then
	rm -rf /Users/Guest
	echo "$(date -u)" "6.1.5 remediated" | tee -a "$logFile"
fi

# 6.2 Turn on filename extensions
# Verify organizational score
Audit6_2="$(defaults read "$plistlocation" OrgScore6_2)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit6_2" = "1" ]; then
	sudo -u "$currentUser" defaults write NSGlobalDomain AppleShowAllExtensions -bool true
	pkill -u "$currentUser" Finder
	echo "$(date -u)" "6.2 remediated" | tee -a "$logFile"
	# defaults write /Users/"$currentUser"/Library/Preferences/.GlobalPreferences.plist AppleShowAllExtensions -bool true
fi

# 6.3 Disable the automatic run of safe files in Safari
# Verify organizational score
Audit6_3="$(defaults read "$plistlocation" OrgScore6_3)"
# If organizational score is 1 or true, check status of client
# If client fails, then remediate
if [ "$Audit6_3" = "1" ]; then
	defaults write /Users/"$currentUser"/Library/Preferences/com.apple.Safari AutoOpenSafeDownloads -bool false
	echo "$(date -u)" "6.3 remediated" | tee -a "$logFile"
fi

echo "$(date -u)" "Remediation complete" | tee -a "$logFile"
echo "continue"
exit 0


#!/bin/sh
########################################################################
# Created By: ALEX DAVENPORT
# Creation Date: October, 2020
# Last modified: October 17th, 2020
# Brief Description: Changes machine hostname to "first + last + computer make"
########################################################################

# VARIABLES
FullHardwareListing=$(/usr/libexec/PlistBuddy -c "print :'CPU Names':$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}' | cut -c 9-)-en-US_US" ~/Library/Preferences/com.apple.SystemProfiler.plist)
LastUser=`defaults read /Library/Preferences/com.apple.loginwindow lastUserName`
Full_Name=$(dscl . read /Users/$LastUser RealName | grep -v RealName | cut -c 2-)
Plural_Full_Name="$Full_Name"\'s""
ComputerName="${Plural_Full_Name} ${FullHardwareListing}"
LocalHostName=$(echo $ComputerName | tr -dc '[:alnum:]\n\r' | sed 's/^\(.\{64\}\).*$/\1/')
ShortName=$(echo $ComputerName | sed 's/^\(.\{64\}\).*$/\1/')

# Script Computer Name
echo $ComputerName
scutil --set HostName "$ShortName"
scutil --set LocalHostName "$LocalHostName"
scutil --set ComputerName "$ShortName"
echo Rename Successful

#Update Inventory
jamf recon
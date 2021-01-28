#!/bin/sh
########################################################################
# Created By: ALEX DAVENPORT
# Creation Date: October, 2020
# Last modified: October 17th, 2020
# Brief Description: Changes machine hostname to "first + last + computer make"
########################################################################

# VARIABLES
FullHardwareListing=$(/usr/libexec/PlistBuddy -c "print :'CPU Names':$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}' | cut -c 9-)-en-US_US" ~/Library/Preferences/com.apple.SystemProfiler.plist)

JssUser=$4
JssPass=$5
JssHost=$6
Serial=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
Response=$(curl -k -s ${JssHost}/JSSResource/computers/serialnumber/${Serial}/subset/location --user ${JssUser}:${JssPass})
Real_name=$(echo $response | /usr/bin/awk -F'<realname>|</realname>' '{print $2}');

Plural_Full_Name="$Real_name"\'s""
ComputerName="${Plural_Full_Name} ${FullHardwareListing}"
LocalHostName=$(echo $ComputerName | tr -dc '[:alnum:]\n\r' | sed 's/^\(.\{64\}\).*$/\1/')
ShortName=$(echo $ComputerName | sed 's/^\(.\{64\}\).*$/\1/')

# Script Computer Name
echo $ComputerName
scutil --set HostName "$ShortName"
scutil --set LocalHostName "$LocalHostName"
scutil --set ComputerName "$ShortName"
cho Rename Successful

#Update Inventory
jamf recon
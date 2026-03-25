#!/bin/bash
########################################################################
# Created By: ALEX DAVENPORT
# Creation Date: October, 2020
# Last modified: March 25th, 2026
# Brief Description: Changes machine hostname to "first + last + computer model"
#                    using the last logged-in local user.
########################################################################

# --- Get hardware model name ---
ModelName=$(system_profiler SPHardwareDataType | awk -F': ' '/Model Name/ {print $2}')
if [ -z "$ModelName" ]; then
    echo "ERROR: Could not determine hardware model."
    exit 1
fi

# --- Get last logged-in user ---
LastUser=$(defaults read /Library/Preferences/com.apple.loginwindow lastUserName 2>/dev/null)
if [ -z "$LastUser" ]; then
    echo "ERROR: Could not determine last logged-in user."
    exit 1
fi

# --- Get user's real name from directory services ---
FullName=$(dscl . read "/Users/${LastUser}" RealName 2>/dev/null | grep -v RealName | sed 's/^ *//')
if [ -z "$FullName" ]; then
    echo "ERROR: Could not determine real name for user '${LastUser}'."
    exit 1
fi

# --- Build computer name ---
PluralFullName="${FullName}'s"
ComputerName="${PluralFullName} ${ModelName}"
LocalHostName=$(echo "$ComputerName" | tr -dc '[:alnum:]\n\r' | cut -c 1-64)
ShortName=$(echo "$ComputerName" | cut -c 1-64)

# --- Set computer name ---
echo "Setting computer name to: ${ComputerName}"
scutil --set HostName "$ShortName"
scutil --set LocalHostName "$LocalHostName"
scutil --set ComputerName "$ShortName"
echo "Rename successful."

# --- Update inventory ---
jamf recon

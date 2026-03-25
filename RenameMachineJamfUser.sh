#!/bin/bash
########################################################################
# Created By: ALEX DAVENPORT
# Creation Date: October, 2020
# Last modified: March 25th, 2026
# Brief Description: Changes machine hostname to "first + last + computer model"
#                    using the Jamf Pro API (OAuth2 client credentials).
########################################################################

# Jamf Pro script parameters
ClientID="$4"
ClientSecret="$5"
JssHost="$6"

# Strip any trailing slash from the URL
JssHost="${JssHost%/}"

# --- Validate inputs ---
if [ -z "$ClientID" ] || [ -z "$ClientSecret" ] || [ -z "$JssHost" ]; then
    echo "ERROR: Missing required parameters."
    echo "  \$4 = API Client ID"
    echo "  \$5 = API Client Secret"
    echo "  \$6 = Jamf Pro URL"
    exit 1
fi

# --- Get hardware model name ---
ModelName=$(system_profiler SPHardwareDataType | awk -F': ' '/Model Name/ {print $2}')
if [ -z "$ModelName" ]; then
    echo "ERROR: Could not determine hardware model."
    exit 1
fi

# --- Get serial number ---
Serial=$(system_profiler SPHardwareDataType | awk '/Serial Number/ {print $NF}')
if [ -z "$Serial" ]; then
    echo "ERROR: Could not determine serial number."
    exit 1
fi

# --- Obtain Bearer token via OAuth2 client credentials ---
TokenResponse=$(curl -s --fail-with-body \
    -X POST "${JssHost}/api/oauth/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=client_credentials&client_id=${ClientID}&client_secret=${ClientSecret}")

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to authenticate with Jamf Pro API."
    exit 1
fi

BearerToken=$(echo "$TokenResponse" | /usr/bin/python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)

if [ -z "$BearerToken" ]; then
    echo "ERROR: Could not extract access token from API response."
    exit 1
fi

# --- Look up assigned user via API ---
Response=$(curl -s --fail-with-body \
    -H "Authorization: Bearer ${BearerToken}" \
    -H "Accept: application/xml" \
    "${JssHost}/JSSResource/computers/serialnumber/${Serial}/subset/location")

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to look up computer in Jamf Pro."
    exit 1
fi

RealName=$(echo "$Response" | /usr/bin/awk -F'<real_name>|</real_name>' '{print $2}')
if [ -z "$RealName" ]; then
    echo "ERROR: Could not determine user's real name from Jamf Pro."
    exit 1
fi

# --- Build computer name ---
PluralFullName="${RealName}'s"
ComputerName="${PluralFullName} ${ModelName}"
LocalHostName=$(echo "$ComputerName" | tr -dc '[:alnum:]\n\r' | cut -c 1-64)
ShortName=$(echo "$ComputerName" | cut -c 1-64)

# --- Set computer name ---
echo "Setting computer name to: ${ComputerName}"
scutil --set HostName "$ShortName"
scutil --set LocalHostName "$LocalHostName"
scutil --set ComputerName "$ShortName"
echo "Rename successful."

# --- Invalidate the token ---
curl -s -o /dev/null \
    -X POST "${JssHost}/api/v1/auth/invalidate-token" \
    -H "Authorization: Bearer ${BearerToken}"

# --- Update inventory ---
jamf recon

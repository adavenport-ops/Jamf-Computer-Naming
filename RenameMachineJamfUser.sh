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
# Write credentials to a temporary file so they don't appear in process listings (ps).
TokenRequestBody=$(mktemp)
chmod 600 "$TokenRequestBody"
printf 'grant_type=client_credentials&client_id=%s&client_secret=%s' \
    "$ClientID" "$ClientSecret" > "$TokenRequestBody"

TokenResponse=$(curl -s --fail-with-body \
    -X POST "${JssHost}/api/oauth/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "@${TokenRequestBody}")
curl_exit=$?

rm -f "$TokenRequestBody"

if [ $curl_exit -ne 0 ]; then
    echo "ERROR: Failed to authenticate with Jamf Pro API."
    exit 1
fi

BearerToken=$(echo "$TokenResponse" | /usr/bin/python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)
unset TokenResponse

if [ -z "$BearerToken" ]; then
    echo "ERROR: Could not extract access token from API response."
    exit 1
fi

# --- Look up assigned user via API ---
# Use a config file for the Authorization header to keep the token off the command line.
CurlConfig=$(mktemp)
chmod 600 "$CurlConfig"
printf 'header = "Authorization: Bearer %s"\nheader = "Accept: application/xml"\n' \
    "$BearerToken" > "$CurlConfig"

Response=$(curl -s --fail-with-body \
    -K "$CurlConfig" \
    "${JssHost}/JSSResource/computers/serialnumber/${Serial}/subset/location")
curl_exit=$?

rm -f "$CurlConfig"

if [ $curl_exit -ne 0 ]; then
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
CurlConfig=$(mktemp)
chmod 600 "$CurlConfig"
printf 'header = "Authorization: Bearer %s"\n' "$BearerToken" > "$CurlConfig"
curl -s -o /dev/null -X POST "${JssHost}/api/v1/auth/invalidate-token" -K "$CurlConfig"
rm -f "$CurlConfig"

# --- Clear sensitive variables ---
unset ClientSecret BearerToken

# --- Update inventory ---
jamf recon

# Jamf Computer Naming

Scripts for Jamf Pro that rename macOS computers to **"User's Model Name"** (e.g. *Alex Davenport's MacBook Pro*).

## Scripts

### RenameMachineLocalUser.sh

Uses the **last logged-in local user** to determine the name. Best suited for environments without LDAP/SSO integration in Jamf.

No Jamf script parameters are required.

### RenameMachineJamfUser.sh

Looks up the **assigned user via the Jamf Pro API** (OAuth2 client credentials). Use this when your Jamf Pro instance has user–computer associations via LDAP, SSO, or manual assignment.

#### Jamf Script Parameters

| Parameter | Value |
|-----------|-------|
| `$4` | API Client ID |
| `$5` | API Client Secret |
| `$6` | Jamf Pro URL (e.g. `https://yourorg.jamfcloud.com`) |

#### Setting Up an API Client

1. In Jamf Pro, go to **Settings > System > API Roles and Clients**.
2. Create an **API Role** with the permission: **Read Computers**.
3. Create an **API Client**, assign it the role above, and note the **Client ID** and **Client Secret**.
4. Enter those values in the script's parameter fields in your Jamf Pro policy.

## Requirements

- macOS (uses `scutil`, `system_profiler`, `dscl`)
- Jamf Pro agent installed (`jamf recon` is called at the end of each script)
- Scripts must run as root (Jamf policies run as root by default)

# Jamf-Computer-Naming
Scripts used in Jamf computer naming based on username and model

The renamemachinelocaluser.sh uses last logged in user to the machine. I used this when there was no LDAP or SSO backend in Jamf that you link your computers with user accounts.   

The renamemachinejamfuser.sh script is aware of the users within JAMF and will do a lookup using the Jamf API and get the computer users First and Last name using that.

When you use the Jamf script you will need to set the variables in jamf for $4 to be a Read Only API Username, $5 to API user Password and $5 to be the Jamf cloud URL.

#USAGE: .\set-current-profile.ps1 [PROFILE-NAME]

param (
   [string]$profile
)

[Environment]::SetEnvironmentVariable("AWS_DEFAULT_PROFILE", "$profile")

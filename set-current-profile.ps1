param (
   [string]$profile
)

[Environment]::SetEnvironmentVariable("AWS_DEFAULT_PROFILE", "$profile")

param (
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$Email
)

# Validate the email address
try {
    $null = [mailaddress] $Email
}
catch {
    throw "Please provide a valid email address"
}

# Validate Name
if ($Name.replace(" ", "") -notmatch "^[a-zA-Z0-9]*$") {
    throw "Please provide a name using only characters in the Latin alphabet and 0 to 9"
}

# Set up the request body
$body = @{
    email = $Email
    name  = $Name
}

# Set up the request headers
$headers = @{
    "Content-Type" = "application/json"
}

$splat = @{
    Method  = "POST"
    Uri     = "https://prod-198.westeurope.logic.azure.com:443/workflows/21e84d67b06f46ae90e09c0530bd698f/triggers/When_a_HTTP_request_is_received/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=lLz2Z9QPuXyA2k31bnydyCHiIB3OXe-cDkioX6Az9JU"
    Body    = ($body | ConvertTo-Json)
    Headers = $headers
}

$request = Invoke-RestMethod @splat

Write-Output "Your environment is being set up."
Write-Output "Please go to https://portal.azure.com and log in with the following credentials:"
Write-Output "Username = $($request.UPN)"
Write-Output "Password = $($request.Password)"
Write-Output ""
Write-Output "You will be asked to change the password on first login and you will be asked to provide some additional information. After this session your account and all data associated to it will be deleted."
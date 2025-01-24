# Boost your Azure Functions with API Management

In this document you will find the exercises for the workshop.

## Exercise 1 - Getting an environment (15 min)

Clone this repository locally and run the Get-Environment.ps1 file with the parameters Name and Email.
`.\Get-Environment.ps1 -Name <YourName> -Email <YourEmail>`

Make sure you only use latin alphabet letters and numbers for the name. This name can be anything, it's only used to create a unique resourcegroup. The email is needed but you can enter a fake email address like test@test.nl .

You will be provided with a username and password. It's possible the automation failed, if so please ask for help. Use this to login to the azure portal (portal.azure.com), you will be asked to set up MFA via sms and change your password. After that is set up check your resource group. Check the deployments in that resourcegroup if they where all successful.

## Exercise 2 - Creating an Azure function (10 min)

Create a **http trigger** function in the Function App and put the authentication level on **Anonymous**.
Replace the code of the function with the following code:

```Powershell

using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Get the name from the Query
$name = $Request.Query.Name ?? "World"

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = "Hello $name!"
})
```

Make sure the trigger is set to only accept GET requests

Test if you can call the function (hint: check the "Get function URL" option) with a tool like PowerShell or Postman.

Test if you can add a query parameter to the url called "Name" and give this a value, check if your output changes.

---

### STOP - Explanation

---

## Exercise 3 - Connect the function to API Management (15 min)

In the azure function look for the API Management blade and link your API. Keep the API suffix empty.

In the settings for the created API look for the checkbox "Subscription required" and make sure it's not selected.

Test if your API Management is working, first use the test tab for the operation to see if you get a result.

Now change the name of the operation to "Hello" and test if it's still working. This will give a 404 error as API management will try to go to the "Hello" function in our app. Change the created backend in API management with the Runtime URL like:
`https://<yourfunctionname>.azurewebsites.net/api//HttpTrigger1`

You now need to make sure the "Hello" part is stripped from the url before it goes to the back-end. Add an API Management policy to do this. You can check answer 1 in the ANSWERS.md file to see how to do this.

Test that your API is working without a query parameter and with one (called Name).

## Exercise 4 - Adding Policy Fragments (10 min)

Create a policy fragment which holds the policies to call the function. Name it "call-function". Replace the existing policy in Hello with the policy fragement. You can check answer 2 if you are stuck.

Test again if your API still works with and without a query parameters.

---

### STOP - Explanation

---

## Exercise 5 - Our own API key (30 min)

Open the keyvault in your environment and make sure you have the permission **Key Vault Secrets Officer**. Make sure the API Management managed identity has the permission **Key Vault Secrets User**.

Create a secret named "Everyone" and give it the value "12345"

Now create a new operation in your API Management called "Hello-Restricted".
Now create a policy which queries your keyvault for a secret named after the value in the Query parameter name (hint: you want to look into "send-request"). The secret value should be send as a header named "Key" to the API management.

If the value doesn't exists in the keyvault or the keys don't match make sure a 401 is returned. Else return the output (hint: you want to use a `<choose>` here). If you want to know what is happening in API management you can use the trace button in the test tab to see what's happening internally.

Make sure that the policy to check the keyvault is again put in a policy fragment. Call this policy fragment "check-keyvault". Keep in mind that nested policy fragments are not supported.

Test if it works. If you want to use PowerShell you can add the header like this:

```PowerShell
Invoke-RestMethod -Uri "https://<NAME OF YOUR APIM>.azure-api.net/Hello-Restricted?Name=Everyone" -Headers @{Key=12345}
```

Feel free to add more secrets and see if they work too.

You can check answer 3 if you get stuck.

## Exercise 6 - Using Named values (10 min)

Create two named values:

* FunctionName
* KeyVaultName

Give them the values of your function and keyvault and make sure that in the policy fragment the names for the function and keyvault are replaced by these values. You can use the syntax `{{Named Value Name}}` to add named values to policies.

You can check answer 4 for more info.

---

### STOP - Explanation

---

## Exercise 7 - Adding Entra ID (20 min)

Create a new operation in API Management called "Hello-Auth".
You can go to Entra ID in the azure portal and check out the App Registrations. There should be one app where you are the owner off (name starts with APIMWORKSHOPAPP). Create a secret for this app and make sure you safe this somewhere.

If you want to login via this app in PowerShell you can use a command like this.

```PowerShell
$ApplicationId = Read-Host -Prompt 'Enter a the Application ID'
$SecurePassword = Read-Host -Prompt 'Enter a the Client Secret Value' -AsSecureString
$TenantId = '289178cb-1f7c-4171-b559-4885bd001c74'
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $SecurePassword
Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential
$Token = (Get-AzAccessToken).Token
$Token
```

This will provide you with a token. You can use sites like https://www.jwt.io to analyze a token like this (don't use this for production environment due to security risks).

In the token you will find the value appid and iss. Create a policy to check that these are corresponding with the values you see. So the issues will be "https://sts.windows.net/289178cb-1f7c-4171-b559-4885bd001c74/" and the appid will be your appid (hint: you want to look into validate-jwt). if it fails it should return a 401. The token needs to be send as a authorization header. If you are using PowerShell you can do that like this (assuming your are still in the same window):

```PowerShell
Invoke-RestMethod -Uri "https://powerupapimapimlevis.azure-api.net/Hello-Auth?" -Headers @{Authorization = "Bearer $Token"}
```

You can check answer 5 for more help.

---

### STOP - Explanation

---

## Exercise 8 - Setting up Roles (10 min)

In the app registration you can create app roles. Create the app role (Name and Value are the same in this case):

* Admin
* User

You can click the link to go to the assignment enterprise application which you also have permissions for. Here you can assign yourself to one of the two roles.

Make sure you create a redirect url for a single web page in the app registation and add the following url:
`https://powerupapimlogin.azurewebsites.net/`

Now go to https://powerupapimlogin.azurewebsites.net/ and enter your application ID in the first field, then press the login link. This will log you into the app and shows which roles are assigned to you and it shows your token. You can again analyze this token to see where this information is stored in the token. If you are interested in how the app works you can check the App folder in this repository to check the code for it.

## Exercise 9 - Conditional logic per role (20 min)

Create a new operation in API Management again and call it "Hello-Role". For this one we want to do a validation of the token again. So check if the follow attributes are set correctly:

* audiences = Application ID from your app
* issuer = `https://login.microsoftonline.com/289178cb-1f7c-4171-b559-4885bd001c74/v2.0`

You then want to get the roles from the token (hint: they are under claims in the object).
And if the Role is Admin it should send the query `Name=Admin` to the function. If the Role is user it should send `Name=You`. In other cases it shouldn't go to the function.

Create the policy for this (hint: you will need to use a `<choose>` again). Test it by passing along the token. The easiest way to test is by using the build in test tab and copying the token to the Authorization header. Make sure you put "Bearer " (the space is intentional) in front of it.

Test if it works with the role you have and assign yourself a different role and check if it works this way too.

You can check answer 6 for more help.

---

### END

---

## Bonus - In case you are very quick

The code can be tidied up more. Thing to consider:

* Creating a named value for the app id and issuer and/or tenant id
* In the last exercise when no Role is set you can add a proper error
* Store which response has to be send for which role in he keyvault and retrieve the proper response here.

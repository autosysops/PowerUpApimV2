## Answer 1

Your Policy should look like this:

```XML
<policies>
    <inbound>
        <base />
        <rewrite-uri template="/" />
        <set-backend-service id="apim-generated-policy" backend-id="<NAME OF YOUR FUNCTIONAPP>" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

## Answer 2

The policy fragment should be like this:

```XML
<fragment>
	<rewrite-uri template="/" />
	<set-backend-service id="apim-generated-policy" backend-id="powerupapimfalevis" />
</fragment>
```

The policy for Hello should look like this

```XML
<policies>
    <inbound>
        <base />
        <include-fragment fragment-id="call-function" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

## Answer 3

The policy fragment check-keyvault should look like:

```XML
<fragment>
	<send-request mode="new" response-variable-name="responseObj" timeout="30" ignore-error="true">
		<set-url>@($"https://<NAME OF YOUR KEYVAULT>.vault.azure.net/secrets/{context.Request.Url.Query.GetValueOrDefault("Name","World")}?api-version=7.4")</set-url>
		<set-method>GET</set-method>
		<authentication-managed-identity resource="https://vault.azure.net" />
	</send-request>
	<choose>
		<when condition="@(!((IResponse)context.Variables["responseObj"]).Body.As<JObject>(preserveContent: true).ContainsKey("value"))">
			<return-response>
				<set-status code="401" reason="Unauthorized" />
			</return-response>
		</when>
		<when condition="@(!((string)((IResponse)context.Variables["responseObj"]).Body.As<JObject>(preserveContent: true)["value"]).Equals((string)context.Request.Headers.GetValueOrDefault("Key","")))">
			<return-response>
				<set-status code="401" reason="Unauthorized" />
			</return-response>
		</when>
	</choose>
</fragment>
```

The policy for Hell-Restricted should look like:

```XML
<policies>
    <inbound>
        <base />
        <include-fragment fragment-id="check-keyvault" />
        <include-fragment fragment-id="call-function" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

## Answer 4

The policy fragment call-function should look like this:

```XML
<fragment>
	<rewrite-uri template="/" />
	<set-backend-service id="apim-generated-policy" backend-id="{{FunctionName}}" />
</fragment>
```

The policy fragment check-keyvault should look like this:

```XML
<fragment>
	<send-request mode="new" response-variable-name="responseObj" timeout="30" ignore-error="true">
		<set-url>@($"https://{{KeyVaultName}}.vault.azure.net/secrets/{context.Request.Url.Query.GetValueOrDefault("Name","World")}?api-version=7.4")</set-url>
		<set-method>GET</set-method>
		<authentication-managed-identity resource="https://vault.azure.net" />
	</send-request>
	<choose>
		<when condition="@(!((IResponse)context.Variables["responseObj"]).Body.As<JObject>(preserveContent: true).ContainsKey("value"))">
			<return-response>
				<set-status code="401" reason="Unauthorized" />
			</return-response>
		</when>
		<when condition="@(!((string)((IResponse)context.Variables["responseObj"]).Body.As<JObject>(preserveContent: true)["value"]).Equals((string)context.Request.Headers.GetValueOrDefault("Key","")))">
			<return-response>
				<set-status code="401" reason="Unauthorized" />
			</return-response>
		</when>
	</choose>
</fragment>
```

## Answer 5

The policy for Hello-Auth should look like this:

```XML
<policies>
    <inbound>
        <base />
        <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized" require-expiration-time="true" require-scheme="Bearer" require-signed-tokens="true">
            <openid-config url="https://login.microsoftonline.com/contoso.onmicrosoft.com/.well-known/openid-configuration" />
            <issuers>
                <issuer>https://sts.windows.net/289178cb-1f7c-4171-b559-4885bd001c74/</issuer>
            </issuers>
            <required-claims>
                <claim name="appid" match="all">
                    <value>acaddd75-7106-4b42-b572-7a138f4df8e6</value>
                </claim>
            </required-claims>
        </validate-jwt>
        <include-fragment fragment-id="call-function" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

## Answer 6

The policy for Hello-Role should look like this:

```XML
<policies>
    <inbound>
        <base />
        <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized" require-expiration-time="true" require-scheme="Bearer" require-signed-tokens="true" output-token-variable-name="jwt">
            <openid-config url="https://login.microsoftonline.com/contoso.onmicrosoft.com/.well-known/openid-configuration" />
            <audiences>
                <audience>acaddd75-7106-4b42-b572-7a138f4df8e6</audience>
            </audiences>
            <issuers>
                <issuer>https://login.microsoftonline.com/289178cb-1f7c-4171-b559-4885bd001c74/v2.0</issuer>
            </issuers>
        </validate-jwt>
        <choose>
            <when condition="@(((Jwt)context.Variables["jwt"]).Claims.GetValueOrDefault("roles").Contains("Admin"))">
                <set-query-parameter name="Name" exists-action="override">
                    <value>Admin</value>
                </set-query-parameter>
                <include-fragment fragment-id="call-function" />
            </when>
            <when condition="@(((Jwt)context.Variables["jwt"]).Claims.GetValueOrDefault("roles").Contains("User"))">
                <set-query-parameter name="Name" exists-action="override">
                    <value>You</value>
                </set-query-parameter>
                <include-fragment fragment-id="call-function" />
            </when>
        </choose>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

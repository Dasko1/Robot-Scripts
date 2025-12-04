
*** Settings ***
Library    RequestsLibrary
Library    Collections
Resource   resource.robot

*** Test Cases ***
OAuth2 Google Flow With Beeceptor Mock
    [Documentation]    End-to-end API-level test using Beeceptor's OAuth 2.0 Mock Server.
    ...                1) Exchange an auth code for a Google access token
    ...                2) Call the Google userinfo endpoint with the Bearer token
    ...                3) Validate the mock profile data

    # Step 1 - Create HTTP session against Beeceptor OAuth mock server.
    Create Session    oauth    ${BASE_URL}

    # Exchange authorization code for an access token.
    &{token_body} =      Create Dictionary
    ...                  grant_type=authorization_code
    ...                  code=dummy-auth-code
    ...                  redirect_uri=${REDIRECT_URI}
    ...                  client_id=${CLIENT_ID}
    ...                  client_secret=${CLIENT_SECRET}

    &{token_headers} =   Create Dictionary
    ...                  Content-Type=application/x-www-form-urlencoded

    ${token_resp} =      POST On Session
    ...                  oauth
    ...                  /oauth/token/google
    ...                  data=${token_body}
    ...                  headers=${token_headers}

    Should Be Equal As Integers    ${token_resp.status_code}    200

    # Extract access_token from JSON response.
    ${access_token} =     Evaluate    $token_resp.json().get("access_token")
    Should Not Be Empty  ${access_token}

    Log To Console       \nAccess token from Beeceptor: ${access_token}

    # Step 2 – Call userinfo endpoint with Bearer token.
    &{userinfo_headers} =   Create Dictionary
    ...                     Authorization=Bearer ${access_token}

    ${userinfo_resp} =      GET On Session
    ...                     oauth
    ...                     /userinfo/google
    ...                     headers=${userinfo_headers}

    Should Be Equal As Integers    ${userinfo_resp.status_code}    200

    # Step 3 – Validate mock user profile payload.
    ${profile} =          Evaluate    $userinfo_resp.json()

    ${sub} =              Evaluate    $profile.get("sub")
    ${email} =            Evaluate    $profile.get("email")
    ${name} =             Evaluate    $profile.get("name")
    ${picture} =          Evaluate    $profile.get("picture")

    Should Not Be Empty          ${sub}
    Should Be Equal As Strings   ${email}      oauth-sample-google@beeceptor.com
    Should Be Equal As Strings   ${name}       Bee User
    Should Contain               ${picture}    beeceptor.com

    Log To Console    \nUser profile from Beeceptor mock:\n${profile}

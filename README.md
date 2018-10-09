# OpenIDDemo
My Genero Demo for authenticating using Google

The Programs:
* OpenIdDemo - a program run via delegation to show the information returned from Google
* OpenIdLogin - an example of a program that just sets information in userStorage on the client
* test_OpenIdLogin - a test program to test the OpenIdLogin program

The Service:
* njmOpenIDConnect - Based on the default Genero example OpenIDConnectProvide


# Adding a provider to the database:

export FGLPROFILE=../res/fglprofile

cd OpenIdConnect_bin

fglrun ImportOAuth.42r -list

fglrun ImportOAuth -import https://test-api.service.hmrc.gov.uk -authz https://test-api.service.hmrc.gov.uk/oauth/authorize -token https://test-api.service.hmrc.gov.uk/oauth/token

fglrun ImportOAuth.42r -list


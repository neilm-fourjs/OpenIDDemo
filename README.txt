
export FGLPROFILE=../res/fglprofile

cd openId_bin

fglrun ImportOAuth.42r -list

fglrun ImportOAuth -import https://test-api.service.hmrc.gov.uk -authz https://test-api.service.hmrc.gov.uk/oauth/authorize -token https://test-api.service.hmrc.gov.uk/oauth/token

fglrun ImportOAuth.42r -list

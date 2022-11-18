#+
#+ Generated from loginws
#+
IMPORT com
IMPORT xml
IMPORT util
IMPORT os

#+
#+ Global Endpoint user-defined type definition
#+
TYPE tGlobalEndpointType RECORD # Rest Endpoint
  Address RECORD # Address
    Uri STRING # URI
  END RECORD,
  Binding RECORD # Binding
    Version STRING, # HTTP Version (1.0 or 1.1)
    ConnectionTimeout INTEGER, # Connection timeout
    ReadWriteTimeout INTEGER, # Read write timeout
    CompressRequest STRING # Compression (gzip or deflate)
  END RECORD
END RECORD

PUBLIC DEFINE Endpoint tGlobalEndpointType
    = (Address:(Uri: "https://generodemos.dynu.net/g/ws/r/oidws/OpenIdLoginWS"))

# Error codes
PUBLIC CONSTANT C_SUCCESS = 0

# generated getUserResponseBodyType
PUBLIC TYPE getUserResponseBodyType RECORD
  scope STRING,
  email STRING,
  family STRING,
  given STRING,
  idp_issuer STRING,
  idp_token_endpoint STRING,
  name STRING,
  picture STRING,
  profile STRING,
  sub STRING,
  token_expires_in INTEGER,
  userinfo_endpoint STRING,
  invocation_id STRING
END RECORD

################################################################################
# Operation /getUser/{l_scope}
#
# VERB: GET
# DESCRIPTION: Get User
#
PUBLIC FUNCTION getUser(p_l_scope STRING)
    RETURNS(INTEGER, getUserResponseBodyType)
  DEFINE fullpath base.StringBuffer
  DEFINE contentType STRING
  DEFINE req com.HTTPRequest
  DEFINE resp com.HTTPResponse
  DEFINE resp_body getUserResponseBodyType
  DEFINE json_body STRING

  TRY

    # Prepare request path
    LET fullpath = base.StringBuffer.Create()
    CALL fullpath.append("/getUser/{l_scope}")
    CALL fullpath.replace("{l_scope}", p_l_scope, 1)

    # Create request and configure it
    LET req =
        com.HTTPRequest.Create(
            SFMT("%1%2", Endpoint.Address.Uri, fullpath.toString()))
    IF Endpoint.Binding.Version IS NOT NULL THEN
      CALL req.setVersion(Endpoint.Binding.Version)
    END IF
    IF Endpoint.Binding.ConnectionTimeout <> 0 THEN
      CALL req.setConnectionTimeout(Endpoint.Binding.ConnectionTimeout)
    END IF
    IF Endpoint.Binding.ReadWriteTimeout <> 0 THEN
      CALL req.setTimeout(Endpoint.Binding.ReadWriteTimeout)
    END IF
    IF Endpoint.Binding.CompressRequest IS NOT NULL THEN
      CALL req.setHeader("Content-Encoding", Endpoint.Binding.CompressRequest)
    END IF

    # Perform request
    CALL req.setMethod("GET")
    CALL req.setHeader("Accept", "application/json")
    CALL req.DoRequest()

    # Retrieve response
    LET resp = req.getResponse()
    # Process response
    INITIALIZE resp_body TO NULL
    LET contentType = resp.getHeader("Content-Type")
    CASE resp.getStatusCode()

      WHEN 200 #Success
        IF contentType MATCHES "*application/json*" THEN
          # Parse JSON response
          LET json_body = resp.getTextResponse()
          CALL util.JSON.parse(json_body, resp_body)
          RETURN C_SUCCESS, resp_body.*
        END IF
        RETURN -1, resp_body.*

      OTHERWISE
        RETURN resp.getStatusCode(), resp_body.*
    END CASE
  CATCH
    RETURN -1, resp_body.*
  END TRY
END FUNCTION
################################################################################

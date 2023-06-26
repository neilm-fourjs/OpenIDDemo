#
# FOURJS_START_COPYRIGHT(U,2015)
# Property of Four Js*
# (c) Copyright Four Js 2015, 2023. All Rights Reserved.
# * Trademark of Four Js Development Tools Europe Ltd
#   in the United States and elsewhere
# 
# Four Js and its suppliers do not warrant or guarantee that these samples
# are accurate and suitable for your purposes. Their inclusion is purely for
# information purposes only.
# FOURJS_END_COPYRIGHT
#

IMPORT security
IMPORT FGL Logs

PRIVATE 
CONSTANT C_ACCESS_VALIDITY = INTERVAL (30) SECOND TO SECOND # Access token validity in seconds

#
# Attributes to be passed to application as environment variables
#
PUBLIC TYPE AttributeType  DYNAMIC ARRAY OF RECORD
                                  name    VARCHAR(255),
                                  value   STRING
                                  END RECORD


PRIVATE TYPE URLType VARCHAR(2048)
#
# Access token definition type
#
PRIVATE TYPE TokenType  RECORD
    uuid        VARCHAR(36),
    path        URLType,
    remote_ip   VARCHAR(255),
    expires     DATETIME YEAR TO SECOND
END RECORD
    
#
# Creates an access token on disk for given id
#  and returns it's name
#    
PUBLIC 
FUNCTION CreateToken(path,attrs,ip)
  DEFINE  path            STRING
  DEFINE  ip              STRING
  DEFINE  attrs           AttributeType
  DEFINE  token           TokenType
  DEFINE  ind             INTEGER
  
  CALL Logs.LOG_EVENT(Logs.C_LOG_DEBUG,"Access","CreateToken",null)
  
  TRY
    LET token.uuid = security.RandomGenerator.CreateUUIDString()
    LET token.path = path
    LET token.remote_ip = ip
    LET token.expires = CURRENT + C_ACCESS_VALIDITY
    INSERT INTO fjs_oidc_access VALUES (token.uuid, token.path, token.remote_ip, token.expires)
    FOR ind=1 TO attrs.getLength()
      INSERT INTO fjs_oidc_access_attr VALUES (token.uuid, attrs[ind].name, attrs[ind].value)
    END FOR
  CATCH
    INITIALIZE token TO NULL # ERROR
    CALL Logs.LOG_EVENT(Logs.C_LOG_SQLERROR,"Access","CreateToken","sqlcode="||sqlca.sqlcode)
  END TRY
  RETURN token.uuid
END FUNCTION

#
# Validates an access token on disk of given name
#  and removes it from disk
# @Return: the uuid and an array of attributes
#
PUBLIC 
FUNCTION ValidateToken(p_uuid,p_path,p_ip, bootstrap_step)
  DEFINE    p_uuid          VARCHAR(36)
  DEFINE    p_path          STRING
  DEFINE    p_ip            STRING
  DEFINE    bootstrap_step  STRING
  DEFINE    token           TokenType  
  DEFINE    attrs           AttributeType
  DEFINE    ind             INTEGER
  DEFINE    rec             RECORD 
        NAME VARCHAR(255),
        value TEXT
  END RECORD
  DEFINE    _found          BOOLEAN 
  DEFINE    _valid          BOOLEAN

  DEFINE    remoteip_mode   STRING
  DEFINE    check_remoteip  BOOLEAN
  
  CALL Logs.LOG_EVENT(Logs.C_LOG_DEBUG, "Access", "ValidateAccessToken",p_uuid)
  
  IF p_uuid IS NULL THEN
    RETURN FALSE, FALSE, NULL
  END IF
  
  LOCATE rec.value IN MEMORY

  WHENEVER ERROR CONTINUE
  
  SELECT uuid, path, remote_ip, expires 
    INTO token.uuid, token.path, token.remote_ip, token.expires
    FROM fjs_oidc_access WHERE uuid = p_uuid
    
  CASE sqlca.sqlcode
  
    WHEN NOTFOUND
      # Cookie not found
      LET _found = FALSE
      LET _valid = FALSE
      CALL Logs.LOG_EVENT(Logs.C_LOG_DEBUG, "Access", "ValidateAccessToken",p_uuid||" not found")
      
    WHEN 0
      LET _found = TRUE
      LET _valid = FALSE
      LET remoteip_mode =  base.Application.getResourceEntry("oidc.client.check")
      # Check remote_ip (if configured)
      IF remoteip_mode IS NULL THEN
        LET check_remoteip = TRUE
        CALL Logs.LOG_EVENT(Logs.C_LOG_DEBUG, "Access", "ValidateToken", p_uuid||" no oidc.client.check set")
      ELSE
        CASE remoteip_mode
          WHEN "Remote-Addr"
            IF token.remote_ip!=p_ip THEN
              # Token invalid
              CALL Logs.LOG_EVENT(Logs.C_LOG_ERROR, "Access", "ValidateToken", p_uuid||"  bad Remote-Addr")
            ELSE
              LET check_remoteip = TRUE
              CALL Logs.LOG_EVENT(Logs.C_LOG_DEBUG, "Access", "ValidateToken", p_uuid||" oidc.client.check='Remote-Addr' set")
            END IF
          WHEN "X-Forwarded-For"
            IF token.remote_ip!=p_ip THEN
              # Token invalid
              CALL Logs.LOG_EVENT(Logs.C_LOG_ERROR, "Access", "ValidateToken", p_uuid||" bad X-Forwarded-For")
            ELSE
              LET check_remoteip = TRUE
              CALL Logs.LOG_EVENT(Logs.C_LOG_DEBUG, "Access", "ValidateToken", p_uuid||" oidc.client.check='X-Forwarded-For' set")
            END IF
          OTHERWISE
            # Token invalid
            CALL Logs.LOG_EVENT(Logs.C_LOG_ERROR, "Access", "ValidateToken", p_uuid||" is invalid, unexpected remoteip mode")
        END CASE
      END IF
      
      # Check validity
      IF token.path == p_path AND check_remoteip THEN
        # Check expiration
        IF token.expires >= CURRENT THEN
          IF bootstrap_step IS NULL THEN
            # RETRIEVE ATTRIBUTES ASSOCIATED TO TOKEN
            DECLARE cur CURSOR FOR
             SELECT name, value
               FROM fjs_oidc_access_attr
               WHERE access_uuid = p_uuid
            LET ind = 1
            FOREACH cur INTO rec.*
              LET attrs[ind].name = rec.NAME
              LET attrs[ind].value = rec.value
              LET ind=ind+1
            END FOREACH
            # Remove one usage token
            DELETE FROM fjs_oidc_access WHERE uuid == p_uuid  
            DELETE FROM fjs_oidc_access_attr WHERE access_uuid == p_uuid
           ELSE
            # DO NOT RETRIEVE ATTRIBUTES, WILL BE DONE IF THERE IS NO BOOTSTRAP STEP
            CALL Logs.LOG_EVENT(Logs.C_LOG_MSG, "Access", "ValidateToken",p_uuid||" requires another step")          
          END IF
          LET _valid = TRUE
          
        ELSE
        
          # Token expired
          CALL Logs.LOG_EVENT(Logs.C_LOG_ERROR, "Access", "ValidateToken",p_uuid||" has expired")
          DELETE FROM fjs_oidc_access WHERE uuid == p_uuid  
          DELETE FROM fjs_oidc_access_attr WHERE access_uuid == p_uuid        
        END IF
      ELSE
      
        # Token invalid
        CALL Logs.LOG_EVENT(Logs.C_LOG_ERROR, "Access", "ValidateToken", p_uuid||" is invalid")
        DELETE FROM fjs_oidc_access WHERE uuid == p_uuid  
        DELETE FROM fjs_oidc_access_attr WHERE access_uuid == p_uuid                
      END IF
      
    OTHERWISE
      # SQL ERROR
      LET _found = FALSE
      LET _valid = FALSE      
      CALL Logs.LOG_EVENT(Logs.C_LOG_SQLERROR, "Access", "ValidateToken", sqlca.sqlcode)
      DELETE FROM fjs_oidc_access WHERE uuid == p_uuid  
      DELETE FROM fjs_oidc_access_attr WHERE access_uuid == p_uuid
      
  END CASE  
  WHENEVER ERROR STOP
  
  FREE rec.value

  RETURN _found, _valid, attrs
END FUNCTION

#
# Cleans all expired tokens
#
PUBLIC 
FUNCTION CleanupToken()
  DEFINE id VARCHAR(36)
  DEFINE now  DATETIME YEAR TO SECOND

  LET now = CURRENT
  
  DECLARE cup CURSOR FOR SELECT uuid FROM fjs_oidc_access WHERE expires<now
  FOREACH cup INTO id
    DELETE FROM fjs_oidc_access WHERE uuid == id
    DELETE FROM fjs_oidc_access_attr WHERE access_uuid == id
  END FOREACH
  FREE cup
  
  CALL Logs.LOG_EVENT(Logs.C_LOG_MSG,"Access","CleanupAccessToken","cleanup")

END FUNCTION



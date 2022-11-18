
TYPE userRecord RECORD
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

--------------------------------------------------------------------------------
#+ GET <server>/OpenIdLoginWS/getToken/scope
#+ result: A Record that contains uesr information
PUBLIC FUNCTION getUser(l_scope STRING ATTRIBUTE(WSParam)) ATTRIBUTES( 
                WSPath = "/getUser/{l_scope}", 
                WSGet,
                WSDescription = "Get User")
        RETURNS (userRecord ATTRIBUTES(WSMedia = 'application/json'))
	DEFINE l_user userRecord
	LET l_user.scope = l_scope
	LET l_user.email = fgl_getEnv("OIDC_EMAIL")
	LET l_user.family = fgl_getEnv("OIDC_FAMILY_NAME")
	LET l_user.given  = fgl_getEnv("OIDC_GIVEN_NAME")
	LET l_user.idp_issuer  = fgl_getEnv("OIDC_IDP_ISSUER")
	LET l_user.idp_token_endpoint  = fgl_getEnv("OIDC_IDP_TOKEN_ENDPOINT")
	LET l_user.name  = fgl_getEnv("OIDC_NAME")
	LET l_user.picture  = fgl_getEnv("OIDC_PICTURE")
	LET l_user.profile  = fgl_getEnv("OIDC_PROFILE")
	LET l_user.sub  = fgl_getEnv("OIDC_SUB")
	LET l_user.token_expires_in  = fgl_getEnv("OIDC_TOKEN_EXPIRES_IN")
	LET l_user.invocation_id = fgl_getEnv("INVOCATION_ID")
	CALL dumpEnv()
	RETURN l_user.*
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION dumpEnv()
	DEFINE c base.channel
	DEFINE l_line STRING
	LET c = base.Channel.create()

	DISPLAY "----------Environment---------"
	CALL c.openPipe("env | sort", "r")
	WHILE NOT c.isEof()
		LET l_line = c.readLine()
		IF l_line.getLength() > 1 THEN
			DISPLAY "Env: "||l_line
		END IF
	END WHILE
	CALL c.close()

END FUNCTION
--------------------------------------------------------------------------------
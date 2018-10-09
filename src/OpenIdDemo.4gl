
-- Client ID: 533588121618-c00p53sjm6vbse9l6eqhgs5hdpgqoktv.apps.googleusercontent.com
-- Client Secret: 7lT-uKZ5-PQiTQMagGlZyD5V

TYPE t_oidc RECORD
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
		userinfo_endpoint STRING
	END RECORD
DEFINE m_txt STRING
MAIN
	DEFINE l_oidc t_oidc

	OPEN FORM frm FROM "OpenIdDemo"
	DISPLAY FORM frm

	CALL dumpEnv()
	LET l_oidc.email = fgl_getEnv("OIDC_EMAIL")
	LET l_oidc.family = fgl_getEnv("OIDC_FAMILY_NAME")
	LET l_oidc.given  = fgl_getEnv("OIDC_GIVEN_NAME")
	LET l_oidc.idp_issuer  = fgl_getEnv("OIDC_IDP_ISSUER")
	LET l_oidc.idp_token_endpoint  = fgl_getEnv("OIDC_IDP_TOKEN_ENDPOINT")
	LET l_oidc.name  = fgl_getEnv("OIDC_NAME")
	LET l_oidc.picture  = fgl_getEnv("OIDC_PICTURE")
	LET l_oidc.profile  = fgl_getEnv("OIDC_PROFILE")
	LET l_oidc.sub  = fgl_getEnv("OIDC_SUB")
	LET l_oidc.token_expires_in  = fgl_getEnv("OIDC_TOKEN_EXPIRES_IN")
	LET l_oidc.userinfo_endpoint  = fgl_getEnv("OIDC_USERINFO_ENDPOINT")

	DISPLAY BY NAME l_oidc.* 

	CALL disp( "Finished." )
	MENU "Finished"
		ON ACTION close EXIT MENU
		ON ACTION exit EXIT MENU
	END MENU

END MAIN
--------------------------------------------------------------------------------
FUNCTION disp(l_txt STRING)
	LET m_txt = m_txt.append( CURRENT||":"||l_txt||"\n" )
	DISPLAY CURRENT||":"||l_txt
	DISPLAY BY NAME m_txt
	CALL ui.Interface.refresh() 
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION dumpEnv()
	DEFINE c base.channel
	DEFINE l_line STRING
	LET c = base.Channel.create()
	CALL disp("----------Environment---------")
	CALL c.openPipe("env | sort", "r")
	WHILE NOT c.isEof()
		LET l_line = c.readLine()
		IF l_line.getLength() > 1 THEN
			CALL disp("Env: "||l_line)
		END IF
	END WHILE
	CALL c.close()
	CALL disp("------------------------------")
END FUNCTION
--------------------------------------------------------------------------------
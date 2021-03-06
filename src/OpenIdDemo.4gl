
IMPORT util
IMPORT security
IMPORT os
IMPORT FGL rest_sec

CONSTANT C_IDP_URL = "https://accounts.google.com"
CONSTANT C_IDP_ENDPOINT = "https://accounts.google.com/o/oauth2/v2/auth"

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
DEFINE m_secretId, m_clientId, m_endPoint STRING
DEFINE m_oidc t_oidc
MAIN

	OPEN FORM frm FROM "OpenIdDemo"
	DISPLAY FORM frm

	CALL getAPIkeys("../etc/apikeys.json") RETURNING m_clientId, m_secretId, m_endPoint
	IF m_clientId IS NULL OR m_secretId IS NULL OR m_endPoint IS NULL THEN
		CALL fgl_winMessage("Error",m_txt,"exclamation")
		EXIT PROGRAM
	END IF

--	CALL dumpEnv()
--	CALL setOidcFromEnv()

	DISPLAY BY NAME m_oidc.* 

	CALL disp( "Finished." )
	MENU "Finished"
		ON ACTION getToken CALL getToken()
		ON ACTION showHTML CALL show_html2()
		ON ACTION close EXIT MENU
		ON ACTION exit EXIT MENU
	END MENU

END MAIN
--------------------------------------------------------------------------------
FUNCTION setOidcFromEnv()
	LET m_oidc.email = fgl_getEnv("OIDC_EMAIL")
	LET m_oidc.family = fgl_getEnv("OIDC_FAMILY_NAME")
	LET m_oidc.given  = fgl_getEnv("OIDC_GIVEN_NAME")
	LET m_oidc.idp_issuer  = fgl_getEnv("OIDC_IDP_ISSUER")
	LET m_oidc.idp_token_endpoint  = fgl_getEnv("OIDC_IDP_TOKEN_ENDPOINT")
	LET m_oidc.name  = fgl_getEnv("OIDC_NAME")
	LET m_oidc.picture  = fgl_getEnv("OIDC_PICTURE")
	LET m_oidc.profile  = fgl_getEnv("OIDC_PROFILE")
	LET m_oidc.sub  = fgl_getEnv("OIDC_SUB")
	LET m_oidc.token_expires_in  = fgl_getEnv("OIDC_TOKEN_EXPIRES_IN")
	LET m_oidc.userinfo_endpoint  = fgl_getEnv("OIDC_USERINFO_ENDPOINT")
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION getToken()
	DEFINE l_stat SMALLINT
	DEFINE l_url, l_state, l_result STRING
	LET l_state = security.RandomGenerator.CreateUUIDString()
	LET l_url = SFMT( "%1?client_id=%2&response_type=code&scope=email&state=%3&redirect_uri=%4",
										C_IDP_ENDPOINT , m_clientId, l_state, m_endPoint)
	DISPLAY "URL:",l_url
	CALL rest_sec.get(l_url,NULL) RETURNING l_stat, l_result
	IF l_result MATCHES "<!DOCTYPE html>*" OR l_result MATCHES "\n<!DOCTYPE html>*" THEN
		CALL show_html(l_result)
	END IF
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION refresh_token()
	DEFINE l_req_data, l_res_data STRING
	DEFINE l_stat SMALLINT
	DEFINE l_refresh_rec RECORD
			access_token STRING,
			refresh_token STRING,
			expires_in STRING,
			scope STRING,
			token_type STRING
		END RECORD

	LET l_req_data = 
		SFMT( "client_secret=%1&client_id=%2&scope=email", m_secretId, m_clientId )
	CALL rest_sec.post( C_IDP_ENDPOINT, l_req_data, NULL ) RETURNING l_stat, l_res_data
	TRY
		CALL util.JSON.parse(l_res_data, l_refresh_rec ) 
		CALL disp("Refresh New Token:"||l_refresh_rec.access_token)
	CATCH
		CALL disp("JSON Parse failed!")
	END TRY
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION show_html(l_html STRING)
	DEFINE l_htmlFile TEXT
	DEFINE l_fileName, l_onICHostReady, l_newHTML STRING
	DEFINE x,y SMALLINT
	LET x = l_html.getIndexOf("<html",1)
	DISPLAY "X:",x
	IF x = 0 THEN LET x = 1 END IF
	LET y = l_html.getIndexOf("</head>",1)
	LET l_newHTML = l_html.subString(x, y-1)
	LET l_onICHostReady = "<script LANGUAGE='JavaScript'>\n
    onICHostReady = function(version) {\n
        if ( version != 1.0 )\n
            alert('Invalid API version');\n
    }\n</script>\n</head>\n<body>"
	LET l_newHTML = l_newHTML.append( l_onICHostReady )
	LET y = l_html.getIndexOf("<body>\n",y)
	LET l_newHTML = l_newHTML.append( l_html.subString(y, l_html.getLength()) )

	LET l_fileName = "webcomponents/html/html.html"
	IF NOT os.Path.exists("webcomponents") THEN
		IF NOT os.path.mkdir("webcomponents") THEN RETURN END IF
		IF NOT os.Path.exists("webcomponents/html") THEN
			IF NOT os.path.mkdir("webcomponents/html") THEN RETURN END IF
		END IF
		IF os.path.exists( l_fileName ) THEN
			IF NOT os.path.delete( l_fileName ) THEN RETURN END IF
		END IF
	END IF
	LOCATE l_htmlFile IN FILE l_fileName
	LET l_htmlFile = l_newHTML
	CALL show_html2()
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION show_html2()
	DEFINE l_html STRING
	OPEN WINDOW show_html WITH FORM "show_html"
	INPUT BY NAME l_html ATTRIBUTES(ACCEPT=FALSE,CANCEL=FALSE)
		ON ACTION close EXIT INPUT
		ON ACTION back EXIT INPUT
	END INPUT
	CLOSE WINDOW show_html
	DISPLAY "HTML:",l_html
END FUNCTION
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
FUNCTION getAPIkeys( l_file STRING ) RETURNS( STRING, STRING, STRING )
	DEFINE rec RECORD
			client STRING,
			secret STRING,
			endpoint STRING
		END RECORD
	DEFINE l_json TEXT
	LOCATE l_json IN MEMORY
	TRY
		CALL l_json.readFile(l_file)
	CATCH
		LET m_txt =  SFMT( "Failed to read %1!", l_file )
		DISPLAY m_Txt
		RETURN NULL, NULL, NULL
	END TRY
	TRY
		CALL util.JSONObject.parse(l_json).toFGL(rec)
	CATCH
		LET m_txt = SFMT( "Failed to parse '%1' content '%2' ", l_file, NVL(l_json,"NULL") )
		DISPLAY m_txt
		RETURN NULL, NULL, NULL
	END TRY
	IF rec.client IS NULL THEN LET m_txt = "Client is NULL" END IF
	IF rec.secret IS NULL THEN LET m_txt = "Secret is NULL" END IF
	IF rec.endpoint IS NULL THEN LET m_txt = "Endpoint is NULL" END IF
	RETURN rec.client, rec.secret, rec.endpoint
END FUNCTION
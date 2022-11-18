
IMPORT util
IMPORT FGL loginws

&include "OpenIdLogin.inc"
DEFINE m_serivceURI STRING = "https://generodemos.dynu.net/g/ws/r/oidws/OpenIdLoginWS"
MAIN
	DEFINE l_rec loginws.getUserResponseBodyType
	DEFINE l_stat SMALLINT
	DEFINE l_msg STRING
	LET loginws.Endpoint.Address.Uri = m_serivceURI
	OPEN FORM loginws FROM "loginws"
	DISPLAY FORM loginws
	MENU
		ON ACTION loginwsform
			CALL loginws_form()

		ON ACTION loginws
			CALL loginws_form()
			CALL loginws.getUser("test") RETURNING l_stat, l_rec.*
			LET l_msg = SFMT("Stat: %1 Email: %2 Scope: %3 Invo: %4",l_stat,l_rec.email,l_rec.scope,l_rec.invocation_id)
			MESSAGE l_msg
			DISPLAY l_msg

		ON ACTION login
			CALL login( C_OPENIDLOGIN )

		ON ACTION checkLogin
			CALL checkLogin()

		ON ACTION exit EXIT MENU
		ON ACTION close EXIT MENU
	END MENU

END MAIN
--------------------------------------------------------------------------------
FUNCTION login(l_url STRING)
	DEFINE l_ret INTEGER

	IF ui.Interface.getFrontEndName() = "GDC" THEN
		LET l_url = "../bin/gdc -u "||l_url
		CALL ui.Interface.frontCall("standard","execute",[l_url, TRUE],[l_ret])
	ELSE
		CALL ui.Interface.frontCall("standard","launchURL",[l_url],[])
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION checkLogin()
	DEFINE l_store STRING
	DEFINE l_oidc t_oidc

	CALL ui.Interface.frontCall("localStorage", "getItem", ["openid"], [l_store])

	DISPLAY "Store:",l_store
	IF l_store IS NULL THEN
		ERROR "Login Invalid!"
		RETURN
	END IF

	CALL util.JSON.parse( l_store, l_oidc )

	MESSAGE "Login Was:",l_oidc.email

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION loginws_form()
	DEFINE l_loginws STRING
	DEFINE l_res, l_cmd STRING
	LET l_loginws = SFMT("%1/getUser/test",m_serivceURI)
--	LET l_loginws = "http://127.0.0.1"
	--DISPLAY BY NAME l_loginws
	INPUT BY NAME l_loginws, l_cmd, l_res WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED)
		ON CHANGE l_loginws
			MESSAGE "Val:",l_loginws
			LET l_res = l_loginws
			DISPLAY "Change:",l_res
		ON ACTION get0
			LET l_cmd = "document.documentElement.innerHTML"
			CALL ui.Interface.frontCall("webcomponent", "call", ["formonly.l_loginws", "eval", l_cmd], [l_res] )
			DISPLAY "Res:",l_res

		ON ACTION get1
			LET l_cmd = "document.getElementsByTagName(\"pre\").item[0]"
			CALL ui.Interface.frontCall("webcomponent", "call", ["formonly.l_loginws", "eval", l_cmd], [l_res] )
			DISPLAY "Res:",l_res

		ON ACTION get2
			CALL ui.Interface.frontCall("webcomponent", "call", ["formonly.l_loginws", "eval", l_cmd], [l_res] )
			DISPLAY "Res:",l_res
	END INPUT
	DISPLAY l_loginws
END FUNCTION
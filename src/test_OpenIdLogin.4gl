
IMPORT util

&include "OpenIdLogin.inc"

MAIN

	MENU
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
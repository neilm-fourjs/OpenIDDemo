IMPORT com

IMPORT FGL OpenIdLoginWS

MAIN
  DEFINE ret INTEGER

  CALL com.WebServiceEngine.RegisterRestService("OpenIdLoginWS", "OpenIdLoginWS")
  CALL log("Server started")
  CALL com.WebServiceEngine.Start()
  WHILE TRUE
    LET ret = com.WebServiceEngine.ProcessServices(-1)
    CASE ret
      WHEN 0
        CALL log("Request processed.")
      WHEN -1
        CALL log("Timeout reached.")
      WHEN -2
        CALL log("Disconnected from application server.")
        EXIT PROGRAM # The Application server has closed the connection
      WHEN -3
        CALL log("Client Connection lost.")
      WHEN -4
        CALL log("Server interrupted with Ctrl-C.")
      WHEN -5
        CALL log(SFMT("BadHTTPHeader: %1",SQLCA.SQLERRM))
      WHEN -9
        CALL log("Unsupported operation.")
      WHEN -10
        CALL log("Internal server error.")
      WHEN -23
        CALL log("Deserialization error.")
      WHEN -35
        CALL log("No such REST operation found.")
      WHEN -36
        CALL log("Missing REST parameter.")
      OTHERWISE
        CALL log("Unexpected server error " || ret || ".")
        EXIT WHILE
    END CASE
    IF int_flag != 0 THEN
      LET int_flag = 0
      EXIT WHILE
    END IF
  END WHILE
  CALL log("Server stopped")
END MAIN
--------------------------------------------------------------------------------------------------------------
FUNCTION log( l_msg STRING )
	DISPLAY l_msg
END FUNCTION
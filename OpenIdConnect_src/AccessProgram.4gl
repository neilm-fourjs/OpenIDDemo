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

IMPORT FGL Logs

PRIVATE CONSTANT C_ACCESS_GRANTED = 0
PRIVATE CONSTANT C_ACCESS_DENIED  = 1
PRIVATE CONSTANT C_ACCESS_ERROR   = 2

PRIVATE CONSTANT C_LOG = "AccessProgram - "
PRIVATE CONSTANT C_ERRORLOG = "AccessProgram ERROR - "
PRIVATE CONSTANT C_DEBUGLOG = "AccessProgram DEBUG - "

#
#
# EXTERNAL APPLICATION TO GRANT ACCESS FOR AN AUTHENTICATED OPENID USER
# TO A GIVEN APPLICATION PATH
#
# NOTE: TO GRANT ACCESS EXIT PROGRAM WITH C_ACCESS_GRANTED OTHERWISE WITH C_ACCESS_DENIED
#
MAIN
  DEFINE  id    STRING
  DEFINE  path  STRING
  DEFINE  attrs DYNAMIC ARRAY OF RECORD
                name  STRING,
                value STRING
                END RECORD
  DEFINE  ind   INTEGER

  # Initialize log
  CALL LOG_INIT(1, ".", "AccessProgram.log")

  # Parse arguments from OpenIDConnect service
  IF base.Application.getArgumentCount() < 2 THEN
    CALL my_errorlog( SFMT("%1Bad arguments: %1",C_ERRORLOG, base.Application.getArgumentCount()))
    EXIT PROGRAM(C_ACCESS_ERROR) # Deny
  ELSE
    LET id = base.Application.getArgument(1)
    LET path = base.Application.getArgument(2)
		CALL disp_args()
    FOR ind=3 TO base.Application.getArgumentCount() STEP 2
      CALL attrs.appendElement()
      LET attrs[attrs.getLength()].name = base.Application.getArgument(ind)
      LET attrs[attrs.getLength()].value = base.Application.getArgument(ind+1)
    END FOR
    CALL CheckAccess(id,path,attrs)
  END IF
END MAIN

#
# Check if given authenticated openid user (id) has access to application path (path) 
#  and with given attribute pairs (attrs) if any
#
# NOTE: TO GRANT ACCESS EXIT PROGRAM WITH C_ACCESS_GRANTED OTHERWISE WITH C_ACCESS_DENIED
#
FUNCTION CheckAccess(id,path,attrs)
  DEFINE    id    STRING
  DEFINE    path  STRING
  DEFINE    attrs DYNAMIC ARRAY OF RECORD
                  name  STRING,
                  value STRING
                  END RECORD
  DEFINE    ok    BOOLEAN
  CALL my_errorlog(C_LOG||"Check Access for '"||id||"' to "||path)  
  CALL DebugAttributes(id,path,attrs)
  LET ok = TRUE # Access check
  IF ok THEN
    CALL my_errorlog(C_LOG||"Access granted")
    EXIT PROGRAM(C_ACCESS_GRANTED)
  ELSE
    CALL my_errorlog(C_LOG||"Access denied") 
    EXIT PROGRAM(C_ACCESS_DENIED)
  END IF  
END FUNCTION

#
# Debug purpose
#                  
FUNCTION DebugAttributes(id,path,attrs)
  DEFINE    id    STRING
  DEFINE    path  STRING
  DEFINE    attrs DYNAMIC ARRAY OF RECORD
                  name  STRING,
                  value STRING
                  END RECORD
  DEFINE    ind   INTEGER
	CALL my_errorlog(SFMT("id=%1 path=%2",id,path))
  FOR ind=1 TO attrs.getLength()
    CALL my_errorlog(SFMT("%1 Attr#%2 %3=%4", C_DEBUGLOG, ind, attrs[ind].name, attrs[ind].value))
  END FOR
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION disp_args()
	DEFINE x SMALLINT
	FOR x = 1 TO base.Application.getArgumentCount()
		DISPLAY SFMT("Args: %1 : %2",x ,base.Application.getArgument(x))
	END FOR
END FUNCTION

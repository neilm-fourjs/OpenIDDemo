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

IMPORT os

PUBLIC CONSTANT C_LOG_ERROR    = 1
PUBLIC CONSTANT C_LOG_DEBUG    = 2
PUBLIC CONSTANT C_LOG_MSG      = 3
PUBLIC CONSTANT C_LOG_ACCESS   = 4
PUBLIC CONSTANT C_LOG_SQLERROR = 5

PRIVATE DEFINE pid   INTEGER
PRIVATE DEFINE level STRING
PRIVATE DEFINE c_log base.Channel

PRIVATE FUNCTION mkdir_recursive(path)
	DEFINE path STRING
	DEFINE
		dirname STRING,
		r       INT
	IF os.Path.exists(path) THEN
		RETURN TRUE
	END IF
	LET dirname = os.Path.dirName(path)
	IF dirname == path THEN
		RETURN TRUE # no dirname to extract anymore
	END IF
	LET r = mkdir_recursive(dirname)
	IF NOT r THEN
		RETURN r
	END IF
	RETURN os.Path.mkdir(path)
END FUNCTION

PUBLIC FUNCTION LOG_INIT(lvl, path, f)
	DEFINE f        STRING
	DEFINE path     STRING
	DEFINE lvl      STRING
	DEFINE fullpath STRING
	LET pid   = fgl_getpid()
	LET level = lvl
	IF path IS NOT NULL AND path.getLength() > 0 THEN
		LET fullpath = os.Path.join(path, "log")
		IF NOT mkdir_recursive(fullpath) THEN
			DISPLAY SFMT("ERROR: Unable to create log file '%1' in '%2' path('%3')", f, fullpath, path)
			EXIT PROGRAM (1)
		END IF
		LET f = os.Path.join(fullpath, f)
	END IF
	DISPLAY SFMT("Logs: %1", f)
	LET c_log = base.Channel.create()
	CALL c_log.openFile(f, "a+")
	CALL startlog(f||"_lagacy")
	IF level IS NOT NULL THEN
		CALL my_errorlog("MSG  : " || pid || " - [Logs] \"INIT\" with level='" || level || "' done")
	ELSE
		CALL my_errorlog("MSG  : " || pid || " - [Logs] \"INIT\" done")
	END IF
END FUNCTION

#
# LOG category : DEBUG or MSG passed as arg_val(1)
# By default : error and access messages are logged
#  MSG : logs also messages
#  DEBUG : logs everything
#
PUBLIC FUNCTION LOG_EVENT(cat, class, ev, msg)
	DEFINE cat   INTEGER
	DEFINE ev    STRING
	DEFINE class STRING
	DEFINE msg   STRING
	IF msg IS NULL THEN
		LET msg = "(null)"
	END IF
	CASE cat
		WHEN C_LOG_ERROR
			CALL my_errorlog("ERROR  : " || pid || " - [" || class || "] \"" || ev || "\" " || msg)
		WHEN C_LOG_DEBUG
			IF level == "DEBUG" THEN
				CALL my_errorlog("DEBUG  : " || pid || " - [" || class || "] \"" || ev || "\" " || msg)
			END IF
		WHEN C_LOG_SQLERROR
			CALL my_errorlog("SQLERR : " || pid || " - [" || class || "] \"" || ev || "\" " || msg)
		WHEN C_LOG_MSG
			IF level == "MSG" OR level == "DEBUG" THEN
				CALL my_errorlog("MSGLOG : " || pid || " - [" || class || "] \"" || ev || "\" " || msg)
			END IF
		WHEN C_LOG_ACCESS
			CALL my_errorlog("ACCESS : " || pid || " - [" || class || "] \"" || ev || "\" " || msg)
	END CASE
END FUNCTION
--------------------------------------------------------------------------------------------------------------
PUBLIC FUNCTION my_errorlog(l_mess STRING)
	DEFINE l_line STRING
	DEFINE l_tok  base.StringTokenizer
	DEFINE i      SMALLINT
	LET l_line = base.Application.getStackTrace()
	LET l_tok  = base.StringTokenizer.create(l_line, "#")
	WHILE l_tok.hasMoreTokens()
		LET l_line = l_tok.nextToken()
		IF l_line IS NULL THEN
			CONTINUE WHILE
		END IF
		IF l_line MATCHES "*my_errorlog*" THEN
			CONTINUE WHILE
		END IF
		IF l_line MATCHES "*LOG_EVENT*" THEN
			CONTINUE WHILE
		END IF
		EXIT WHILE
	END WHILE
	LET i = l_line.getIndexOf(" ", 1)
	CALL c_log.writeLine(SFMT("%1: %2: %3", CURRENT, l_line.subString(i + 1, l_line.getLength() - 1), l_mess))
END FUNCTION

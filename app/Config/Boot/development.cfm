<cfsilent>
<!---
 |---------------------------------------------------------------
 | ERROR DISPLAY
 |---------------------------------------------------------------
 | In development, we want to show as many errors as possible to help
 | make sure they don't make it to production. And save us hours of
 | painful debugging.
--->
<cfset Request.DISPLAY_ERRORS = true>
<cfsetting showdebugoutput="yes">

<!---
 |---------------------------------------------------------------
 | DEBUG BACKTRACES
 |---------------------------------------------------------------
 | If true, error screens show the backtrace (the templates and lines that
 | led to the error) along with the other error information.
--->
<cfparam name="Request.SHOW_DEBUG_BACKTRACE" default="true">

<!---
 |---------------------------------------------------------------
 | DEBUG MODE
 |---------------------------------------------------------------
 | A flag the app and framework can check to turn on extra checks and output.
--->
<cfparam name="Request.APP_DEBUG" default="true">
</cfsilent>

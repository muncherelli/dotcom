<cfsilent>
<!---
 |---------------------------------------------------------------
 | ERROR DISPLAY
 |---------------------------------------------------------------
 | Don't show ANY errors to visitors in production; they get a plain error page.
--->
<cfset Request.DISPLAY_ERRORS = false>
<cfsetting showdebugoutput="no">

<!---
 |---------------------------------------------------------------
 | DEBUG BACKTRACES
--->
<cfparam name="Request.SHOW_DEBUG_BACKTRACE" default="false">

<!---
 |---------------------------------------------------------------
 | DEBUG MODE
--->
<cfparam name="Request.APP_DEBUG" default="false">
<!---
 |---------------------------------------------------------------
 | PAGE CACHE
 |---------------------------------------------------------------
 | Whether cachePage() keeps pages (see app/Config/Cache.cfm).
 | On in production.
--->
<cfparam name="Request.CACHE_PAGES" default="true">
</cfsilent>

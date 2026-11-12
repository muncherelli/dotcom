<cfsilent>
<!---
    Boot: run once per web request by public/index.cfm, after Paths.
--->

<!--- includes from here go up to the project root first --->
<cfset Request.toRoot = RepeatString("../", ListLen(Request.paths.systemDirectory, "/"))>

<!---
 *---------------------------------------------------------------
 * PATH CONSTANTS
 *---------------------------------------------------------------
 * Where the main folders are on disk (each ends in "\"), for
 * reading and writing files. Includes still use Request.paths.
--->

<!--- The path to the project root directory. Just above APPPATH. --->
<cfset Request.ROOTPATH = Request.paths.root>

<!--- The path to the application directory. --->
<cfset Request.APPPATH = Request.ROOTPATH & Replace(Request.paths.appDirectory, "/", "\", "ALL") & "\">

<!--- The path to the system directory. --->
<cfset Request.SYSTEMPATH = Request.ROOTPATH & Replace(Request.paths.systemDirectory, "/", "\", "ALL") & "\">

<!--- The path to the writable directory. --->
<cfset Request.WRITEPATH = Request.ROOTPATH & Replace(Request.paths.writableDirectory, "/", "\", "ALL") & "\">
<cfset writePathMissing = NOT DirectoryExists(Request.WRITEPATH)>
</cfsilent><cfif writePathMissing><cfheader statuscode="503" statustext="Service Unavailable">The WRITEPATH is not set correctly.<cfabort></cfif><cfsilent>

<!---
 *---------------------------------------------------------------
 * CONSTANTS
 *---------------------------------------------------------------
--->
</cfsilent><cfinclude template="#Request.toRoot##Request.paths.appDirectory#/Config/Constants.cfm"><cfsilent>

<!---
 *---------------------------------------------------------------
 * DOTENV
 *---------------------------------------------------------------
 * Settings from the project's .env file, into Request.env.
--->
</cfsilent><cfinclude template="#Request.toRoot##Request.paths.systemDirectory#/Config/DotEnv.cfm"><cfsilent>

<!---
 *---------------------------------------------------------------
 * ENVIRONMENT
 *---------------------------------------------------------------
 * ENVIRONMENT from .env; "production" when it isn't set.
--->
<cfset Request.ENVIRONMENT = "production">
<cfif StructKeyExists(Request.env, "ENVIRONMENT") AND Len(Request.env.ENVIRONMENT)>
    <cfset Request.ENVIRONMENT = Request.env.ENVIRONMENT>
</cfif>
<!---
 *---------------------------------------------------------------
 * ENVIRONMENT-SPECIFIC BOOT
 *---------------------------------------------------------------
 * app/Config/Boot/<ENVIRONMENT>.cfm. The name is used in a path,
 * so it has to be plain lowercase letters, and the file has to exist.
--->
<cfset envBootMissing = REFind("[^a-z]", Request.ENVIRONMENT)
    OR NOT FileExists(Request.APPPATH & "Config\Boot\" & Request.ENVIRONMENT & ".cfm")>
</cfsilent><cfif envBootMissing><cfheader statuscode="503" statustext="Service Unavailable">The application environment is not set correctly.<cfabort></cfif><cfinclude template="#Request.toRoot##Request.paths.appDirectory#/Config/Boot/#Request.ENVIRONMENT#.cfm"><cfsilent>

<!---
 *---------------------------------------------------------------
 * COMMON FUNCTIONS
 *---------------------------------------------------------------
 * app/Common.cfm (if there is one), then system/Common.cfm.
--->
<cfset hasAppCommon = FileExists(Request.APPPATH & "Common.cfm")>
</cfsilent><cfif hasAppCommon><cfinclude template="#Request.toRoot##Request.paths.appDirectory#/Common.cfm"></cfif><cfinclude template="#Request.toRoot##Request.paths.systemDirectory#/Common.cfm"><cfsilent>

<!---
 *---------------------------------------------------------------
 * PAGE CACHE
 *---------------------------------------------------------------
 * A GET for a page that's in the cache and hasn't expired is sent
 * from there, and nothing else runs.
--->
<cfset Request.cacheTTL = 0>
<cfset pageCacheOn = Request.CACHE_PAGES AND ListFind("GET,HEAD", UCase(CGI.REQUEST_METHOD))>
</cfsilent><cfif pageCacheOn><cfinclude template="#Request.toRoot##Request.paths.appDirectory#/Config/Cache.cfm"><cfset pageCacheStep = "serve"><cfinclude template="#Request.toRoot##Request.paths.systemDirectory#/Cache/PageCache.cfm"><cfif cacheHit><cfheader name="X-Cache" value="HIT"><cfcontent type="text/html" reset="yes"><cfoutput>#output#</cfoutput><cfabort></cfif></cfif><cfsilent>

<!---
 *---------------------------------------------------------------
 * RUN THE REQUEST
 *---------------------------------------------------------------
 * Its output is held back until it has finished, so a failure
 * halfway through shows only the error page.
--->
<cftry>
    <cfsavecontent variable="output"><cfinclude template="#Request.toRoot##Request.paths.systemDirectory#/Run.cfm"></cfsavecontent>
    <cfcatch type="Any">
        <cfset Request.cacheTTL = 0>
        <cfset Request.exception = StructNew()>
        <cfset Request.exception.type = cfcatch.Type>
        <!--- CF 5 words some messages in HTML: keep just the text --->
        <cfset Request.exception.message = Trim(REReplace(REReplace(cfcatch.Message, "<[^>]*>", " ", "ALL"), "[[:space:]]+", " ", "ALL"))>
        <cfset Request.exception.message = Replace(Replace(Replace(Replace(Request.exception.message, "&lt;", "<", "ALL"), "&gt;", ">", "ALL"), "&quot;", """", "ALL"), "&amp;", "&", "ALL")>
        <cfset Request.exception.detail = Trim(REReplace(REReplace(cfcatch.Detail, "<[^>]*>", " ", "ALL"), "[[:space:]]+", " ", "ALL"))>
        <cfset Request.exception.detail = Replace(Replace(Replace(Replace(Request.exception.detail, "&lt;", "<", "ALL"), "&gt;", ">", "ALL"), "&quot;", """", "ALL"), "&amp;", "&", "ALL")>
        <cfset Request.exception.tagContext = cfcatch.TagContext>
        <cfsavecontent variable="output"><cfinclude template="#Request.toRoot##Request.paths.systemDirectory#/Debug/Exceptions.cfm"></cfsavecontent>
    </cfcatch>
</cftry>
<!--- keep the page if the controller asked to and it went well --->
<cfset output = Trim(output)>
<cfparam name="Request.show404" default="false">
<cfset pageCacheStep = "store">
<cfset storePage = pageCacheOn AND Request.cacheTTL GT 0 AND NOT Request.show404>
</cfsilent><cfif storePage><cfinclude template="#Request.toRoot##Request.paths.systemDirectory#/Cache/PageCache.cfm"><cfheader name="X-Cache" value="MISS"></cfif><cfsilent>

<!--- drop the blank lines the included files left before this point --->
</cfsilent><cfcontent type="text/html" reset="yes"><cfoutput>#output#</cfoutput>
<cfsilent>
<cfset Request.startTick = GetTickCount()>
<!---
 *---------------------------------------------------------------
 * CHECK COLDFUSION VERSION
--->
<cfset minCfVersion = "5.0">
<cfscript>
cfVersionParts = ListToArray(Server.ColdFusion.ProductVersion, ", .");
cfVersion = ArrayToList(cfVersionParts, ".");
minParts = ListToArray(minCfVersion, ".");
cfTooOld = false;
for (i = 1; i LTE ArrayLen(minParts); i = i + 1) {
    have = 0;
    if (i LTE ArrayLen(cfVersionParts)) have = Val(cfVersionParts[i]);
    if (have NEQ Val(minParts[i])) {
        cfTooOld = have LT Val(minParts[i]);
        break;
    }
}
</cfscript>
</cfsilent><cfif cfTooOld><cfheader statuscode="503" statustext="Service Unavailable"><cfoutput>Your ColdFusion version must be #minCfVersion# or higher to run this site. Current version: #cfVersion#</cfoutput><cfabort></cfif><cfsilent>

<!---
 *---------------------------------------------------------------
 * SET THE CURRENT DIRECTORY
 *---------------------------------------------------------------
 * ColdFusion has no working directory to change; it resolves includes
 * from each file's own folder. FCPATH records where this file lives.
--->
<cfset Request.FCPATH = GetDirectoryFromPath(GetCurrentTemplatePath())>

<!---
 *---------------------------------------------------------------
 * BOOTSTRAP THE APPLICATION
 *----------------------------------------------------------------
 * Loads the paths config, then the framework's boot file, which sets
 * up the environment and runs the request.
--->

<!--- 
 *---------------------------------------------------------------
 * LOAD OUR PATHS CONFIG FILE
 *---------------------------------------------------------------
 * This is the line that might need to be changed, depending on your folder structure. 
--->
<cfinclude template="../app/Config/Paths.cfm">

<!--- ^^^ Change this line if you move your application folder --->

</cfsilent><cfinclude template="../#Request.paths.systemDirectory#/Boot.cfm">
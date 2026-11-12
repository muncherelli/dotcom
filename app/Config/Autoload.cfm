<cfsilent>
<!---
    Autoload: files loaded on every request, after the common functions.
--->
<cfset Request.autoload = StructNew()>

<!---
 | -------------------------------------------------------------------
 | Files
 | -------------------------------------------------------------------
 | The files array provides a list of paths to files of functions
 | (such as libraries in app/ThirdParty) that will be autoloaded.
 | Paths are from the project root, written with "/". Each is loaded
 | once: ColdFusion 5 can't declare a function twice.
 |
 | Prototype:
 |   ArrayAppend(Request.autoload.files, "app/ThirdParty/Name/Name.cfm");
--->
<cfset Request.autoload.files = ArrayNew(1)>
<cfset ArrayAppend(Request.autoload.files, "app/ThirdParty/Markdown/Markdown.cfm")>
</cfsilent>

<cfsilent>
<!---
    Paths

    Holds the paths that are used by the system to
    locate the main directories, app, system, etc.

    Modifying these allows you to restructure your application,
    share a system folder between multiple applications, and more.

    All paths are relative to the project's root folder, written with "/".
    ColdFusion 5 can only include files by relative path, so the framework
    turns these into "../" paths for includes. Request.paths.root is the
    project root on disk, for reading and writing files.
--->
<cfset Request.paths = StructNew()>

<!--- SYSTEM FOLDER NAME: the framework itself --->
<cfset Request.paths.systemDirectory = "system">

<!--- APPLICATION FOLDER NAME: this app's code (this folder's parent) --->
<cfset Request.paths.appDirectory = "app">

<!--- WRITABLE DIRECTORY NAME: the one place ColdFusion may write (logs, cache, uploads) --->
<cfset Request.paths.writableDirectory = "writable">

<!--- VIEW DIRECTORY NAME: the app's views --->
<cfset Request.paths.viewDirectory = "app/Views">

<!--- ENVIRONMENT DIRECTORY NAME: where the .env file is; never publicly reachable --->
<cfset Request.paths.envDirectory = "">

<!--- the project root on disk: two folders up from this file (app/Config/) --->
<cfset Request.paths.root = REReplace(GetDirectoryFromPath(GetCurrentTemplatePath()), "[^\\]+\\[^\\]+\\$", "")>
</cfsilent>

<cfsilent>
<!---
    Router: works out the request's path and finds the first route for it.

    Sets Request.uri (the path, no leading or trailing "/") and Request.route:
    found (true/false), controller, method, params (array), from (the pattern).
--->

<!--- IIS 4 puts the script name in front of PATH_INFO ("/index.cfm/blog/x").
      A request for /index.cfm/... itself has it twice once rewritten. --->
<cfset uri = CGI.PATH_INFO>
<cfloop condition="Left(uri, Len(CGI.SCRIPT_NAME)) EQ CGI.SCRIPT_NAME AND (Len(uri) EQ Len(CGI.SCRIPT_NAME) OR Mid(uri, Len(CGI.SCRIPT_NAME) + 1, 1) EQ '/')">
    <cfset uri = Mid(uri, Len(CGI.SCRIPT_NAME) + 1, Len(uri))>
</cfloop>
<cfset Request.uri = REReplace(uri, "^/+|/+$", "", "ALL")>

<cfset Request.route = StructNew()>
<cfset Request.route.found = false>
<cfset verb = UCase(CGI.REQUEST_METHOD)>
<cfif verb EQ "HEAD"><cfset verb = "GET"></cfif>

<cfloop from="1" to="#ArrayLen(Request.routeTable)#" index="routeN">
    <cfset r = Request.routeTable[routeN]>
    <cfif r.verb EQ "*" OR r.verb EQ verb>
        <cfset hit = REFind(r.regex, "/" & Request.uri, 1, true)>
        <cfif hit.pos[1] GT 0>
            <!--- "Blog::show/$1" -> controller Blog, method show, params [group 1] --->
            <cfset target = r.to>
            <cfloop from="#ArrayLen(hit.pos)#" to="2" step="-1" index="g">
                <cfset groupText = "">
                <cfif hit.len[g] GT 0><cfset groupText = Mid("/" & Request.uri, hit.pos[g], hit.len[g])></cfif>
                <cfset target = Replace(target, "$" & (g - 1), groupText, "ALL")>
            </cfloop>
            <cfset Request.route.found = true>
            <cfset Request.route.from = r.from>
            <cfset Request.route.controller = ListFirst(target, ":")>
            <cfset methodPart = "">
            <cfif Find("::", target)><cfset methodPart = Mid(target, Find("::", target) + 2, Len(target))></cfif>
            <cfset Request.route.method = "index">
            <cfif Len(ListFirst(methodPart, "/"))><cfset Request.route.method = ListFirst(methodPart, "/")></cfif>
            <cfset Request.route.params = ListToArray(ListRest(methodPart, "/"), "/")>
            <cfbreak>
        </cfif>
    </cfif>
</cfloop>
</cfsilent>

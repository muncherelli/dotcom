<cfsilent>
<!---
    Run: handles the request. Boot runs it inside the error handler and sends
    what it outputs.

    1. Routes: app/Config/Routes.cfm fills in the route table.
    2. Router: finds the route for this request; none is a 404.
    3. Controller: app/Controllers/<Name>.cfm (after BaseController.cfm), then
       calls the route's method with the route's arguments.
    4. Output: what the method returns (and anything it printed), with each
       view() in it rendered.
--->

<!--- 1. ROUTES --->
</cfsilent><cfinclude template="#Request.toRoot##Request.paths.systemDirectory#/Router/RouteCollection.cfm"><cfinclude template="#Request.toRoot##Request.paths.appDirectory#/Config/Routes.cfm"><cfsilent>

<!--- 2. ROUTER --->
</cfsilent><cfinclude template="#Request.toRoot##Request.paths.systemDirectory#/Router/Router.cfm"><cfsilent>
<cfset Request.show404 = NOT Request.route.found>

<!--- 3. CONTROLLER --->
<cfset Request.viewQueue = ArrayNew(1)>
<cfset result = "">
<cfif NOT Request.show404>
    <cfset ctrl = Request.route.controller>
    <cfset method = Request.route.method>
    <cfif NOT REFind("^[A-Za-z][A-Za-z0-9_]*$", ctrl) OR NOT REFind("^[A-Za-z][A-Za-z0-9_]*$", method)>
        <cfthrow message="Router: the route ""#Request.route.from#"" names an invalid controller or method: #ctrl#::#method#">
    </cfif>
    <cfif NOT FileExists(Request.APPPATH & "Controllers\" & ctrl & ".cfm")>
        <cfthrow message="Router: controller #ctrl# not found (app/Controllers/#ctrl#.cfm)">
    </cfif>
    <cfset hasBase = ctrl NEQ "BaseController" AND FileExists(Request.APPPATH & "Controllers\BaseController.cfm")>
</cfif>
</cfsilent><cfif NOT Request.show404><cfif hasBase><cfinclude template="#Request.toRoot##Request.paths.appDirectory#/Controllers/BaseController.cfm"></cfif><cfinclude template="#Request.toRoot##Request.paths.appDirectory#/Controllers/#ctrl#.cfm"></cfif><cfsilent>
<cfif NOT Request.show404>
    <cfif NOT (IsDefined(method) AND IsCustomFunction(Evaluate(method)))>
        <cfthrow message="Router: #ctrl#.cfm has no function #method#()">
    </cfif>
    <cfset callArgs = "">
    <cfloop from="1" to="#ArrayLen(Request.route.params)#" index="argN">
        <cfset callArgs = ListAppend(callArgs, "Request.route.params[#argN#]")>
    </cfloop>
</cfif>
</cfsilent><cfif NOT Request.show404><cfsavecontent variable="printed"><cfset result = Evaluate("#method#(#callArgs#)")></cfsavecontent><cfif IsSimpleValue(result)><cfset result = printed & result><cfelse><cfset result = printed></cfif></cfif><cfsilent>

<!--- 4. OUTPUT: a 404, or the result with its views rendered --->
<cfif Request.show404>
    <cfheader statuscode="404" statustext="Not Found">
    <cfset result = view("errors/html/error_404")>
</cfif>
</cfsilent><cfinclude template="#Request.toRoot##Request.paths.systemDirectory#/View/Render.cfm"><cfoutput>#result#</cfoutput>

<cfsilent>
<!---
 | --------------------------------------------------------------------
 | Routes
 | --------------------------------------------------------------------
 | routes.get("path", "Controller::method") and .post/.put/.patch/.delete/
 | .options/.add (any method). See system/Router/RouteCollection.cfm.
--->
<cfscript>
routes.get("/", "Home::index");
</cfscript>
</cfsilent>

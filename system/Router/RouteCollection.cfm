<cfsilent>
<!---
    RouteCollection: the `routes` object that app/Config/Routes.cfm fills in.

        routes.get("/", "Home::index");
        routes.get("blog/(:segment)", "Blog::show/$1");
        routes.post("contact", "Contact::send");
        routes.add("legacy", "Legacy::index");          any method

    The path is matched without its leading and trailing "/" ("/" is the home
    page). Placeholders: (:any) (:segment) (:num) (:alpha) (:alphanum) (:hash);
    anything else is a regular expression. "$1".."$9" in the target pass what
    the groups matched to the controller method as arguments.
--->
<cfset Request.routeTable = ArrayNew(1)>
<cfscript>
function route_add(verb, from, to) {
    var r = StructNew();
    var pattern = REReplace(Trim(from), "^/+|/+$", "", "ALL");
    r.verb = verb;
    r.from = pattern;
    pattern = Replace(pattern, "(:any)", "(.*)", "ALL");
    pattern = Replace(pattern, "(:segment)", "([^/]+)", "ALL");
    pattern = Replace(pattern, "(:alphanum)", "([a-zA-Z0-9]+)", "ALL");
    pattern = Replace(pattern, "(:num)", "([0-9]+)", "ALL");
    pattern = Replace(pattern, "(:alpha)", "([a-zA-Z]+)", "ALL");
    pattern = Replace(pattern, "(:hash)", "([^/]+)", "ALL");
    // matched against "/" & path: CF 5's REFind never matches an empty string
    r.regex = "^/" & pattern & "$";
    r.to = to;
    ArrayAppend(Request.routeTable, r);
    return true;
}
function route_get(from, to)     { return route_add("GET", from, to); }
function route_post(from, to)    { return route_add("POST", from, to); }
function route_put(from, to)     { return route_add("PUT", from, to); }
function route_patch(from, to)   { return route_add("PATCH", from, to); }
function route_delete(from, to)  { return route_add("DELETE", from, to); }
function route_options(from, to) { return route_add("OPTIONS", from, to); }
function route_any(from, to)     { return route_add("*", from, to); }

routes = StructNew();
routes.get = route_get;
routes.post = route_post;
routes.put = route_put;
routes.patch = route_patch;
routes.delete = route_delete;
routes.options = route_options;
routes.add = route_any;
</cfscript>
</cfsilent>

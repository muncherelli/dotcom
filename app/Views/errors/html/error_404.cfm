<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="robots" content="noindex">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>404 - Page Not Found</title>
    <style>
        body { margin: 0; padding: 4rem 1rem; font: 1rem/1.5 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; color: #777; background: #fafafa; text-align: center; }
        h1 { margin: 0 0 1rem; font-size: 3rem; font-weight: 300; color: #222; }
        p { margin: 0; }
        code { font: .9em ui-monospace, Consolas, monospace; }
    </style>
</head>
<body>
<cfoutput>
    <h1>404 - Page Not Found</h1>
    <cfif Request.DISPLAY_ERRORS>
        <cfif Request.route.found>
            <p><code>#esc(Request.route.controller)#::#esc(Request.route.method)#</code> sent a 404 for <code>/#esc(Request.uri)#</code>.</p>
        <cfelse>
            <p>No route matches <code>#esc(CGI.REQUEST_METHOD)# /#esc(Request.uri)#</code>.</p>
        </cfif>
    <cfelse>
        <p>Sorry! Cannot seem to find the page you were looking for.</p>
    </cfif>
</cfoutput>
</body>
</html>

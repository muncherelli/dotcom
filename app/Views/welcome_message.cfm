<cfset elapsed = GetTickCount() - Request.startTick><!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>muncherelli.com</title>
    <style>
        body { margin: 0; padding: 4rem 1rem; font: 1rem/1.6 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; color: #222; background: #fafafa; }
        main { max-width: 40rem; margin: 0 auto; }
        h1 { margin: 0 0 .5rem; font-size: 2.25rem; font-weight: 300; }
        p { color: #555; }
        code { padding: .1em .35em; border-radius: 4px; background: #eee; font: .9em ui-monospace, Consolas, monospace; }
        footer { margin-top: 3rem; font-size: .85rem; color: #888; }
    </style>
</head>
<body>
<cfoutput>
    <main>
        <h1>muncherelli.com</h1>
        <p>This page is <code>app/Views/welcome_message.cfm</code>, returned by
           <code>Home::index</code> in <code>app/Controllers/Home.cfm</code>.</p>
        <p>Routes live in <code>app/Config/Routes.cfm</code>.</p>
        <footer>
            Page rendered in #elapsed# ms &mdash;
            Environment: #esc(Request.ENVIRONMENT)# &mdash;
            ColdFusion #esc(ArrayToList(ListToArray(Server.ColdFusion.ProductVersion, ", "), "."))#
        </footer>
    </main>
</cfoutput>
</body>
</html>

<cfsilent>
<!--- Development error page: what failed, where, and how it got there. --->
<cfset exc = Request.exception>
<cfset cfVer = ArrayToList(ListToArray(Server.ColdFusion.ProductVersion, ", "), ".")>
</cfsilent><!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="robots" content="noindex">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><cfoutput>#esc(exc.type)#</cfoutput></title>
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; font: .95rem/1.5 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; color: #222; background: #fff; }
        .header { padding: 1.5rem 1rem; background: #b80000; color: #fff; }
        .environment { font-size: .8rem; opacity: .85; }
        .container { max-width: 64rem; margin: 0 auto; padding: 0 1rem; }
        h1 { margin: .25rem 0 .5rem; font-size: 1.6rem; font-weight: 400; }
        .header p { margin: 0; }
        .detail { margin-top: .5rem; opacity: .9; }
        h2 { margin: 1.5rem 0 .5rem; font-size: 1rem; }
        .source { margin: 0; padding: .5rem 0; overflow-x: auto; background: #1e1e1e; color: #ddd; border-radius: 6px; font: .85rem/1.45 ui-monospace, Consolas, monospace; }
        .source div { padding: 0 1rem; white-space: pre; }
        .source .hit { background: #6b1414; color: #fff; }
        .source span { display: inline-block; width: 3.5em; color: #888; user-select: none; }
        ol.trace { padding-left: 1.5rem; font: .85rem/1.6 ui-monospace, Consolas, monospace; }
        table { border-collapse: collapse; font-size: .85rem; }
        td { padding: .2rem 1rem .2rem 0; vertical-align: top; }
        td:first-child { color: #666; white-space: nowrap; }
    </style>
</head>
<body>
<cfoutput>
    <div class="header">
        <div class="container">
            <div class="environment">
                Displayed at #TimeFormat(Now(), "HH:mm:ss")# &mdash;
                ColdFusion: #esc(cfVer)# &mdash;
                Environment: #esc(Request.ENVIRONMENT)#
            </div>
            <h1>#esc(exc.type)#</h1>
            <p>#esc(exc.message)#</p>
            <cfif Len(Trim(exc.detail))><p class="detail">#esc(exc.detail)#</p></cfif>
        </div>
    </div>

    <div class="container">
        <cfif Len(exc.file)>
            <h2>#esc(exc.file)# at line #exc.line#</h2>
        </cfif>
        <cfif ArrayLen(exc.source)>
            <div class="source"><cfloop from="1" to="#ArrayLen(exc.source)#" index="i"><div<cfif exc.source[i].number EQ exc.line> class="hit"</cfif>><span>#exc.source[i].number#</span>#esc(exc.source[i].text)#</div></cfloop></div>
        </cfif>

        <cfif Request.SHOW_DEBUG_BACKTRACE AND ArrayLen(exc.tagContext)>
            <h2>Backtrace</h2>
            <ol class="trace">
                <cfloop from="1" to="#ArrayLen(exc.tagContext)#" index="i">
                    <li>#esc(exc.tagContext[i].template)#:#exc.tagContext[i].line#<cfif StructKeyExists(exc.tagContext[i], "id") AND Len(exc.tagContext[i].id)> &mdash; #esc(exc.tagContext[i].id)#</cfif></li>
                </cfloop>
            </ol>
        </cfif>

        <h2>Request</h2>
        <table>
            <tr><td>Method</td><td>#esc(CGI.REQUEST_METHOD)#</td></tr>
            <tr><td>Path</td><td>#esc(CGI.PATH_INFO)#</td></tr>
            <tr><td>Query string</td><td>#esc(CGI.QUERY_STRING)#</td></tr>
            <tr><td>Host</td><td>#esc(CGI.HTTP_HOST)#</td></tr>
            <tr><td>Remote address</td><td>#esc(CGI.REMOTE_ADDR)#</td></tr>
        </table>
    </div>
</cfoutput>
</body>
</html>

<cfsilent>
<!---
    Toolbar: in development (Request.APP_DEBUG), a small window in the corner of
    every page with what this request carried: the route, the client IP, CGI
    variables, headers, URL, Form and Cookie values, and the .env settings.
    Boot puts it just before </body>. Values that look secret are hidden.
--->
<cfscript>
function tb_rows(s) {
    var out = "";
    var k = "";
    var keys = ListSort(StructKeyList(s), "textnocase");
    var i = 0;
    var v = "";
    for (i = 1; i LTE ListLen(keys); i = i + 1) {
        k = ListGetAt(keys, i);
        v = s[k];
        if (NOT IsSimpleValue(v)) v = "(complex value)";
        else if (REFindNoCase("pass|secret|token|key", k) AND Len(v)) v = "********";
        out = out & "<tr><td>" & esc(k) & "</td><td>" & esc(v) & "</td></tr>";
    }
    if (out EQ "") out = "<tr><td colspan=""2""><i>none</i></td></tr>";
    return out;
}
</cfscript>
<!--- the Request section keeps its own order and names (struct keys come out sorted, in capitals) --->
<cfif Request.fromPageCache>
    <cfset tbRoute = "(sent from the page cache; no route ran)">
<cfelseif Request.route.found>
    <cfset tbRoute = "/" & Request.route.from & "  ->  " & Request.route.controller & "::" & Request.route.method & "(" & ArrayToList(Request.route.params, ", ") & ")">
<cfelse>
    <cfset tbRoute = "(no route matched)">
</cfif>
<cfset tbElapsed = GetTickCount() - Request.startTick>
<cfset tbRequestRows = "">
<cfset tbPairs = ArrayNew(1)>
<cfset ArrayAppend(tbPairs, "Method|" & CGI.REQUEST_METHOD)>
<cfset ArrayAppend(tbPairs, "Path|" & CGI.PATH_INFO)>
<cfset ArrayAppend(tbPairs, "Route|" & tbRoute)>
<cfset ArrayAppend(tbPairs, "Client IP|" & client_ip())>
<cfset ArrayAppend(tbPairs, "REMOTE_ADDR|" & CGI.REMOTE_ADDR)>
<cfset ArrayAppend(tbPairs, "Environment|" & Request.ENVIRONMENT)>
<cfset ArrayAppend(tbPairs, "Time so far|" & tbElapsed & " ms")>
<cfloop from="1" to="#ArrayLen(tbPairs)#" index="i">
    <cfset tbRequestRows = tbRequestRows & "<tr><td>" & esc(ListFirst(tbPairs[i], "|")) & "</td><td>" & esc(ListRest(tbPairs[i], "|")) & "</td></tr>">
</cfloop>
<cfset tbCgi = StructNew()>
<cfloop list="#StructKeyList(CGI)#" index="k"><cfset tbCgi[k] = Evaluate("CGI." & k)></cfloop>
<cfset tbHttp = GetHttpRequestData()>
<cfset tbHeaders = tbHttp.headers>
<cfset tbSections = "Request,CGI,Headers,URL,Form,Cookie,Env">
</cfsilent><cfoutput><details id="cf-debug" style="position:fixed;right:12px;bottom:12px;z-index:2147483647;max-width:min(42rem,calc(100vw - 24px));font:12px/1.4 ui-monospace,Consolas,monospace;color:##eee;background:##1e1e1e;border-radius:8px;box-shadow:0 4px 18px rgba(0,0,0,.35)">
<summary style="cursor:pointer;padding:6px 12px;user-select:none">&##9881; #esc(client_ip())# &middot; #esc(tbRoute)#</summary>
<div style="max-height:60vh;overflow:auto;padding:0 12px 10px">
<style>##cf-debug table{border-collapse:collapse;width:100%}##cf-debug td{padding:2px 8px 2px 0;vertical-align:top;word-break:break-all}##cf-debug td:first-child{color:##9cdcfe;white-space:nowrap;word-break:normal}##cf-debug h4{margin:10px 0 4px;color:##ffb86c;font-size:12px}</style>
<h4>Request</h4><table>#tbRequestRows#</table>
<h4>CGI</h4><table>#tb_rows(tbCgi)#</table>
<h4>Headers</h4><table>#tb_rows(tbHeaders)#</table>
<h4>URL</h4><table>#tb_rows(URL)#</table>
<h4>Form</h4><table>#tb_rows(Form)#</table>
<h4>Cookie</h4><table>#tb_rows(Cookie)#</table>
<h4>Env (.env)</h4><table>#tb_rows(Request.env)#</table>
</div>
</details></cfoutput>

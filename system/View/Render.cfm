<cfsilent>
<!---
    Render: replaces each view() placeholder in `result` with that view's output.
    A view is app/Views/<name>.cfm; its data's keys become variables in it.
    Views may call view() themselves; those are rendered in turn.

    A view given a cache time is kept in writable/cache/view-<md5 of its cache
    name>.html (first line: when it expires, seconds since 1970) and taken from
    there until then. A view that itself calls view() isn't cached.

    CF 5's cfscript can't include a file, read or write one, throw or catch,
    so those steps stay tags.
--->
<cfscript>
renderPass = 0;
nowSeconds = DateDiff("s", CreateDateTime(1970, 1, 1, 0, 0, 0), Now());
</cfscript>
</cfsilent><cfloop condition="Find(Chr(1) & 'view', result) AND renderPass LT 50"><cfsilent>
    <cfscript>
    renderPass = renderPass + 1;
    tokenAt = Find(Chr(1) & "view", result);
    tokenEnd = Find(Chr(2), result, tokenAt);
    theView = Request.viewQueue[Val(Mid(result, tokenAt + 5, tokenEnd - tokenAt - 5))];
    viewError = "";
    if (NOT REFind("^[A-Za-z0-9_]+(/[A-Za-z0-9_]+)*$", theView.name)) {
        viewError = "view(): invalid view name """ & theView.name & """";
    } else if (NOT FileExists(Request.ROOTPATH & Replace(Request.paths.viewDirectory & "/" & theView.name, "/", "\", "ALL") & ".cfm")) {
        viewError = "view(): no view " & theView.name & " (" & Request.paths.viewDirectory & "/" & theView.name & ".cfm)";
    }
    viewCacheOn = Request.cacheOn AND theView.cache GT 0;
    viewCacheFile = "";
    if (viewCacheOn) viewCacheFile = Request.WRITEPATH & "cache\view-" & LCase(Hash(theView.cacheName)) & ".html";
    viewFromCache = false;
    </cfscript>
    <cfif Len(viewError)><cfthrow message="#viewError#"></cfif>

    <!--- the view cache: use a stored copy that hasn't expired --->
    <cfif viewCacheOn AND FileExists(viewCacheFile)>
        <cftry>
            <cffile action="read" file="#viewCacheFile#" variable="cached">
            <cfscript>
            firstBreak = Find(Chr(10), cached);
            if (firstBreak GT 1 AND Val(Left(cached, firstBreak - 1)) GT nowSeconds) {
                viewFromCache = true;
                rendered = "";
                if (firstBreak LT Len(cached)) rendered = Right(cached, Len(cached) - firstBreak);
            }
            </cfscript>
            <!--- an unreadable cache file just means the view is made again --->
            <cfcatch type="Any"><cfset viewFromCache = false></cfcatch>
        </cftry>
    </cfif>

    <cfscript>
    // the view's data, as variables it can use, and the way from it up to
    // the project root (for paths such as cfmodule's)
    if (NOT viewFromCache) {
        for (dataKey in theView.data) SetVariable(dataKey, theView.data[dataKey]);
        Request.viewToRoot = RepeatString("../", ListLen(Request.paths.viewDirectory & "/" & theView.name, "/") - 1);
    }
    </cfscript>
</cfsilent><cfif NOT viewFromCache><cfsavecontent variable="rendered"><cfinclude template="../#Request.toRoot##Request.paths.viewDirectory#/#theView.name#.cfm"></cfsavecontent></cfif><cfsilent>

    <!--- keep a freshly made view; one with view() calls inside can't be stored as is --->
    <cfif viewCacheOn AND NOT viewFromCache AND NOT Find(Chr(1) & "view", rendered)>
        <cftry>
            <cfif NOT DirectoryExists(Request.WRITEPATH & "cache")>
                <cfdirectory action="create" directory="#Request.WRITEPATH#cache">
            </cfif>
            <cffile action="write" file="#viewCacheFile#" output="#(nowSeconds + theView.cache)##Chr(10)##rendered#" addnewline="no">
            <!--- a cache we can't write mustn't break the page --->
            <cfcatch type="Any"></cfcatch>
        </cftry>
    </cfif>

    <cfscript>
    // put the output in place of the placeholder (CF 5's Left/Right won't take a count of 0)
    before = "";
    if (tokenAt GT 1) before = Left(result, tokenAt - 1);
    after = "";
    if (tokenEnd LT Len(result)) after = Right(result, Len(result) - tokenEnd);
    result = before & rendered & after;
    </cfscript>
</cfsilent></cfloop>

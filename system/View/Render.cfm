<cfsilent>
<!---
    Render: replaces each view() placeholder in `result` with that view's output.
    A view is app/Views/<name>.cfm; its data's keys become variables in it.
    Views may call view() themselves; those are rendered in turn.

    A view given a cache time is kept in writable/cache/view-<md5 of its cache
    name>.html (first line: when it expires, seconds since 1970) and taken from
    there until then. A view that itself calls view() isn't cached.
--->
<cfset renderPass = 0>
<cfset nowSeconds = DateDiff("s", CreateDateTime(1970, 1, 1, 0, 0, 0), Now())>
</cfsilent><cfloop condition="Find(Chr(1) & 'view', result) AND renderPass LT 50"><cfsilent>
    <cfset renderPass = renderPass + 1>
    <cfset tokenAt = Find(Chr(1) & "view", result)>
    <cfset tokenEnd = Find(Chr(2), result, tokenAt)>
    <cfset viewN = Val(Mid(result, tokenAt + 5, tokenEnd - tokenAt - 5))>
    <cfset theView = Request.viewQueue[viewN]>
    <cfif NOT REFind("^[A-Za-z0-9_]+(/[A-Za-z0-9_]+)*$", theView.name)>
        <cfthrow message="view(): invalid view name ""#theView.name#""">
    </cfif>
    <cfif NOT FileExists(Request.ROOTPATH & Replace(Request.paths.viewDirectory & "/" & theView.name, "/", "\", "ALL") & ".cfm")>
        <cfthrow message="view(): no view #theView.name# (#Request.paths.viewDirectory#/#theView.name#.cfm)">
    </cfif>

    <!--- the view cache: use a stored copy that hasn't expired --->
    <cfset viewCacheOn = Request.cacheOn AND theView.cache GT 0>
    <cfset viewFromCache = false>
    <cfif viewCacheOn>
        <cfset viewCacheFile = Request.WRITEPATH & "cache\view-" & LCase(Hash(theView.cacheName)) & ".html">
        <cfif FileExists(viewCacheFile)>
            <cftry>
                <cffile action="read" file="#viewCacheFile#" variable="cached">
                <cfset firstBreak = Find(Chr(10), cached)>
                <cfif firstBreak GT 1 AND Val(Left(cached, firstBreak - 1)) GT nowSeconds>
                    <cfset viewFromCache = true>
                    <cfset rendered = "">
                    <cfif firstBreak LT Len(cached)><cfset rendered = Right(cached, Len(cached) - firstBreak)></cfif>
                </cfif>
                <!--- an unreadable cache file just means the view is made again --->
                <cfcatch type="Any"><cfset viewFromCache = false></cfcatch>
            </cftry>
        </cfif>
    </cfif>

    <cfif NOT viewFromCache>
        <cfloop collection="#theView.data#" item="dataKey">
            <cfset SetVariable(dataKey, theView.data[dataKey])>
        </cfloop>
    </cfif>
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

    <!--- (CF 5's Left/Right won't take a count of 0) --->
    <cfset before = "">
    <cfif tokenAt GT 1><cfset before = Left(result, tokenAt - 1)></cfif>
    <cfset after = "">
    <cfif tokenEnd LT Len(result)><cfset after = Right(result, Len(result) - tokenEnd)></cfif>
    <cfset result = before & rendered & after>
</cfsilent></cfloop>

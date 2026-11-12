<cfsilent>
<!---
    PageCache: Boot includes this twice. With pageCacheStep "serve" (before
    the request runs) it sends a cached page that hasn't expired and stops.
    With "store" (after a request that called cachePage()) it saves the page.

    A cache file is writable/cache/page-<md5 of host, path, query>.html: the
    first line is when it expires (seconds since 1970), the rest is the page.
--->
<cfset nowSeconds = DateDiff("s", CreateDateTime(1970, 1, 1, 0, 0, 0), Now())>
<cfset cacheKey = LCase(CGI.HTTP_HOST) & CGI.PATH_INFO>
<cfif Request.cache.cacheQueryString><cfset cacheKey = cacheKey & "?" & CGI.QUERY_STRING></cfif>
<cfset cacheFile = Request.WRITEPATH & "cache\page-" & LCase(Hash(cacheKey)) & ".html">
<cfset cacheHit = false>

<cfif pageCacheStep EQ "serve" AND FileExists(cacheFile)>
    <cftry>
        <cffile action="read" file="#cacheFile#" variable="cached">
        <cfset firstBreak = Find(Chr(10), cached)>
        <cfif firstBreak GT 1>
            <cfset expires = Val(Left(cached, firstBreak - 1))>
            <cfif expires GT nowSeconds>
                <cfset cacheHit = true>
                <cfset output = "">
                <cfif firstBreak LT Len(cached)><cfset output = Right(cached, Len(cached) - firstBreak)></cfif>
                <cfset cacheSecondsLeft = expires - nowSeconds>
            </cfif>
        </cfif>
        <!--- an unreadable cache file just means the page is made again --->
        <cfcatch type="Any"><cfset cacheHit = false></cfcatch>
    </cftry>
</cfif>

<cfif pageCacheStep EQ "store">
    <cfset cacheSecondsLeft = Request.cacheTTL>
    <cftry>
        <cfif NOT DirectoryExists(Request.WRITEPATH & "cache")>
            <cfdirectory action="create" directory="#Request.WRITEPATH#cache">
        </cfif>
        <cffile action="write" file="#cacheFile#" output="#(nowSeconds + Request.cacheTTL)##Chr(10)##output#" addnewline="no">
        <!--- a cache we can't write mustn't break the page --->
        <cfcatch type="Any"></cfcatch>
    </cftry>
</cfif>

<cfif (cacheHit OR pageCacheStep EQ "store") AND Request.cache.sendHeaders>
    <cfheader name="Cache-Control" value="public, max-age=#cacheSecondsLeft#">
</cfif>
</cfsilent>

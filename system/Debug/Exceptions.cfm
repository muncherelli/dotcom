<cfsilent>
<!---
    Exceptions: Boot includes this when the request fails, with the error in
    Request.exception (type, message, detail, tagContext). It logs the error to
    writable/logs, sends a 500 and shows the error page for the environment:
    app/Views/errors/html/error_exception.cfm when Request.DISPLAY_ERRORS is on,
    app/Views/errors/html/production.cfm otherwise.
--->
<cfset exc = Request.exception>
<cfheader statuscode="500" statustext="Internal Server Error">

<!--- CF 5 lists the backtrace outermost first: turn it round so the
      template that failed comes first, then where it happened --->
<cfset trace = ArrayNew(1)>
<cfloop from="#ArrayLen(exc.tagContext)#" to="1" step="-1" index="i">
    <cfset ArrayAppend(trace, exc.tagContext[i])>
</cfloop>
<cfset exc.tagContext = trace>
<cfset exc.file = "">
<cfset exc.line = 0>
<cfif ArrayLen(exc.tagContext)>
    <cfset exc.file = exc.tagContext[1].template>
    <cfset exc.line = Val(exc.tagContext[1].line)>
</cfif>

<!--- log it: writable/logs/log-YYYY-MM-DD.log, one line per error --->
<cfset logDir = Request.WRITEPATH & "logs\">
<cftry>
    <cfif NOT DirectoryExists(logDir)><cfdirectory action="create" directory="#logDir#"></cfif>
    <cfset logLine = "CRITICAL - " & DateFormat(Now(), "yyyy-mm-dd") & " " & TimeFormat(Now(), "HH:mm:ss")
        & " --> " & exc.type & ": " & REReplace(exc.message, "[[:cntrl:]]+", " ", "ALL")
        & " in " & exc.file & ":" & exc.line & " (" & CGI.REQUEST_METHOD & " " & CGI.PATH_INFO & ")">
    <cffile action="append" file="#logDir#log-#DateFormat(Now(), 'yyyy-mm-dd')#.log" output="#logLine#" addnewline="yes">
    <cfcatch type="Any"><!--- a log we can't write mustn't hide the real error ---></cfcatch>
</cftry>

<!--- the source lines around the error, for the development page --->
<cfset exc.source = ArrayNew(1)>
<cfif Request.DISPLAY_ERRORS AND exc.line GT 0 AND FileExists(exc.file)>
    <cffile action="read" file="#exc.file#" variable="srcText">
    <cfset srcText = Replace(srcText, Chr(13), "", "ALL") & Chr(10)>
    <cfset srcFrom = Max(1, exc.line - 7)>
    <cfset srcTo = exc.line + 7>
    <cfset srcN = 1>
    <cfset srcAt = 1>
    <cfloop condition="srcN LTE srcTo AND srcAt LTE Len(srcText)">
        <cfset srcEnd = Find(Chr(10), srcText, srcAt)>
        <cfif srcN GTE srcFrom>
            <cfset srcLine = StructNew()>
            <cfset srcLine.number = srcN>
            <cfset srcLine.text = Mid(srcText, srcAt, srcEnd - srcAt + 1)>
            <cfset ArrayAppend(exc.source, srcLine)>
        </cfif>
        <cfset srcAt = srcEnd + 1>
        <cfset srcN = srcN + 1>
    </cfloop>
</cfif>
<cfset Request.exception = exc>
<cfset errorView = "production">
<cfif Request.DISPLAY_ERRORS><cfset errorView = "error_exception"></cfif>
</cfsilent><cfinclude template="../#Request.toRoot##Request.paths.viewDirectory#/errors/html/#errorView#.cfm">

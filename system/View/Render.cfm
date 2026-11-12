<cfsilent>
<!---
    Render: replaces each view() placeholder in `result` with that view's output.
    A view is app/Views/<name>.cfm; its data's keys become variables in it.
    Views may call view() themselves; those are rendered in turn.
--->
<cfset renderPass = 0>
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
    <cfloop collection="#theView.data#" item="dataKey">
        <cfset SetVariable(dataKey, theView.data[dataKey])>
    </cfloop>
</cfsilent><cfsavecontent variable="rendered"><cfinclude template="../#Request.toRoot##Request.paths.viewDirectory#/#theView.name#.cfm"></cfsavecontent><cfsilent>
    <!--- (CF 5's Left/Right won't take a count of 0) --->
    <cfset before = "">
    <cfif tokenAt GT 1><cfset before = Left(result, tokenAt - 1)></cfif>
    <cfset after = "">
    <cfif tokenEnd LT Len(result)><cfset after = Right(result, Len(result) - tokenEnd)></cfif>
    <cfset result = before & rendered & after>
</cfsilent></cfloop>

<!---
    Markdown tests: converts each case in cases.txt and compares it with
    the HTML expected. A case is

        @@ name
        the Markdown
        @@ html
        the HTML it should become

    Run it on its own (not through the framework, which has already
    loaded markdown()): include it from a page that is reachable, e.g.
    <cfinclude template="../app/ThirdParty/Markdown/tests/run.cfm">
--->
<cfinclude template="../Markdown.cfm">
<cffile action="read" file="#GetDirectoryFromPath(GetCurrentTemplatePath())#cases.txt" variable="mdTestText">
<cfscript>
mdTestLines = ListToArray(Replace(Replace(Replace(mdTestText, Chr(13), "", "ALL"), Chr(10) & Chr(10), Chr(10) & " " & Chr(10), "ALL"), Chr(10) & Chr(10), Chr(10) & " " & Chr(10), "ALL"), Chr(10));
mdTests = ArrayNew(1);
mdPart = "";
for (i = 1; i LTE ArrayLen(mdTestLines); i = i + 1) {
    line = mdTestLines[i];
    if (line EQ " ") line = "";
    if (line EQ "@@ html") {
        mdPart = "html";
    } else if (Left(line, 3) EQ "@@ ") {
        mdTest = StructNew();
        mdTest.name = Mid(line, 4, Len(line));
        mdTest.md = ArrayNew(1);
        mdTest.html = ArrayNew(1);
        ArrayAppend(mdTests, mdTest);
        mdPart = "md";
    } else if (Len(mdPart)) {
        ArrayAppend(mdTests[ArrayLen(mdTests)][mdPart], line);
    }
}
mdPassed = 0;
mdReport = ArrayNew(1);
for (i = 1; i LTE ArrayLen(mdTests); i = i + 1) {
    mdTest = mdTests[i];
    want = Trim(ArrayToList(mdTest.html, Chr(10)));
    got = markdown(ArrayToList(mdTest.md, Chr(10)));
    if (Compare(got, want) EQ 0) {
        mdPassed = mdPassed + 1;
        ArrayAppend(mdReport, "PASS " & mdTest.name);
    } else {
        ArrayAppend(mdReport, "FAIL " & mdTest.name & Chr(10) & "--- got:" & Chr(10) & got & Chr(10) & "--- want:" & Chr(10) & want);
    }
}
ArrayAppend(mdReport, mdPassed & "/" & ArrayLen(mdTests) & " passed");
</cfscript>
<cfcontent type="text/plain" reset="yes"><cfoutput>#ArrayToList(mdReport, Chr(10))#
</cfoutput>

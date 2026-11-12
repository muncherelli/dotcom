<!---
    MarkdownTag: a custom tag for Markdown written in a page.

        <cfmodule template="#Request.viewToRoot#app/ThirdParty/Markdown/MarkdownTag.cfm">
            ## Hello
            Some **Markdown**.
        </cfmodule>

    or, for Markdown in a variable:

        <cfmodule template="..." text="#post.body#">

    The indent all the body's lines share is taken off first, so the
    Markdown can be indented to fit the HTML around it.
--->
<cfif ThisTag.ExecutionMode EQ "end" OR NOT ThisTag.HasEndTag><cfsilent>
    <!--- a custom tag has its own variables, so it loads markdown() for itself --->
    <cfinclude template="Markdown.cfm">
    <cfscript>
    if (StructKeyExists(Attributes, "text")) mdTagText = Attributes.text;
    else mdTagText = ThisTag.GeneratedContent;
    mdTagLines = md_lines(Replace(Replace(mdTagText, Chr(13) & Chr(10), Chr(10), "ALL"), Chr(9), "    ", "ALL"));
    // the smallest indent of the lines that aren't blank
    mdTagIndent = 1000;
    for (i = 1; i LTE ArrayLen(mdTagLines); i = i + 1) {
        if (NOT md_blank(mdTagLines[i])) mdTagIndent = Min(mdTagIndent, md_indent(mdTagLines[i]));
    }
    for (i = 1; i LTE ArrayLen(mdTagLines); i = i + 1) mdTagLines[i] = md_dedent(mdTagLines[i], mdTagIndent);
    mdTagHtml = markdown(ArrayToList(mdTagLines, Chr(10)));
    </cfscript>
</cfsilent><cfif ThisTag.HasEndTag><cfset ThisTag.GeneratedContent = mdTagHtml><cfelse><cfoutput>#mdTagHtml#</cfoutput></cfif></cfif>

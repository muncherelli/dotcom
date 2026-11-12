<cfsilent>
<cfscript>
function index() {
    cachePage(60);
    return view("welcome_message");
}
</cfscript>
</cfsilent>

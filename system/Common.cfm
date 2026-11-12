<cfsilent>
<!---
    Common functions: available everywhere after Boot has run.
--->
<cfscript>
/**
 * env(name [, default]): a setting from .env. "true"/"false" become booleans,
 * "empty" and "null" become "". The default (or "") when it isn't set.
 */
function env(name) {
    var value = "";
    if (ArrayLen(Arguments) GT 1) value = Arguments[2];
    if (StructKeyExists(Request.env, name)) {
        value = Request.env[name];
        switch (LCase(value)) {
            case "true":  value = true;  break;
            case "false": value = false; break;
            case "empty": value = "";    break;
            case "null":  value = "";    break;
        }
    }
    return value;
}

/**
 * esc(data [, context]): escapes data for the place it's written into.
 * context: html (default), attr (inside an attribute value), js (inside a
 * JavaScript string), css (inside a CSS value), url (a URL part), raw (as is).
 * Arrays and structs are escaped value by value.
 */
function esc(data) {
    var context = "html";
    var out = "";
    var i = 0;
    var c = "";
    var code = 0;
    var key = "";
    if (ArrayLen(Arguments) GT 1) context = LCase(Arguments[2]);
    if (context EQ "raw") return data;
    if (IsArray(data)) {
        for (i = 1; i LTE ArrayLen(data); i = i + 1) data[i] = esc(data[i], context);
        return data;
    }
    if (IsStruct(data)) {
        for (key in data) data[key] = esc(data[key], context);
        return data;
    }
    if (context EQ "html") return Replace(HTMLEditFormat(data), "'", "&##039;", "ALL");
    if (context EQ "url") return URLEncodedFormat(data);
    if (ListFind("attr,js,css", context) EQ 0) {
        // CF 5 can't throw from a function: this fails with the context in the message
        return Evaluate("esc_invalid_context_" & REReplace(context, "[^a-z0-9_]", "_", "ALL"));
    }
    // attr/js/css: letters and digits stay, everything else becomes an escape
    for (i = 1; i LTE Len(data); i = i + 1) {
        c = Mid(data, i, 1);
        code = Asc(c);
        if (REFind("[A-Za-z0-9]", c) OR (context NEQ "css" AND Find(c, ",._") GT 0)
            OR (context EQ "attr" AND c EQ "-")) {
            out = out & c;
        } else if (context EQ "attr") {
            out = out & "&##x" & UCase(FormatBaseN(code, 16)) & ";";
        } else if (context EQ "js") {
            out = out & "\x" & UCase(Right("0" & FormatBaseN(code, 16), 2));
        } else {
            out = out & "\" & UCase(FormatBaseN(code, 16)) & " ";
        }
    }
    return out;
}
/**
 * view(name [, data]): the output of app/Views/<name>.cfm, with data's keys as
 * variables in it. Return it from a controller method; join views with &.
 * (It stands in for the view until the method returns: CF 5 functions can't
 * include templates, so the framework renders it then.)
 */
function view(name) {
    var v = StructNew();
    v.name = name;
    v.data = StructNew();
    if (ArrayLen(Arguments) GT 1) v.data = Arguments[2];
    ArrayAppend(Request.viewQueue, v);
    return Chr(1) & "view" & ArrayLen(Request.viewQueue) & Chr(2);
}

/**
 * show404(): from a controller method, `return show404();` sends the 404 page.
 */
function show404() {
    Request.show404 = true;
    return "";
}
/**
 * cachePage(seconds): from a controller method, keep this page in the page
 * cache for that long (see app/Config/Cache.cfm). Does nothing when
 * Request.CACHE_PAGES is off.
 */
function cachePage(seconds) {
    Request.cacheTTL = Val(seconds);
    return "";
}
</cfscript>
</cfsilent>

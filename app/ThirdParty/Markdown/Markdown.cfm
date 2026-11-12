<cfsilent>
<!---
    Markdown: a small Markdown to HTML converter for ColdFusion 5.

    markdown(text) returns the HTML for a Markdown text. It follows the
    core of CommonMark, simplified:

        headings        # to ######, or a line underlined with === or ---
        paragraphs      split by blank lines; two spaces or a \ at the end
                        of a line make a line break
        emphasis        *em* _em_ **strong** __strong__ ***both***
        code            `code`, fenced blocks (``` or ~~~) and blocks
                        indented by four spaces
        links           [text](url "title"), [text][ref], [ref], <url>
        images          ![alt](src "title"), ![alt][ref]
        references      [ref]: url "title" (on a line of its own)
        block quotes    > quoted text
        lists           - * + bullets, 1. or 1) numbers; nest by indenting
        rules           --- *** ___
        escapes         \ before punctuation shows it as a plain character

    HTML written in the Markdown is passed through as is: only convert
    text you trust.

    How it works: the blocks (paragraphs, lists...) are found line by line,
    then the text inside them is converted in one go for the whole document.
    CF 5 compiles a regular expression every time it's used and every
    statement costs, so a line's first character decides what it could be,
    and each inline regular expression runs once, not once per paragraph.

    While it works, the text carries markers that can't be in the Markdown:
        Chr(5) Chr(6)       < and > of the block tags (<p>, <li>...), so the
                            inline steps leave them alone; nothing inline
                            reaches past a Chr(5), so it stays in its block
        Chr(3) N Chr(4)     finished HTML set aside in st.keep (code, links,
                            tags), put back at the end
--->
<cfscript>
/**
 * markdown(text): the HTML for a Markdown text.
 */
function markdown(text) {
    var s = Replace(Replace(text, Chr(13) & Chr(10), Chr(10), "ALL"), Chr(13), Chr(10), "ALL");
    var refs = StructNew();
    var st = StructNew();
    var lines = 0;
    st.keep = ArrayNew(1);
    s = Replace(Replace(Replace(Replace(s, Chr(3), "", "ALL"), Chr(4), "", "ALL"), Chr(5), "", "ALL"), Chr(6), "", "ALL");
    s = Replace(s, Chr(9), "    ", "ALL");
    lines = md_lines(s);
    if (Find("]:", s)) lines = md_refs(lines, refs);
    s = md_inline(md_blocks(lines, false, st), refs, st);
    return Replace(Replace(md_restore(s, st), Chr(5), "<", "ALL"), Chr(6), ">", "ALL");
}

/*
 * ---------------------------------------------------------------
 *  STRINGS
 * ---------------------------------------------------------------
 */

// count characters from start ("" for none: CF 5's Mid won't take 0)
function md_sub(s, start, count) {
    if (count LT 1) return "";
    return Mid(s, start, count);
}

// everything from start to the end
function md_from(s, start) {
    return md_sub(s, start, Len(s) - start + 1);
}

// the text's lines; an empty line comes back as " " (ListToArray would drop it)
function md_lines(s) {
    s = Replace(s, Chr(10) & Chr(10), Chr(10) & " " & Chr(10), "ALL");
    s = Replace(s, Chr(10) & Chr(10), Chr(10) & " " & Chr(10), "ALL");
    if (Left(s, 1) EQ Chr(10)) s = " " & s;
    return ListToArray(s, Chr(10));
}

function md_blank(line) {
    return Len(Trim(line)) EQ 0;
}

function md_indent(line) {
    return Len(line) - Len(LTrim(line));
}

// the line without up to n of its leading spaces
function md_dedent(line, n) {
    return md_from(line, Min(md_indent(line), n) + 1);
}

// escaped for HTML text or an attribute value
function md_esc(s) {
    return Replace(Replace(Replace(Replace(s, "&", "&amp;", "ALL"), "<", "&lt;", "ALL"), ">", "&gt;", "ALL"), """", "&quot;", "ALL");
}

// a reference label, matched without regard to case
function md_key(label) {
    return UCase(Trim(label));
}

// a block tag (see the top): md_tag("p") for <p>
function md_tag(name) {
    return Chr(5) & name & Chr(6);
}

// finished HTML, set aside until the end; returns its placeholder
function md_token(st, html) {
    ArrayAppend(st.keep, html);
    return Chr(3) & ArrayLen(st.keep) & Chr(4);
}

// the text with its placeholders put back
function md_restore(s, st) {
    var parts = ArrayNew(1);
    var pos = 1;
    var at = Find(Chr(3), s);
    var stop = 0;
    if (at EQ 0) return s;
    while (at GT 0) {
        ArrayAppend(parts, md_sub(s, pos, at - pos));
        stop = Find(Chr(4), s, at);
        ArrayAppend(parts, md_restore(st.keep[Val(Mid(s, at + 1, stop - at - 1))], st));
        pos = stop + 1;
        at = Find(Chr(3), s, pos);
    }
    ArrayAppend(parts, md_from(s, pos));
    return ArrayToList(parts, "");
}

/*
 * ---------------------------------------------------------------
 *  BLOCKS
 * ---------------------------------------------------------------
 */

// what a line could start: blank, code (indented 4), fence, atx, hr, quote,
// html, li (a list item), li0 (a list item that can't end a paragraph:
// empty, or numbered from other than 1) or text
function md_kind(line) {
    var t = LTrim(line);
    var c = Left(t, 1);
    var x = "";
    if (Len(t) EQ 0) return "blank";
    if (Len(line) - Len(t) GE 4) return "code";
    if (Find(c, "`~##><-*_+0123456789") EQ 0) return "text";
    if (c EQ "`" OR c EQ "~") {
        // ``` or ~~~ (or longer); a backtick fence's info string can't have backticks
        x = SpanIncluding(t, c);
        if (Len(x) GE 3 AND NOT (c EQ "`" AND Find("`", md_from(t, Len(x) + 1)))) return "fence";
        return "text";
    }
    if (c EQ "##") {
        x = SpanIncluding(t, "##");
        if (Len(x) LE 6 AND (Len(x) EQ Len(t) OR Mid(t, Len(x) + 1, 1) EQ " ")) return "atx";
        return "text";
    }
    if (c EQ ">") return "quote";
    if (c EQ "<") {
        // an HTML block starts with a comment or a block-level tag
        x = md_from(t, 2);
        if (Left(x, 3) EQ "!--") return "html";
        if (Left(x, 1) EQ "/") x = md_from(x, 2);
        c = SpanIncluding(LCase(x), "abcdefghijklmnopqrstuvwxyz0123456789");
        x = Left(md_from(x, Len(c) + 1), 1);
        if (Len(c) AND (Len(x) EQ 0 OR Find(x, " />")) AND ListFind("address,article,aside,blockquote,body,center,details,dialog,dd,div,dl,dt,fieldset,figcaption,figure,footer,form,h1,h2,h3,h4,h5,h6,head,header,hr,html,iframe,legend,li,main,nav,ol,p,pre,script,section,style,summary,table,tbody,td,tfoot,th,thead,title,tr,ul", c)) return "html";
        return "text";
    }
    // --- *** ___ (spaces allowed between)
    if (Find(c, "-*_")) {
        x = Replace(Trim(t), " ", "", "ALL");
        if (Len(x) GE 3 AND Len(Replace(x, c, "", "ALL")) EQ 0) return "hr";
    }
    // list item: - * + or 1. 1) then a space (or nothing)
    if (Find(c, "-*+")) {
        x = md_from(t, 2);
        c = "1";
    } else if (Find(c, "0123456789")) {
        c = SpanIncluding(t, "0123456789");
        x = md_from(t, Len(c) + 1);
        if (Len(c) GT 9 OR (Left(x, 1) NEQ "." AND Left(x, 1) NEQ ")")) return "text";
        x = md_from(x, 2);
    } else {
        return "text";
    }
    if (Len(x) AND Left(x, 1) NEQ " ") return "text";
    if (Len(Trim(x)) EQ 0 OR Val(c) NEQ 1) return "li0";
    return "li";
}

// a list item's marker (for a line md_kind calls li or li0): width is how
// far the item's text is indented
function md_marker(line) {
    var m = StructNew();
    var t = LTrim(line);
    var x = SpanIncluding(t, "0123456789");
    var spaces = 0;
    m.ordered = 0;
    m.start = 1;
    if (Len(x)) {
        m.ordered = 1;
        m.start = Val(x);
    }
    m.delim = Mid(t, Len(x) + 1, 1);
    x = md_from(t, Len(x) + 2);
    spaces = Len(x) - Len(LTrim(x));
    // five or more spaces: the text is an indented code block
    if (spaces GE 5 OR Len(Trim(x)) EQ 0) spaces = 1;
    m.width = Len(line) - Len(x) + spaces;
    return m;
}

// whether the line closes the code block opened by fence
function md_fence_closes(line, fence) {
    var t = Trim(line);
    return md_indent(line) LE 3 AND Len(t) GE Len(fence) AND Len(Replace(t, Left(fence, 1), "", "ALL")) EQ 0;
}

// takes the reference definitions ([ref]: url "title") out of the lines, into refs
function md_refs(lines, refs) {
    var out = ArrayNew(1);
    var fence = "";
    var canStart = true;
    var isDef = false;
    var i = 0;
    var r = 0;
    var t = "";
    var key = "";
    var def = 0;
    for (i = 1; i LTE ArrayLen(lines); i = i + 1) {
        isDef = false;
        t = LTrim(lines[i]);
        if (Len(fence)) {
            if (md_fence_closes(lines[i], fence)) fence = "";
        } else if ((Left(t, 1) EQ "`" OR Left(t, 1) EQ "~") AND md_kind(lines[i]) EQ "fence") {
            fence = SpanIncluding(t, Left(t, 1));
        } else if (canStart AND Left(t, 1) EQ "[" AND md_indent(lines[i]) LE 3 AND Find("]:", t)) {
            r = REFind("^\[([^]]+)\]: *<?([^ <>]+)>?( +""([^""]*)"")? *$", t, 1, true);
            isDef = r.pos[1] GT 0;
        }
        if (isDef) {
            key = md_key(Mid(t, r.pos[2], r.len[2]));
            // the first definition of a label wins
            if (NOT StructKeyExists(refs, key)) {
                def = StructNew();
                def.url = Mid(t, r.pos[3], r.len[3]);
                def.title = "";
                if (ArrayLen(r.pos) GE 5) def.title = md_sub(t, r.pos[5], r.len[5]);
                refs[key] = def;
            }
        } else {
            ArrayAppend(out, lines[i]);
        }
        // a definition can't break into a paragraph
        canStart = isDef OR Len(Trim(t)) EQ 0 OR Left(t, 1) EQ "##";
    }
    return out;
}

// the blocks of lines of Markdown, with their text still to be converted;
// tight leaves paragraphs without <p> (in tight lists)
function md_blocks(lines, tight, st) {
    var out = ArrayNew(1);
    var n = ArrayLen(lines);
    var i = 1;
    var k = 0;
    var line = "";
    var kind = "";
    var m = 0;
    var first = 0;
    var buf = 0;
    var items = 0;
    var info = "";
    var fence = "";
    var loose = false;
    var blanks = 0;
    var level = 0;
    var tag = "";
    var html = "";
    var c = "";
    // the kinds of line that end a paragraph
    var stops = ",fence,atx,hr,html,quote,li,";
    while (i LTE n) {
        line = lines[i];
        kind = md_kind(line);

        if (kind EQ "blank") {
            i = i + 1;

        } else if (kind EQ "code") {
            // indented code block
            buf = ArrayNew(1);
            while (i LTE n AND (md_blank(lines[i]) OR md_indent(lines[i]) GE 4)) {
                ArrayAppend(buf, md_dedent(lines[i], 4));
                i = i + 1;
            }
            k = ArrayLen(buf);
            while (k GT 0 AND md_blank(buf[k])) {
                ArrayDeleteAt(buf, k);
                k = k - 1;
            }
            ArrayAppend(out, md_token(st, "<pre><code>" & md_esc(ArrayToList(buf, Chr(10))) & Chr(10) & "</code></pre>"));

        } else if (kind EQ "fence") {
            // fenced code block; the info string's first word names the language
            k = md_indent(line);
            info = LTrim(line);
            fence = SpanIncluding(info, Left(info, 1));
            info = Trim(md_from(info, Len(fence) + 1));
            tag = "<code>";
            if (Len(info)) tag = "<code class=""language-" & md_esc(ListFirst(info, " ")) & """>";
            buf = ArrayNew(1);
            i = i + 1;
            while (i LTE n AND NOT md_fence_closes(lines[i], fence)) {
                if (md_blank(lines[i])) ArrayAppend(buf, Chr(10));
                else ArrayAppend(buf, md_dedent(lines[i], k) & Chr(10));
                i = i + 1;
            }
            i = i + 1;
            ArrayAppend(out, md_token(st, "<pre>" & tag & md_esc(ArrayToList(buf, "")) & "</code></pre>"));

        } else if (kind EQ "atx") {
            // heading: closing #s are left off
            info = Trim(line);
            level = Len(SpanIncluding(info, "##"));
            info = md_from(info, level + 1);
            if (Right(info, 1) EQ "##") info = REReplace(" " & info, " ##+ *$", "");
            ArrayAppend(out, md_tag("h" & level) & Trim(info) & md_tag("/h" & level));
            i = i + 1;

        } else if (kind EQ "hr") {
            ArrayAppend(out, md_tag("hr"));
            i = i + 1;

        } else if (kind EQ "quote") {
            // block quote: lines without > carry on its last paragraph
            buf = ArrayNew(1);
            while (i LTE n) {
                line = lines[i];
                kind = md_kind(line);
                if (kind EQ "quote") {
                    line = md_from(LTrim(line), 2);
                    if (Left(line, 1) EQ " ") line = md_from(line, 2);
                } else if (kind EQ "blank" OR Find("," & kind & ",", stops)) {
                    break;
                }
                ArrayAppend(buf, line);
                i = i + 1;
            }
            ArrayAppend(out, md_tag("blockquote") & Chr(10) & md_blocks(buf, false, st) & Chr(10) & md_tag("/blockquote"));

        } else if (kind EQ "li" OR kind EQ "li0") {
            // list: items with the same kind of marker; blank lines between
            // its items (or its items' blocks) make it loose (<p> in every item)
            first = md_marker(line);
            items = ArrayNew(1);
            loose = false;
            while (i LTE n) {
                kind = md_kind(lines[i]);
                if (kind NEQ "li" AND kind NEQ "li0") break;
                m = md_marker(lines[i]);
                if (m.ordered NEQ first.ordered OR m.delim NEQ first.delim) break;
                buf = ArrayNew(1);
                ArrayAppend(buf, md_from(lines[i], m.width + 1));
                i = i + 1;
                blanks = 0;
                while (i LTE n) {
                    line = lines[i];
                    if (md_blank(line)) {
                        blanks = blanks + 1;
                    } else if (md_indent(line) GE m.width) {
                        line = md_dedent(line, m.width);
                        if (blanks GT 0) {
                            kind = md_kind(line);
                            if (kind NEQ "li" AND kind NEQ "li0") loose = true;
                        }
                        blanks = 0;
                    } else {
                        if (blanks GT 0) break;
                        kind = md_kind(line);
                        if (kind EQ "li0" OR Find("," & kind & ",", stops)) break;
                    }
                    ArrayAppend(buf, line);
                    i = i + 1;
                }
                k = ArrayLen(buf);
                while (k GT 1 AND md_blank(buf[k])) {
                    ArrayDeleteAt(buf, k);
                    k = k - 1;
                }
                if (blanks GT 0 AND i LTE n) loose = true;
                ArrayAppend(items, buf);
            }
            tag = "ul";
            if (first.ordered) tag = "ol";
            html = md_tag(tag);
            if (first.ordered AND first.start NEQ 1) html = md_tag("ol start=""" & first.start & """");
            for (k = 1; k LTE ArrayLen(items); k = k + 1) {
                html = html & Chr(10) & md_tag("li") & md_blocks(items[k], NOT loose, st) & md_tag("/li");
            }
            ArrayAppend(out, html & Chr(10) & md_tag("/" & tag));

        } else if (kind EQ "html") {
            // HTML block: passed through up to the next blank line
            buf = ArrayNew(1);
            while (i LTE n AND NOT md_blank(lines[i])) {
                ArrayAppend(buf, lines[i]);
                i = i + 1;
            }
            ArrayAppend(out, md_token(st, ArrayToList(buf, Chr(10))));

        } else {
            // paragraph, or a heading when it's underlined with === or ---
            buf = ArrayNew(1);
            ArrayAppend(buf, LTrim(line));
            level = 0;
            i = i + 1;
            while (i LTE n) {
                line = LTrim(lines[i]);
                c = Left(line, 1);
                // most lines are plain text: no need to look closer
                if (Len(line) EQ 0 OR Find(c, "`~##><-*_+0123456789=")) {
                    kind = md_kind(lines[i]);
                    if (kind EQ "blank") break;
                    if ((c EQ "=" OR c EQ "-") AND kind NEQ "code" AND Len(Replace(Trim(line), c, "", "ALL")) EQ 0) {
                        level = 1;
                        if (c EQ "-") level = 2;
                        i = i + 1;
                        break;
                    }
                    if (Find("," & kind & ",", stops)) break;
                }
                ArrayAppend(buf, line);
                i = i + 1;
            }
            html = RTrim(ArrayToList(buf, Chr(10)));
            if (level GT 0) {
                ArrayAppend(out, md_tag("h" & level) & html & md_tag("/h" & level));
            } else if (tight) {
                ArrayAppend(out, html);
            } else {
                ArrayAppend(out, md_tag("p") & html & md_tag("/p"));
            }
        }
    }
    return ArrayToList(out, Chr(10));
}

/*
 * ---------------------------------------------------------------
 *  INLINES
 * ---------------------------------------------------------------
 */

// the text of all the blocks converted
function md_inline(s, refs, st) {
    var L = Chr(5);
    var parts = ArrayNew(1);
    var pos = 1;
    var at = 0;
    var c = "";
    var run = 0;
    var stop = 0;
    var edge = 0;
    var x = "";

    // code spans, backslash escapes, autolinks and HTML tags, left to right
    at = REFind("[\\`<]", s);
    while (at GT 0) {
        ArrayAppend(parts, md_sub(s, pos, at - pos));
        c = Mid(s, at, 1);
        pos = at + 1;
        // where this block ends
        edge = Find(L, s, at);
        if (edge EQ 0) edge = Len(s) + 1;
        if (c EQ "\") {
            c = Left(md_from(s, at + 1), 1);
            if (c EQ Chr(10)) {
                ArrayAppend(parts, md_token(st, "<br>") & Chr(10));
                pos = at + 2;
            } else if (Len(c) AND Find(c, "!""##$%&'()*+,-./:;<=>?@[\]^_`{|}~")) {
                ArrayAppend(parts, md_token(st, md_esc(c)));
                pos = at + 2;
            } else {
                ArrayAppend(parts, "\");
            }
        } else if (c EQ "`") {
            // a code span ends at the next run of exactly as many backticks
            run = Len(SpanIncluding(md_from(s, at), "`"));
            pos = at + run;
            stop = 0;
            at = Find("`", s, pos);
            while (at GT 0 AND at LT edge AND stop EQ 0) {
                c = SpanIncluding(md_from(s, at), "`");
                if (Len(c) EQ run) stop = at;
                else at = Find("`", s, at + Len(c));
            }
            if (stop GT 0) {
                x = Replace(md_sub(s, pos, stop - pos), Chr(10), " ", "ALL");
                if (Len(x) GT 2 AND Left(x, 1) EQ " " AND Right(x, 1) EQ " " AND Len(Trim(x))) x = Mid(x, 2, Len(x) - 2);
                ArrayAppend(parts, md_token(st, "<code>" & md_esc(x) & "</code>"));
                pos = stop + run;
            } else {
                ArrayAppend(parts, RepeatString("`", run));
            }
        } else {
            // <scheme:url>, <name@host>, or an HTML tag or comment
            stop = Find(">", s, at);
            x = "";
            if (stop GT 0 AND stop LT edge) x = md_sub(s, at + 1, stop - at - 1);
            c = Left(x, 1);
            if (Len(x) EQ 0 OR Find("<", x)) {
                ArrayAppend(parts, "<");
            } else if (Find(" ", x) EQ 0 AND Find(Chr(10), x) EQ 0 AND Find(":", x) AND REFind("^[A-Za-z][A-Za-z0-9+.-]+:", x)) {
                ArrayAppend(parts, md_token(st, "<a href=""" & md_esc(x) & """>" & md_esc(x) & "</a>"));
                pos = stop + 1;
            } else if (Find(" ", x) EQ 0 AND Find(Chr(10), x) EQ 0 AND Find("@", x) GT 1) {
                ArrayAppend(parts, md_token(st, "<a href=""mailto:" & md_esc(x) & """>" & md_esc(x) & "</a>"));
                pos = stop + 1;
            } else if (c EQ "/" OR c EQ "!" OR REFind("[A-Za-z]", c)) {
                ArrayAppend(parts, md_token(st, "<" & x & ">"));
                pos = stop + 1;
            } else {
                ArrayAppend(parts, "<");
            }
        }
        at = 0;
        if (pos LTE Len(s)) at = REFind("[\\`<]", s, pos);
    }
    ArrayAppend(parts, md_from(s, pos));
    s = ArrayToList(parts, "");

    // escape what's left for HTML, keeping entities such as &copy; and &##169;
    if (Find("&", s)) s = REReplace(Replace(s, "&", "&amp;", "ALL"), "&amp;(##[0-9]{1,7}|##[xX][0-9A-Fa-f]{1,6}|[A-Za-z][A-Za-z0-9]{1,31});", "&\1;", "ALL");
    s = Replace(Replace(s, "<", "&lt;", "ALL"), ">", "&gt;", "ALL");

    // images, then links (so a link's text can be an image)
    if (Find("![", s)) s = md_links(s, refs, st, true);
    if (Find("[", s)) s = md_links(s, refs, st, false);

    s = md_emphasis(s);

    // line breaks: two or more spaces at the end of a line
    if (Find(" " & Chr(10), s)) {
        s = REReplace(s, " {2,}" & Chr(10), "<br>" & Chr(10), "ALL");
        s = REReplace(s, " +" & Chr(10), Chr(10), "ALL");
    }
    return s;
}

// s with *em*, _em_, **strong**, __strong__ and ***both*** turned into HTML
function md_emphasis(s) {
    // a character that can be next to the marker, and one that can be inside
    var a = "[^* " & Chr(5) & "]";
    var b = "[^*" & Chr(5) & "]";
    if (Find("*", s)) {
        if (Find("***", s)) s = REReplace(s, "\*\*\*(" & a & "|" & a & b & "*" & a & ")\*\*\*", "<strong><em>\1</em></strong>", "ALL");
        if (Find("**", s)) s = REReplace(s, "\*\*(" & a & "|" & a & "(" & b & "|\*" & b & ")*" & a & ")\*\*", "<strong>\1</strong>", "ALL");
        if (Find("*", s)) s = REReplace(s, "\*(" & a & "|" & a & b & "*" & a & ")\*", "<em>\1</em>", "ALL");
    }
    // _ only at the edges of words (snake_case stays as it is)
    if (Find("_", s)) {
        a = "[^_ " & Chr(5) & "]";
        b = "[^_" & Chr(5) & "]";
        if (Find("__", s)) s = REReplace(s, "(^|[^A-Za-z0-9_])__(" & a & "|" & a & "(" & b & "|_" & b & ")*" & a & ")__", "\1<strong>\2</strong>", "ALL");
        if (Find("_", s)) s = REReplace(s, "(^|[^A-Za-z0-9_])_(" & a & "|" & a & b & "*" & a & ")_", "\1<em>\2</em>", "ALL");
    }
    return s;
}

// s with its images (or links) turned into HTML; s is already escaped
function md_links(s, refs, st, images) {
    var open = "[";
    var pos = 1;
    var at = 0;
    var stop = 0;
    var label = "";
    var rest = "";
    var inner = "";
    var href = "";
    var title = "";
    var key = "";
    var used = 0;
    var found = false;
    var tok = "";
    if (images) open = "![";
    at = Find(open, s);
    while (at GT 0) {
        pos = at + 1;
        stop = Find("]", s, at + Len(open));
        if (stop EQ 0) break;
        label = md_sub(s, at + Len(open), stop - at - Len(open));
        rest = md_from(s, stop + 1);
        found = false;
        title = "";
        used = 0;
        if (Find("[", label) OR Find(Chr(5), label)) {
            // a [ in the label (or the end of the block): try again from the next one
            at = Find(open, s, at + 1);
        } else {
            if (Left(rest, 1) EQ "(" AND Find(")", rest)) {
                // [text](url) or [text](url "title")
                used = Find(")", rest);
                inner = Trim(md_sub(rest, 2, used - 2));
                if (Find(Chr(5), inner) EQ 0) {
                    found = true;
                    href = inner;
                    if (Find(" ", inner)) {
                        href = Left(inner, Find(" ", inner) - 1);
                        title = Trim(md_from(inner, Len(href) + 1));
                        found = Len(title) GE 2 AND Left(title, 1) EQ """" AND Right(title, 1) EQ """";
                        if (found) title = md_sub(title, 2, Len(title) - 2);
                    }
                    href = md_restore(href, st);
                }
            }
            if (NOT found) {
                // [text][ref], [text][] or [ref]
                used = 0;
                key = label;
                if (Left(rest, 1) EQ "[" AND Find("]", rest)) {
                    used = Find("]", rest);
                    if (used GT 2) key = Mid(rest, 2, used - 2);
                }
                key = md_key(key);
                if (StructKeyExists(refs, key)) {
                    found = true;
                    href = md_esc(refs[key].url);
                    title = md_esc(refs[key].title);
                }
            }
            if (found) {
                href = Replace(Replace(href, """", "%22", "ALL"), " ", "%20", "ALL");
                if (Len(title)) title = " title=""" & Replace(title, """", "&quot;", "ALL") & """";
                if (images) {
                    // alt is the text without its markup
                    label = Replace(REReplace(md_restore(md_emphasis(label), st), "<[^>]*>", "", "ALL"), """", "&quot;", "ALL");
                    tok = md_token(st, "<img src=""" & href & """ alt=""" & label & """" & title & ">");
                } else {
                    tok = md_token(st, "<a href=""" & href & """" & title & ">") & label & "</a>";
                }
                s = md_sub(s, 1, at - 1) & tok & md_from(rest, used + 1);
                pos = at + Len(tok);
            }
            at = 0;
            if (pos LTE Len(s)) at = Find(open, s, pos);
        }
    }
    return s;
}
</cfscript>
</cfsilent>

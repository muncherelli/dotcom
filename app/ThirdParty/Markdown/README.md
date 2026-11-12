# Markdown

A small Markdown to HTML converter for ColdFusion 5, in one file of
functions.

## Install

Copy this folder to `app/ThirdParty/Markdown` and list the file in
`app/Config/Autoload.cfm`:

```cfm
<cfset ArrayAppend(Request.autoload.files, "app/ThirdParty/Markdown/Markdown.cfm")>
```

## Use

```cfm
<cfoutput>#markdown(text)#</cfoutput>
```

It covers the core of CommonMark, simplified:

| Markdown | HTML |
| --- | --- |
| `# Title` to `###### Title`, or a line underlined with `===` / `---` | headings |
| text split by blank lines; two spaces or `\` at a line's end | paragraphs, `<br>` |
| `*em*` `_em_` `**strong**` `__strong__` `***both***` | emphasis |
| `` `code` ``, ```` ``` ```` or `~~~` fences, four-space indents | code |
| `[text](url "title")`, `[text][ref]`, `[ref]`, `<https://…>` | links |
| `![alt](src "title")`, `![alt][ref]` | images |
| `[ref]: url "title"` | link references |
| `> quote` | block quotes |
| `-` `*` `+` bullets, `1.` `1)` numbers, nested by indenting | lists |
| `---` `***` `___` | rules |
| `\` before punctuation | the character as is |

HTML in the Markdown is passed through as is, so only convert text you
trust.

Tables, strikethrough and other GitHub extras aren't supported.

## Speed

CF 5 compiles a regular expression every time one runs, and every
statement costs, so the blocks are found from each line's first
character and the inline formatting runs once over the whole document.
For pages that don't change on every request, keep the output in the
view or page cache.

## Tests

`tests/cases.txt` holds Markdown and the HTML it should become;
`tests/run.cfm` checks them all. Include it from a reachable page
(outside the framework, which has already loaded `markdown()`).

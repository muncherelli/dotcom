<cfsilent>
<!---
    Cache: settings for the page cache (cachePage(seconds) in a controller
    method) and the view cache (view("name", data, seconds)). Both keep their
    output in writable/cache.

    Any setting can be overridden in .env as cache.<name>, e.g.
        cache.handler = dummy
    (as CodeIgniter's Config classes can).

    Placeholders filled in as a page is sent, even when it comes from the
    cache: {elapsed_time} (seconds the request took), {elapsed_ms} (the same
    in milliseconds) and {client_ip}.
--->
<cfset Request.cache = StructNew()>

<!---
 | --------------------------------------------------------------------------
 | Primary Handler
 | --------------------------------------------------------------------------
 | "file" keeps pages and views in writable/cache. "dummy" keeps nothing:
 | cachePage() and the view cache do nothing (handy while developing).
--->
<cfset Request.cache.handler = "file">

<!---
 | --------------------------------------------------------------------------
 | Cache Include Query String
 | --------------------------------------------------------------------------
 | Whether the query string is part of a page's cache key. CodeIgniter leaves
 | it out by default; with it out, /blog?page=2 would get /blog's cached page,
 | so it's in here.
--->
<cfset Request.cache.cacheQueryString = true>

<!---
 | --------------------------------------------------------------------------
 | Send Cache-Control
 | --------------------------------------------------------------------------
 | Send "Cache-Control: public, max-age=<seconds left>" with cached pages, so
 | Cloudflare and browsers can keep them too.
--->
<cfset Request.cache.sendHeaders = true>

<!--- .env overrides: cache.<name> = value --->
<cfset config_from_env(Request.cache, "cache")>
</cfsilent>

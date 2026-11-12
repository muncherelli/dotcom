<cfsilent>
<!---
 | --------------------------------------------------------------------------
 | Page Cache
 | --------------------------------------------------------------------------
 | A controller method calls cachePage(seconds) to keep its finished page in
 | writable/cache; the next GET for the same address is sent from there
 | without running the routes, controller or views.
 |
 | Request.CACHE_PAGES (set in app/Config/Boot/<environment>.cfm) turns the
 | whole thing on or off; with it off, cachePage() does nothing.
--->

<!---
 | --------------------------------------------------------------------------
 | Cache Include Query String
 | --------------------------------------------------------------------------
 | Whether the query string is part of the page's cache key. CodeIgniter
 | leaves it out by default; with it out, /blog?page=2 would get /blog's
 | cached page, so it's in here.
--->
<cfparam name="Request.cacheQueryString" default="true">

<!---
 | --------------------------------------------------------------------------
 | Send Cache-Control
 | --------------------------------------------------------------------------
 | Send "Cache-Control: public, max-age=<seconds left>" with cached pages, so
 | Cloudflare and browsers can keep them too.
--->
<cfparam name="Request.cacheSendHeaders" default="true">
</cfsilent>

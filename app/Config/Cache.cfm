<cfsilent>
<!---
 | --------------------------------------------------------------------------
 | Page Cache
 | --------------------------------------------------------------------------
 | A controller method calls cachePage(seconds) to keep its finished page in
 | writable/cache; the next GET for the same address is sent from there
 | without running the routes, controller or views.
 |
 | A single view can be cached too: view("sidebar", data, 60) keeps that view's
 | output for 60 seconds (shared by every page that shows it). The third
 | argument may also be a struct with cache (seconds) and cache_name (the
 | cache key; the view's name by default).
 |
 | Placeholders filled in as the page is sent, even when it comes from the
 | cache: {elapsed_time} (seconds the request took), {elapsed_ms} (the same in
 | milliseconds) and {client_ip}.
 |
 | Request.CACHE_ENABLED (set in app/Config/Boot/<environment>.cfm) turns both
 | caches on or off; with it off, cachePage() and the view cache do nothing.
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

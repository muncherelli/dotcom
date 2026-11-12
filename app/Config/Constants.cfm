<cfsilent>
<!---
 |--------------------------------------------------------------------------
 | Timing Constants
 |--------------------------------------------------------------------------
 | Provide simple ways to work with the many ColdFusion functions and tags
 | that take a number of seconds (cfcookie, cfcache, DateAdd("s", ...)).
--->
<cfparam name="Request.SECOND" default="1">
<cfparam name="Request.MINUTE" default="60">
<cfparam name="Request.HOUR"   default="3600">
<cfparam name="Request.DAY"    default="86400">
<cfparam name="Request.WEEK"   default="604800">
<cfparam name="Request.MONTH"  default="2592000">
<cfparam name="Request.YEAR"   default="31536000">
<cfparam name="Request.DECADE" default="315360000">
</cfsilent>

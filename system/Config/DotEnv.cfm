<cfsilent>
<!---
    DotEnv: reads the project's .env file into Request.env (name -> value).

    One setting per line, NAME = value. Lines starting with # are comments.
    "export " before a name is allowed. Values may be quoted ("..." or '...');
    an unquoted value ends at " #" (a comment). ${NAME} in a value is replaced
    with an earlier setting. A missing .env is fine: Request.env is empty.
--->
<cfset Request.env = StructNew()>
<cfset envFile = Request.ROOTPATH & Replace(Request.paths.envDirectory, "/", "\", "ALL") & ".env">
<cfif FileExists(envFile)>
    <cffile action="read" file="#envFile#" variable="envText">
    <cfscript>
    envLines = ListToArray(envText, Chr(13) & Chr(10));
    for (envN = 1; envN LTE ArrayLen(envLines); envN = envN + 1) {
        envLine = Trim(envLines[envN]);
        envEq = Find("=", envLine);
        if (Left(envLine, 1) NEQ "##" AND envEq GT 1) {
            // Split our compound string into its parts
            envName = Trim(Left(envLine, envEq - 1));
            envValue = "";
            if (envEq LT Len(envLine)) envValue = Trim(Right(envLine, Len(envLine) - envEq));

            // Sanitize the name
            envName = REReplace(envName, "^export[[:space:]]+", "");
            envName = Replace(Replace(envName, "'", "", "ALL"), """", "", "ALL");

            // Sanitize the value: a quoted value is what's between the quotes,
            // an unquoted one stops at an inline comment
            envQuote = Left(envValue, 1);
            if (envQuote EQ """" OR envQuote EQ "'") {
                envClose = Find(envQuote, envValue, 2);
                if (envClose EQ 0) envClose = Len(envValue) + 1;
                if (envClose GT 2) envValue = Mid(envValue, 2, envClose - 2);
                else envValue = "";
            } else {
                envHash = Find(" ##", envValue);
                if (envHash) envValue = Trim(Left(envValue, envHash - 1));
            }

            // Resolve ${NAME} from settings above this one
            envFrom = 1;
            envRef = REFind("\$\{([A-Za-z0-9_.]+)\}", envValue, envFrom, true);
            while (envRef.pos[1] GT 0) {
                envKey = Mid(envValue, envRef.pos[2], envRef.len[2]);
                envSub = "";
                if (StructKeyExists(Request.env, envKey)) envSub = Request.env[envKey];
                // (CF 5's Left/Right won't take a count of 0)
                envBefore = "";
                if (envRef.pos[1] GT 1) envBefore = Left(envValue, envRef.pos[1] - 1);
                envAfter = "";
                envRest = Len(envValue) - (envRef.pos[1] + envRef.len[1] - 1);
                if (envRest GT 0) envAfter = Right(envValue, envRest);
                envValue = envBefore & envSub & envAfter;
                envFrom = envRef.pos[1] + Len(envSub);
                envRef = REFind("\$\{([A-Za-z0-9_.]+)\}", envValue, envFrom, true);
            }

            if (Len(envName)) Request.env[envName] = envValue;
        }
    }
    </cfscript>
</cfif>
</cfsilent>

---
description: "Register an HTTP/WebSocket API as a connection skill (key in env) — project-with-reflect"
argument-hint: "<name>  (+ its url / docs / key env-var — natural language ok)"
---
Run the **register-api** action of the `project-with-reflect` skill with arguments: $ARGUMENTS

**The user can describe the API in plain language** — its base URL, docs link, and which env var holds
the key. Extract those from `$ARGUMENTS` and ask only for what's missing; they don't type positional
args. Creates a connection under `$PROJECT_WITH_REFLECT_ROOT/connections/<name>/` (transport `http`),
installed as a skill `/<name>`. `KEY_ENV_VAR` is the **name** of the env var holding the key (e.g.
`SONIOX_API_KEY`) — a pointer; the key itself stays in env/keychain, **never on disk**. `docs_url`
(e.g. `https://soniox.com/docs`) is recorded in frontmatter for grounding — the skill fetches it
before coding against the API. After registering, write the endpoints / usage / gotchas into
`<name>.md`. Follow the skill's steps.

---
description: "Register an HTTP/WebSocket API as a connection skill (key in env) — project-with-reflect"
argument-hint: "<name> [base_url] [KEY_ENV_VAR]"
---
Run the **register-api** action of the `project-with-reflect` skill with arguments: $ARGUMENTS

Creates a connection under `$PROJECT_WITH_REFLECT_ROOT/connections/<name>/` (transport `http`),
installed as a skill `/<name>`. `KEY_ENV_VAR` is the **name** of the env var holding the key (e.g.
`SONIOX_API_KEY`) — a pointer; the key itself stays in env/keychain, **never on disk**. After
registering, write the endpoints / usage / gotchas into `<name>.md`. Follow the skill's steps.

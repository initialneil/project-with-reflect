---
description: "Register an ssh machine or provision+pay a cloud server (project-with-reflect)"
---
Run the **register-machine** action of the `project-with-reflect` skill with arguments: $ARGUMENTS

Existing host → record a key-based `~/.ssh/config` alias + `machine.json` (no passwords).
A server you don't have yet → run the guided provision-and-pay flow for whatever provider
the user names: confirm resource + cost estimate + billing, create it, open the firewall
port. You guide, the user authorizes; never hold billing creds; confirm cost first.

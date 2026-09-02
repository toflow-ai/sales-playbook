# Running the playbook in GitHub Actions

`.github/workflows/claude.yml` runs any skill or command from this repo on a
GitHub runner, with the toflow, ai-ark, and Slack MCP servers attached, and has
Claude post the result to Slack.

Trigger it from **Actions → Claude → Run workflow**, or call it from another
workflow (see [Adding a scheduled workflow](#adding-a-scheduled-workflow)).

## Why CI does not use `.mcp.json`

The repo's `.mcp.json` is for interactive use on your laptop and cannot work in
a runner:

| Server | Local | In CI |
|---|---|---|
| `toflow` | `mcp-remote`, browser OAuth | `type: http` + `Authorization: Bearer $TOFLOW_API_KEY` |
| `ai-ark` | token in the URL | same, from a secret |
| `google-calendar` | `gcal.mcp.claude.com`, a Claude.ai-hosted connector tied to your Claude login | **not available** — needs a self-hosted Google MCP with a service account |
| `slack` | — | `slack-mcp-server` over stdio with a bot token |

`.github/scripts/build-mcp-config.sh` generates the CI config from secrets, and
the workflow passes `--strict-mcp-config` so nothing else is loaded. A server
whose secret is missing is skipped rather than failing the run.

## Required secrets

Set these under **Settings → Secrets and variables → Actions**.

| Secret | Required | How to get it |
|---|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` | yes | Run `claude setup-token` locally and paste the token |
| `TOFLOW_API_KEY` | yes | toflow workspace settings → API key |
| `SLACK_MCP_XOXB_TOKEN` | yes | Slack app bot token (`xoxb-…`), see below |
| `SLACK_CHANNEL` | yes | Default channel **ID** (`C…`), not `#name` |
| `AI_ARK_TOKEN` | no | Omit to run without ai-ark |

`claude setup-token` produces long-lived credentials tied to your Claude
subscription — every scheduled run bills your quota, and the token is a static
secret in the repo. Rotate it if it leaks, and re-run `setup-token` when it
expires (roughly yearly). If this later needs to run on an org account without a
static secret, `claude-code-action` also supports OIDC workload identity
federation via `anthropic_federation_rule_id`.

### Slack app setup

1. Create a Slack app → **OAuth & Permissions** → add these bot scopes:

   | Scope | Why |
   |---|---|
   | `channels:read`, `groups:read`, `im:read`, `mpim:read` | **required to start at all** — see below |
   | `channels:history`, `groups:history` | reading messages and their reactions |
   | `chat:write` | posting |
   | `reactions:read`, `reactions:write` | triage state (✅ / ❌ / 📨) |
   | `users:read` | resolving user IDs to names |

   The four `*:read` scopes are not optional. On startup the server caches the
   channel collection with a single `conversations.list` call covering all four
   conversation types at once (`AllChanTypes` = `mpim, im, public_channel,
   private_channel`). Missing any one of them fails that call with
   `missing_scope`, and the server treats it as fatal and exits — which the
   client sees only as `slack (CONNECTION_CLOSED)`, with no mention of scopes.
   This happens even if your workflow never lists channels.
2. Install to the workspace and copy the **Bot User OAuth Token** (`xoxb-…`).
3. Invite the bot to the target channel: `/invite @yourbot`.
4. Copy the channel ID from the channel's context menu → *View channel details*.

Use the channel **ID**. `SLACK_MCP_ADD_MESSAGE_TOOL` allowlists by ID, and a
`#name` will not match it.

Note: `conversations_search_messages` does not work with bot tokens. Everything
this workflow needs — posting, history, channel and user lookup — does.

## What the agent may and may not do

Claude can read toflow data and write to the CRM: update records, and create
notes, tasks, and email drafts.

These are denied by the permission profile in `.github/claude/`, independent of
the `--allowedTools` list:

- **Outbound messages** — `send_email`, `send_whatsapp_message`,
  `send_linkedin_message`, `send_inmail`, `send_connection_request`,
  `reply_to_email`, `forward_email`, and the `start_*_conversation` tools
- **Live sequence enrollments** — `enroll_in_sequence`, `retry_enrollment`,
  `update_enrollment`, `set_enrollment_node_content`,
  `resolve_invalid_enrollments`. An enrollment is queued outbound mail, so
  editing one is a way of sending without calling a `send_*` tool
- **Sending-account config** — `set_email_signature`, `set_primary_account`,
  which change what every outgoing email looks like and who it comes from
- **Deletions** — every `delete_*`, plus `remove_from_list` and
  `remove_person_from_deal`
- **Credit-burning bulk enrichment** — `bulk_enrich_*`

`Bash` is not in the allowed tool list either.

The list was verified against `tools/list` on the live server — every denied
name exists, so none of them are silently no-ops from a typo.

This matters because these runs read notes, emails, and LinkedIn content —
text that people outside your company can influence — and then act with your
credentials. Keeping "can send" and "can delete" off the table is most of the
defense; the prompt also tells Claude to treat record content as data, never as
instructions. Widen the allowlist deliberately, not by default.

Posting is scoped to one channel per run via `SLACK_MCP_ADD_MESSAGE_TOOL`, so
an injected instruction cannot turn the bot loose on the workspace.

## Delivery

Claude posts to Slack itself, through the MCP server. Because that is a tool
call rather than a workflow step, a run could finish without posting — the
**Check the Slack post landed** step reads the execution transcript and fails
the job if `conversations_add_message` was never called.

The full report is also written to `report.md` and uploaded as a run artifact.

## The lead triage flow

Two workflows, split so that no email leaves without a human seeing it.

```
#new-leads signup
      │
      ▼  lead-triage.yml          (send_email BLOCKED)
  research → dedupe → create person/company/deal → draft email
      │
      ▼  posts one card per lead, top-level, to #sales-bot-updates
      │
      ▼  a human reacts ✅ (or ❌)
      │
      ▼  lead-send-approved.yml   (send_email PERMITTED)
  verify recipient → send → react 📨
```

Both are `workflow_dispatch` only. Add a `schedule:` to stage 1 once it has
proven itself; leave stage 2 manual.

### Why the split

Signup data is attacker-controlled — anyone can create a workspace with any
name, company, and description. Stage 1 reads that text, researches it, and
writes to the CRM, but cannot send anything. Only stage 2 can send, and it does
nothing except send drafts that stage 1 wrote and a person approved.

That is why there are two permission profiles in `.github/claude/`:

| Profile | Denies | Used by |
|---|---|---|
| `settings-default.json` | 30 tools, all sends included | everything |
| `settings-sender.json` | 29 — `send_email` permitted | `lead-send-approved.yml` only |

The sender profile permits `send_email` and nothing else. WhatsApp, LinkedIn,
InMail, deletions, and enrollment edits stay blocked: approving an email is not
approval to message someone on another channel.

### Triage state is Slack reactions

`conversations_history` returns reactions as `name:count`. ✅ means handled, ❌
rejected, 📨 (on a card) already sent.

Two constraints this design has to respect:

- **Reactions on thread replies are never returned** — `conversations_replies`
  hard-codes them empty. Anything a human reacts to must be a top-level message,
  which is why draft cards are posted individually rather than threaded.
- **Reactions are counts, not identities.** You can see that someone approved,
  never who. With a small private channel that is an acceptable trust model, but
  it is not an audit trail.

The bot token already carries `reactions:read` and `reactions:write`. The MCP
server does not register write tools unless they are named, so
`build-mcp-config.sh` sets `SLACK_MCP_ENABLED_TOOLS` explicitly.

### Prerequisite

`@salesbot` must be invited to `#new-leads` (`C0APE9SJM0E`). It is not a member
by default and cannot read the channel without it.

## Adding a scheduled workflow

`claude.yml` accepts `workflow_call`, so a scheduled job is a thin caller:

```yaml
name: Weekly pipeline review
on:
  schedule:
    - cron: "30 3 * * 1" # Mondays 09:00 IST
jobs:
  review:
    uses: ./.github/workflows/claude.yml
    secrets: inherit
    with:
      prompt: "/pipeline-review"
      slack_channel: C0123456789
      max_turns: "60"
```

`secrets: inherit` is required — a called workflow gets no secrets otherwise.
Scheduled runs only fire from the default branch.

## Troubleshooting

- **`MCP servers enabled: none`** — no server secrets are set; check secret names.
- **Claude reports no toflow tools** — `TOFLOW_API_KEY` is missing or rejected.
  `curl -i -X POST https://api.toflow.ai/mcp -H "Authorization: Bearer $KEY"`
  returning 401 means the key is bad.
- **"Claude never called conversations_add_message"** — usually the bot is not
  in the channel, or `SLACK_CHANNEL` holds a `#name` instead of an ID.
- **`slack (CONNECTION_CLOSED)` and no `mcp__slack__*` tools** — almost always a
  missing read scope, not a bad token or a bad release. The server authenticates
  successfully first, then dies caching channels. The real error never reaches
  the MCP client; reproduce the launch by hand to see it:

  ```
  SLACK_MCP_XOXB_TOKEN=xoxb-... npx -y slack-mcp-server@latest --transport stdio
  ```
- **Hit the turn limit** — raise `max_turns`; research-heavy skills need more
  than the default 40.

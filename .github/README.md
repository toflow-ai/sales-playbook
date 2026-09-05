# Running the playbook in GitHub Actions

`.github/workflows/claude.yml` runs any skill or command from this repo on a
GitHub runner, with the toflow, ai-ark, and Slack MCP servers attached, and has
Claude post the result to Slack.

Trigger it from **Actions → Claude → Run workflow**, or call it from another
workflow (see [Adding a scheduled workflow](#adding-a-scheduled-workflow)), or
from an `@salesbot` mention in Slack via n8n (see below).

## Triggering from an @salesbot mention (n8n)

Slack's Events API needs a public HTTPS endpoint, which this repo doesn't
host — that endpoint is an n8n workflow instead. The flow:

```
Slack app_mention event
      │
      ▼  n8n webhook
  strip the "<@BOTID> " prefix from event.text → prompt
      │
      ▼  n8n calls the GitHub REST API
  POST /repos/toflow-ai/sales-playbook/actions/workflows/claude.yml/dispatches
      │
      ▼  claude.yml (workflow_dispatch)
  runs the prompt, replies in the mention's thread
```

### Slack app config

- Subscribe to the `app_mention` event (Event Subscriptions → Subscribe to
  bot events), pointing at the n8n webhook URL.
- The `app_mentions:read` bot scope is required in addition to the scopes
  listed above.
- Invite `@salesbot` to any channel it should be mentionable in. This is what
  scopes it, not the n8n config — the Slack app subscribes to `app_mention`
  workspace-wide, so a channel it isn't a member of just never generates the
  event in the first place.
- E.g. in `#toflow-sales`, a plain top-level `@salesbot /pipeline-review` (or
  `/forecast`, `research <company>`, or open-ended instructions) runs under
  the default profile — read/research/draft, no sending — and replies in a
  new thread started on that mention (`thread_ts` = the mention's own `ts`,
  per the Transform step below). No special-casing needed per channel; only
  `#new-leads` gets the extra sender-profile rule, because only it has a
  drafted email to approve. Any other channel `@salesbot` is invited to
  behaves the same generic, non-sending way.

### n8n workflow

1. **Webhook node** — receives the Slack event. Slack requires the endpoint
   to echo back `challenge` on the one-time URL verification request, and to
   respond within 3 seconds on every request after that — do the GitHub call
   without making Slack wait on it (respond `200` first, or run the HTTP
   Request node without blocking the webhook response).
2. **Filter** — `event.type == "app_mention"` (Slack redelivers on retries
   and also fires `message` events in the same channel; ignore both).
3. **Transform** — build the dispatch payload:
   - `prompt`: `event.text` with the leading `<@U…> ` bot mention stripped —
     passed straight through, freeform, no keyword parsing. It reaches Claude
     labeled as Slack-sourced, untrusted input (the `thread_ts`-gated boundary
     language already in `claude.yml`'s prompt), and Claude itself decides —
     from that text plus the thread history it reads via `conversations_replies`
     — what's actually being asked, including whether a message like "send it"
     means finish sending a `/lead-triage` draft.
   - `slack_channel`: `event.channel`
   - `thread_ts`: `event.thread_ts` if present (mention was inside a thread),
     else `event.ts` (mention was top-level — reply in a new thread on it).
   - `settings_file`: this is the one security-relevant decision n8n makes,
     and it's a plain equality check, not text parsing —
     `event.channel == "C0APE9SJM0E" && event.thread_ts is present` (the raw
     Slack field, checked *before* the `thread_ts` fallback above — that
     fallback field is always populated and would make this check always
     true) → `.github/claude/settings-sender.json`, else
     `.github/claude/settings-default.json`. In other words: only a *reply
     inside an existing thread in `#new-leads`* ever runs with `send_email`
     available at all — a fresh top-level mention, or a mention in any other
     channel, never can, regardless of what the message says.
4. **HTTP Request node** — call the GitHub API:
   ```
   POST https://api.github.com/repos/toflow-ai/sales-playbook/actions/workflows/claude.yml/dispatches
   Authorization: Bearer <GitHub PAT>
   Accept: application/vnd.github+json
   Content-Type: application/json

   { "ref": "main", "inputs": { "prompt": "...", "slack_channel": "...", "thread_ts": "...", "settings_file": "..." } }
   ```
   The PAT needs `actions: write` + `contents: read` on this repo (a
   fine-grained token scoped to just `toflow-ai/sales-playbook` is enough —
   store it as an n8n credential, not inline in the workflow).

Having `settings_file` come from a channel-ID equality check rather than a
GitHub-side string match on the message means n8n can never be tricked by
message content into granting `send_email` — the only lever is which channel
and thread the mention landed in, and that's Slack's own routing, not
attacker-controlled text.

`workflow_dispatch` is fire-and-forget: the API call returns `204` with no run
ID. If you need to correlate a dispatch back to a specific Slack event, add a
`GITHUB_RUN_ID`-free correlation instead — e.g. have n8n poll
`GET /repos/.../actions/workflows/claude.yml/runs` for the next run created
after the dispatch, or skip correlation entirely and rely on the Slack thread
reply as the confirmation that it ran. The `concurrency` block in `claude.yml`
already serializes overlapping mentions so a burst of them queues instead of
racing.

## Why CI does not use `.mcp.json`

The repo's `.mcp.json` is for interactive use on your laptop and cannot work in
a runner:

| Server | Local | In CI |
|---|---|---|
| `toflow` | `mcp-remote`, browser OAuth | `type: http` + `Authorization: Bearer $TOFLOW_API_KEY` |
| `ai-ark` | token in the URL | same, from a secret |
| `posthog` | token in the header | same, from a secret |
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
| `POSTHOG_API_KEY` | no | Omit to run without PostHog (`/lead-triage`'s journey lookup skips silently) |

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
   | `channels:history`, `groups:history` | reading messages and threads |
   | `chat:write` | posting |
   | `app_mentions:read` | receiving `@salesbot` mentions |
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

Posting is scoped to the run's own destination channel plus
`#sales-bot-updates` via `SLACK_MCP_ADD_MESSAGE_TOOL` (a comma-separated
allowlist) — nowhere else, so an injected instruction cannot turn the bot
loose on the workspace.

## Delivery

Claude posts to Slack itself, through the MCP server — twice, per its
Deliverables instructions: a detailed execution log to `#sales-bot-updates`
(`C0BUL9U9CFK`) first, then a short reply at the run's actual destination
(the mention's thread, or the target channel for a manual/scheduled run)
linking back to that log via its permalink. When the destination already *is*
`#sales-bot-updates`, the one log post covers both and there's no duplicate.

There's no `report.md` artifact any more — `#sales-bot-updates` is the
execution history now, and it's readable without downloading anything from
Actions.

Because both posts are tool calls rather than workflow steps, a run could
finish without posting at all — the **Check the Slack post landed** step
reads the execution transcript and fails the job if
`conversations_add_message` was never called at least once.

## The lead triage flow

One workflow (`claude.yml`) runs both stages — what changes between them is
the prompt and the permission profile, not the workflow file.

```
#new-leads signup
      │
      ▼  claude.yml, prompt "/lead-triage", settings-default.json (send_email BLOCKED)
  research → dedupe → create person/company/deal → draft email
      │
      ▼  posts the card as a thread reply on the signup post
      │
      ▼  a human replies in that thread — "send it", or the
         literal "/lead-send-approved", either works
      │
      ▼  n8n sees channel=#new-leads + thread_ts set → dispatches
         claude.yml again, this time with settings-sender.json (send_email PERMITTED)
  Claude reads the thread, recognizes the send request, follows
  .claude/commands/lead-send-approved.md → verify recipient → send → confirm in-thread
```

Stage 1 is `workflow_dispatch` only for now (`prompt: "/lead-triage <N>"`
from the Actions tab, or a future `schedule:` caller — see [Adding a scheduled
workflow](#adding-a-scheduled-workflow)). Stage 2 only ever arrives via an
`@salesbot` mention through n8n — see [Triggering from an @salesbot
mention](#triggering-from-an-salesbot-mention-n8n) — there is no manual
Actions-tab entry point for it any more, since it needs a specific thread to
act on.

### Why the permission split still exists

Signup data is attacker-controlled — anyone can create a workspace with any
name, company, and description. `/lead-triage` reads that text, researches it,
and writes to the CRM, but the run it's in never has `send_email` available.
Sending only ever happens in a run where n8n decided, from the Slack event's
channel and thread alone (not from message content), to grant it.

That is why there are two permission profiles in `.github/claude/`:

| Profile | Denies | Granted when (per n8n's rule, see above) |
|---|---|---|
| `settings-default.json` | 30 tools, all sends included | everything except the row below |
| `settings-sender.json` | 29 — `send_email` permitted | mention is a reply inside an existing `#new-leads` thread |

The sender profile permits `send_email` and nothing else. WhatsApp, LinkedIn,
InMail, deletions, and enrollment edits stay blocked regardless of profile:
being allowed to send an email is not being allowed to message someone on
another channel.

### Triage state lives in toflow and thread text, not Slack reactions

There used to be a ✅/❌/📨 reaction scheme for tracking triage and approval
state. It's gone — reactions are anonymous (you can see *that* someone
reacted, never *who*), which made for a weak audit trail, and it meant
`/lead-send-approved` had to batch-scan the whole channel looking for
approved-but-unsent drafts.

The replacement is simpler and ties directly to identity:

- **"Already triaged"** is answered by toflow, not Slack: `/lead-triage`
  checks whether a person + deal already exist for the signup (Step 2) and
  skips if so. Re-scanning the same signup post on a later run is harmless.
- **"Approved to send"** is a named human replying inside that lead's own
  thread asking for the draft to be sent — "send it" and the literal
  `/lead-send-approved` both work, since Claude reads the thread and decides
  intent itself (see [Triggering from an @salesbot
  mention](#triggering-from-an-salesbot-mention-n8n)). There is nothing to scan
  for in advance; the mention itself carries the thread to act on, and n8n's
  channel+thread check is what makes `send_email` available for that run at all.
- **"Already sent"** is answered by reading the thread: `/lead-send-approved`
  looks for its own prior `Sent to <email> at <time>` reply before sending
  again.

This means `SLACK_MCP_ENABLED_TOOLS` no longer needs `reactions_add`, and the
bot token doesn't need `reactions:read`/`reactions:write` for this flow at all.

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

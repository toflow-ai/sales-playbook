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

1. Create a Slack app → **OAuth & Permissions** → add bot scopes:
   `chat:write`, `channels:read`, `channels:history`, `users:read`.
   Add `groups:read` and `groups:history` for private channels.
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

These are denied in the workflow's `settings` block, independent of the
`--allowedTools` list:

- **Outbound messages** — `send_email`, `send_whatsapp_message`,
  `send_linkedin_message`, `send_inmail`, `send_connection_request`,
  `reply_to_email`, `forward_email`, and the `start_*_conversation` tools
- **Sequence enrollment** — `enroll_in_sequence`, `retry_enrollment`
- **Deletions** — every `delete_*`, plus `remove_from_list` and
  `remove_person_from_deal`
- **Credit-burning bulk enrichment** — `bulk_enrich_*`

`Bash` is not in the allowed tool list either.

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
- **Hit the turn limit** — raise `max_turns`; research-heavy skills need more
  than the default 40.

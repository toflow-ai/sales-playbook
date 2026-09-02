#!/usr/bin/env bash
# Renders the MCP server config used inside the GitHub runner.
#
# The repo's .mcp.json is built for interactive laptop use: toflow goes through
# `mcp-remote`, which opens a browser OAuth flow, and google-calendar points at
# a Claude.ai-hosted connector tied to a logged-in Claude account. Neither can
# authenticate headlessly, so CI talks to the same services over plain HTTP
# with static tokens instead. The workflow passes --strict-mcp-config so only
# what this script emits is loaded.
#
# Servers whose secret is absent are omitted, so a workflow only gets the
# integrations that are actually configured.
set -euo pipefail

OUT="${1:?usage: build-mcp-config.sh <output-path>}"

servers='{}'

add() { # add <name> <json>
  servers="$(jq -c --arg n "$1" --argjson s "$2" '. + {($n): $s}' <<<"$servers")"
}

if [[ -n "${TOFLOW_API_KEY:-}" ]]; then
  add toflow "$(jq -n --arg t "$TOFLOW_API_KEY" '{
    type: "http",
    url: "https://api.toflow.ai/mcp",
    headers: { Authorization: ("Bearer " + $t) }
  }')"
fi

if [[ -n "${AI_ARK_TOKEN:-}" ]]; then
  add ai-ark "$(jq -n --arg t "$AI_ARK_TOKEN" '{
    type: "http",
    url: ("https://api.ai-ark.com/v1/mcp?token=" + $t)
  }')"
fi

if [[ -n "${SLACK_MCP_XOXB_TOKEN:-}" ]]; then
  # Posting is disabled unless SLACK_MCP_ADD_MESSAGE_TOOL is set. We scope it to
  # the run's target channel rather than `true`, so a prompt injection carried in
  # CRM content can't reach the rest of the workspace. Channel IDs only (C…) —
  # the allowlist does not match #names.
  # Write tools are unregistered unless named in SLACK_MCP_ENABLED_TOOLS.
  # reactions_add is needed to mark a lead handled; channels_list is omitted
  # because the bot token lacks channels:read, and conversations_search_messages
  # does not work with bot tokens at all.
  enabled="conversations_history,conversations_replies,conversations_add_message,reactions_add,users_search"
  add slack "$(jq -n \
      --arg t "$SLACK_MCP_XOXB_TOKEN" \
      --arg c "${SLACK_MCP_ADD_MESSAGE_TOOL:-}" \
      --arg e "$enabled" '{
    command: "npx",
    args: ["-y", "slack-mcp-server@latest", "--transport", "stdio"],
    env: ({ SLACK_MCP_XOXB_TOKEN: $t, SLACK_MCP_ENABLED_TOOLS: $e }
          + (if $c == "" then {} else { SLACK_MCP_ADD_MESSAGE_TOOL: $c } end))
  }')"
fi

jq -n --argjson s "$servers" '{mcpServers: $s}' > "$OUT"

echo "MCP servers enabled: $(jq -r 'if (.mcpServers | length) == 0 then "none"
  else (.mcpServers | keys | join(", ")) end' "$OUT")"

if [[ -n "${SLACK_MCP_XOXB_TOKEN:-}" && -z "${SLACK_MCP_ADD_MESSAGE_TOOL:-}" ]]; then
  echo "::warning::Slack MCP is loaded but no channel allowlist was set — Claude will not be able to post."
fi

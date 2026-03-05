# Slack App Setup for NanoClaw

## Fast path (3 steps)

### 1. Create the app from the manifest

1. Go to [api.slack.com/apps](https://api.slack.com/apps) → **Create New App** → **From a manifest**
2. Select your workspace, click **Next**
3. Paste the contents of [`slack-app-manifest.json`](../../../../slack-app-manifest.json) (in the project root), click **Next** → **Create**

This auto-configures all scopes, events, and Socket Mode in one shot.

### 2. Generate the App-Level Token

1. In your new app, go to **Basic Information** → scroll to **App-Level Tokens**
2. Click **Generate Token and Scopes**
3. Name it anything (e.g. `nanoclaw`), add the `connections:write` scope, click **Generate**
4. Copy the token — it starts with `xapp-`

### 3. Install and run the setup script

1. In the sidebar click **Install App** → **Install to Workspace** → **Allow**
2. Copy the **Bot User OAuth Token** (starts with `xoxb-`)
3. Back in your terminal:

```bash
npx tsx scripts/setup-slack.ts
```

Paste both tokens when prompted. Done — tokens are written to `.env` and synced automatically.

---

## Adding the bot to a channel

The bot only receives messages from channels it has been added to:

1. Open the channel in Slack
2. Click the channel name → **Integrations** → **Add apps** → search for your bot

## Getting the channel ID for registration

- **From the URL:** `https://app.slack.com/client/TXXXXXXX/C0123456789` — the `C...` part is the ID
- **Right-click the channel** → **Copy link** — ID is the last path segment
- **Via API:** `curl -s -H "Authorization: Bearer $SLACK_BOT_TOKEN" "https://slack.com/api/conversations.list" | jq '.channels[] | {id, name}'`

NanoClaw JID format: `slack:C0123456789`

## Token reference

| Token | Prefix | Location |
|-------|--------|----------|
| Bot User OAuth Token | `xoxb-` | **Install App** → **Bot User OAuth Token** |
| App-Level Token | `xapp-` | **Basic Information** → **App-Level Tokens** |

## Troubleshooting

**Bot not receiving messages**
- Verify Socket Mode is enabled (manifest sets this automatically)
- Verify the bot has been added to the channel
- Check `SLACK_BOT_TOKEN` and `SLACK_APP_TOKEN` are in `.env` AND in `data/env/env`

**"missing_scope" errors**
- Add the missing scope in **OAuth & Permissions**
- Reinstall the app to your workspace (Slack will show a banner)
- Re-run `npx tsx scripts/setup-slack.ts` with the new token

**Token not working**
- Bot tokens start with `xoxb-`, app tokens with `xapp-`
- If you regenerated a token, re-run `npx tsx scripts/setup-slack.ts`

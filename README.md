# ReasonLayer Agent

An AI assistant that runs Claude agents in isolated Docker containers and connects to your team via Slack. Deploy on any Linux server in minutes.

---

## How it works

When someone messages the bot in Slack, the message goes into a queue. A polling loop picks it up and spawns a Claude agent inside a Docker container. The agent has access to tools, can call APIs, write files, and do real work — then sends the response back to Slack. Each Slack channel gets its own isolated container with its own memory and filesystem so groups can't see each other's context.

```
Slack message → SQLite queue → Polling loop → Claude agent container → Response → Slack
```

The app itself also runs in Docker (via `docker compose`), so the only thing you need on the host is Docker.

---

## Prerequisites

- Docker and Docker Compose — verify with `docker compose version`
- An [Anthropic API key](https://console.anthropic.com/)
- A Slack workspace where you can install apps

---

## Setup

### 1. Clone the repo

```bash
git clone <your-repo-url>
cd reasonlayer-agent
```

### 2. Create your `.env` file

```bash
cp .env.example .env
```

Open `.env` and fill in:

```env
ANTHROPIC_API_KEY=your-key-here
SLACK_BOT_TOKEN=xoxb-...
SLACK_APP_TOKEN=xapp-...
ASSISTANT_NAME=Andy
```

Getting the Slack tokens is covered in the next section.

### 3. Build the agent image

```bash
./container/build.sh
```

This builds the Docker image that Claude agents run inside. Only needed once, and again after you pull updates.

### 4. Start

```bash
docker compose up -d
```

Check it's running:

```bash
docker compose logs -f
```

---

## Slack Setup

You need to create a Slack app. The `slack-app-manifest.json` file in this repo pre-configures everything — scopes, events, socket mode — so you don't have to click through the settings manually.

### Create the app

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Click **Create New App** → **From a manifest**
3. Select your workspace → **Next**
4. Paste the entire contents of `slack-app-manifest.json` → **Next** → **Create**

### Get your App-Level Token (`xapp-...`)

1. In your new app, go to **Basic Information** → scroll down to **App-Level Tokens**
2. Click **Generate Token and Scopes**
3. Give it a name (anything), add the `connections:write` scope, click **Generate**
4. Copy the token — it starts with `xapp-`

### Get your Bot Token (`xoxb-...`)

1. In the sidebar, click **Install App** → **Install to Workspace** → **Allow**
2. Copy the **Bot User OAuth Token** — it starts with `xoxb-`

Add both tokens to `.env`, then:

```bash
docker compose restart
```

### Add the bot to a channel

In Slack, open the channel you want the bot to join → click the channel name at the top → **Integrations** → **Add apps** → search for your bot name and add it.

### Register the channel

Get the channel ID from the Slack URL:
```
https://app.slack.com/client/T.../C0123456789
                                  ^^^^^^^^^^^ this part
```

Then send this in your main/admin channel:

```
@Andy join #your-channel-name slack:C0123456789
```

---

## Configuration

All config lives in `.env`. Restart after changes: `docker compose restart`

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ANTHROPIC_API_KEY` | Yes | — | Anthropic API key |
| `SLACK_BOT_TOKEN` | Yes | — | Slack bot token (`xoxb-...`) |
| `SLACK_APP_TOKEN` | Yes | — | Slack app-level token (`xapp-...`) |
| `ASSISTANT_NAME` | No | `Andy` | The trigger word — messages must start with `@Andy` |
| `CONTAINER_TIMEOUT` | No | `1800000` | Max agent run time in milliseconds |
| `MAX_CONCURRENT_CONTAINERS` | No | `5` | Max number of agents running in parallel |
| `TZ` | No | `UTC` | Timezone for scheduled tasks |

---

## Managing the service

```bash
docker compose up -d          # Start
docker compose down           # Stop
docker compose restart        # Restart (after .env changes)
docker compose logs -f        # Tail logs
```

After pulling updates:

```bash
docker compose down
./container/build.sh
docker compose up -d
```

---

## Architecture

**Single process.** One Node.js app handles everything: receiving messages from Slack, queuing them in SQLite, dispatching agents, and sending responses back.

**Isolated agents.** Each Claude agent runs in its own Docker container. It can only see directories explicitly mounted into it — its group folder, its memory, its IPC channel. It cannot touch other groups, the host filesystem, or your credentials.

**Per-group memory.** Each Slack channel (group) has its own `CLAUDE.md` file and working directory that persist between conversations. The agent remembers context, preferences, and ongoing tasks.

**IPC via filesystem.** The host process and agent containers communicate through mounted directories. The agent writes results to a file, the host picks them up. No network, no ports, no service discovery.

**Docker-outside-of-Docker.** The ReasonLayer Agent app itself runs in Docker. It spawns agent containers by connecting to the host Docker socket (`/var/run/docker.sock`). The host just needs Docker — no Node.js, no build tools.

**Scheduled tasks.** Agents can create recurring tasks (cron-style) that run automatically and message you back with results.

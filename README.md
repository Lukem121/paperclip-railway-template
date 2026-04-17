# Paperclip Railway Template

One-click deploy of [Paperclip](https://github.com/paperclipai/paperclip) on [Railway](https://railway.com)—no SSH, no scraping logs. You get an app + Postgres + a **setup page** where you generate your first admin invite in one click.

## What you get

- **Paperclip** — the app (built from a pinned upstream release via this repo’s Dockerfile).
- **Postgres** — a Railway Postgres service; the app uses it for auth and data.
- **Setup UI** at `/setup` — a small page that lets you **generate your first admin invite URL** so you can create the initial admin account. No CLI, no config files.

After you create that admin, you use Paperclip at `/` as usual (login, agents, etc.).

## Deploy

1. Click the button below (or use the template URL). Railway will create a new project from this template.
2. In the template editor, **leave the suggested env vars as-is** (see [Required variables](#required-variables) if you need to edit them).
3. Ensure the **Paperclip** service has:
   - **HTTP proxy** on port `3100`
   - **Healthcheck path** `/setup/healthz`
   - A **volume** mounted at `/paperclip` (for app data)
4. Deploy. Once the service is live, open your app URL and go to **`/setup`**.

**Template URL:**

```
https://railway.com/deploy/KJZc89?referralCode=uXzB-u&utm_medium=integration&utm_source=template&utm_campaign=paperclip
```

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/KJZc89?referralCode=uXzB-u&utm_medium=integration&utm_source=template&utm_campaign=paperclip)

## What to do after deploy

1. Open your app’s public URL (e.g. `https://your-app.up.railway.app`).
2. Go to **`/setup`** (e.g. `https://your-app.up.railway.app/setup`).
3. (Optional) If you want AI agents immediately, complete Step 1 on setup:
   - set `OPENAI_API_KEY` and/or `ANTHROPIC_API_KEY` in Railway variables
   - run Codex login from setup (Claude uses `ANTHROPIC_API_KEY` directly)
4. Click **“Generate admin invite URL”**. The page will show a one-time invite link.
5. Open that link in your browser and complete sign-up. That account is the first admin.
6. From then on, use the app at **`/`** — log in with that admin (or with users you invite later).

You only need the setup page once to bootstrap the first admin. Don’t share `/setup` publicly if you don’t want others generating invite links.

## Required variables

Set these on the **Paperclip** service in Railway (template editor or service Variables). The template may prefill some; adjust if your setup differs.

| Variable | What to set | Why |
|----------|-------------|-----|
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | Links Paperclip to the Postgres service. Use the Postgres reference variable so Railway injects the URL. |
| `BETTER_AUTH_SECRET` | e.g. `${{secret(64, "abcdef0123456789")}}` or a long random string | Secret for auth cookies/sessions. Must be at least 32 characters. |
| `HOST` | `0.0.0.0` | Bind inside the container so Railway’s proxy can reach the app. |
| `PORT` | `3100` | Port the app listens on (must match the proxy). |
| `SERVE_UI` | `true` | Serve the web UI. |
| `PAPERCLIP_HOME` | `/paperclip` | Data directory; must match the volume mount path. |
| `PAPERCLIP_DEPLOYMENT_MODE` | `authenticated` | Require login (recommended). |
| `PAPERCLIP_DEPLOYMENT_EXPOSURE` | `private` | Treat the app as private (recommended). |
| `PAPERCLIP_PUBLIC_URL` | `https://${{Paperclip.RAILWAY_PUBLIC_DOMAIN}}` | Public URL of the app (no trailing slash). Railway’s public domain for this service. |
| `BETTER_AUTH_BASE_URL` | `https://${{Paperclip.RAILWAY_PUBLIC_DOMAIN}}` | Same as above; auth callbacks use this. |

Optional (for AI agents):

- **`OPENAI_API_KEY`** — If set, the wrapper runs Codex login at startup so agents using the Codex adapter work. You can also run Codex login from the setup page. Without it, the app and dashboard work; agents that use Codex will fail until the key is set and login is run.

- **`ANTHROPIC_API_KEY`** — Used by the Claude adapter. Optional; add when you want Claude-based agents.

## Networking and storage (Railway)

- **HTTP proxy:** Enable a public domain for the Paperclip service and set the port to **3100**.
- **Healthcheck:** Set path to **`/setup/healthz`**. Railway uses this to know when the app is ready.
- **Volume:** Add a volume and mount it at **`/paperclip`**. The app stores data here; without it, data is lost on redeploy.

## How this template works

- The **Dockerfile** builds a pinned upstream Paperclip release (`PAPERCLIP_REF` in the Dockerfile; overridable at **build** time via the same-named Railway variable or `docker build --build-arg`). It does **not** use a Docker `VOLUME` (Railway handles persistence via its volume at `/paperclip`).
- At runtime, a small **wrapper server** runs: it starts Paperclip on an internal port, proxies requests to it, and serves the **setup UI** at `/setup` (and health at `/setup/healthz`). So you never need to run CLI bootstrap or read logs to get an invite link.

## Updating the upstream Paperclip version

The image is pinned to a specific Paperclip release. To bump to a newer upstream tag:

```bash
GITHUB_TOKEN=... node scripts/bump-paperclip-ref.mjs
```

Then rebuild and redeploy.

### Pin a different Paperclip release (no fork)

Paperclip is **cloned while the Docker image is built**, not at container start. Overriding the version is **build-time only**: set the variable, then trigger a **new build** (redeploy).

| Where | What to do |
|-------|------------|
| **Railway** | Add a service variable **`PAPERCLIP_REF`** with a valid tag or branch from [paperclipai/paperclip](https://github.com/paperclipai/paperclip) (often the same value as the default `PAPERCLIP_REF` in this repo’s `Dockerfile`). Railway passes service variables into the build when the Dockerfile declares matching `ARG` lines; see [Using variables at build time](https://docs.railway.com/guides/dockerfiles#using-variables-at-build-time). |
| **Local `docker build`** | `docker build --build-arg PAPERCLIP_REF=v2026.416.0 -t paperclip-railway-template .` |

If you omit `PAPERCLIP_REF`, the default in the Dockerfile is used.

## Local test (developers)

From the repo root, after building the image:

```bash
docker network create paperclip_net
docker run --rm -d --name paperclip_pg --network paperclip_net \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=paperclip \
  postgres:16
# Wait a few seconds for Postgres to be ready, then:
docker run --rm -d --name paperclip_app --network paperclip_net -p 3100:3100 \
  -e DATABASE_URL=postgresql://postgres:postgres@paperclip_pg:5432/paperclip \
  -e HOST=0.0.0.0 -e PORT=3100 -e SERVE_UI=true \
  -e PAPERCLIP_HOME=/paperclip \
  -e PAPERCLIP_DEPLOYMENT_MODE=authenticated -e PAPERCLIP_DEPLOYMENT_EXPOSURE=private \
  -e PAPERCLIP_PUBLIC_URL=http://localhost:3100 -e BETTER_AUTH_BASE_URL=http://localhost:3100 \
  -e BETTER_AUTH_SECRET=local-dev-secret-32chars-min \
  -v paperclip_local_data:/paperclip \
  paperclip-railway-template
```

Open `http://localhost:3100/setup` and use “Generate admin invite URL” to test. Stop with:

```bash
docker stop paperclip_app paperclip_pg
```

## Support

- **This template / deploy issues:** [this repo’s Issues](https://github.com/Lukem121/paperclip-railway-template/issues).
- **Paperclip app bugs and features:** [paperclipai/paperclip Issues](https://github.com/paperclipai/paperclip/issues).

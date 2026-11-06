<div align="center">

<img src="../assets/icons-phosphor/network.svg" width="56" height="56" alt="">

# Alfred-NIM through free-claude-code

### Claude Code on NVIDIA NIM, through a proxy on this Mac

*Two Terminal tabs: the proxy in one, Claude in the other. Why each variable is there, how to stop it, how to tell it is up.*

![Kind](https://img.shields.io/badge/Kind-Start--up_procedure-800020?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--06-5c1a2b?style=flat-square)
![Lane](https://img.shields.io/badge/Lane-Alfred--NIM-64748b?style=flat-square)

<img src="../assets/icons-phosphor/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](../README.md) › [`startup/`](README.md) › `ALFRED-NIM-FREE-CLAUDE-CODE.md` · public · `main` is the working branch

</div>

## <img src="../assets/icons-phosphor/list-checks.svg" width="24" height="24" alt=""> Copy, paste

**Tab 1, the proxy (leave it running):**

```sh
cd ~/code-forked/free-claude-code
uv run uvicorn server:app --host 127.0.0.1 --port 8082
```

**Tab 2, Claude (in the repository you are working on, not a parent folder):**

```sh
cd ~/code/<repo>
curl -s http://localhost:8082/health          # {"status":"healthy"} means the proxy is up
CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1 ANTHROPIC_AUTH_TOKEN="freecc" ANTHROPIC_BASE_URL="http://localhost:8082" claude
```

Then `/model` in Claude lists the proxy's models (`anthropic/nvidia_nim/z-ai/glm4.7` and the rest). **Stop:** `/exit` in tab 2, then Ctrl-C in tab 1.

`freecc` is the proxy's documented default token (its `README.md` and `.env.example`). If you changed `ANTHROPIC_AUTH_TOKEN` in the proxy's `.env`, use your value instead, in both places it appears on this page.

## <img src="../assets/icons-phosphor/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="../assets/icons-phosphor/network.svg" width="16" height="16" alt=""> **The proxy speaks Anthropic to Claude Code and OpenAI-style chat to NVIDIA NIM.** It keeps the NIM key; Claude Code only ever sees `localhost:8082`.
2. <img src="../assets/icons-phosphor/key-round.svg" width="16" height="16" alt=""> **`ANTHROPIC_AUTH_TOKEN` is required now.** Without it Claude Code sends your claude.ai login to the proxy, the proxy compares it with its own token, and answers 401. That is why the bare `ANTHROPIC_BASE_URL=... claude` line stopped working.
3. <img src="../assets/icons-phosphor/scan-search.svg" width="16" height="16" alt=""> **`CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1` fills the `/model` picker** from the proxy. It is off by default in Claude Code.
4. <img src="../assets/icons-phosphor/footprints.svg" width="16" height="16" alt=""> **`source .venv/bin/activate` is not needed** when you start with `uv run`. It is only for running `uvicorn`, `python` or `pytest` bare.
5. <img src="../assets/icons-phosphor/triangle-alert.svg" width="16" height="16" alt=""> **The logs pile up in the repository folder:** 146 rotated `server.*.log` files, about 6.8 GB, on Nov 6. Move them out; the commands are below.

## <img src="../assets/icons-phosphor/notebook-pen.svg" width="24" height="24" alt=""> The old Reminders note, line by line

| The line you kept | What it is now |
|---|---|
| `uv run uvicorn server:app --host 0.0.0.0 --port 8082` | **Right, with one change.** Starts the proxy (tab 1); use `--host 127.0.0.1` so only this Mac can reach it (see *Who can reach the proxy*) |
| `ANTHROPIC_BASE_URL=http://localhost:8082 claude` | **Stopped working, for a reason.** The proxy now asks for a token this line does not send. See *Why the bare line stopped working* |
| `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1 ANTHROPIC_AUTH_TOKEN="freecc" ANTHROPIC_BASE_URL="http://localhost:8082" claude` | **The one to use.** Tab 2 |
| `source ~/code-forked/free-claude-code/.venv/bin/activate` | **Not needed with `uv run`.** It puts the project's own Python and `uvicorn` first on your `PATH`. See *The virtual environment* |

## <img src="../assets/icons-phosphor/key-round.svg" width="24" height="24" alt=""> Why the bare line stopped working

What the code and the docs show, read Nov 6, 2026:

1. **The proxy checks a token on every model route.** `api/dependencies.py`, `require_api_key`: when the proxy's `ANTHROPIC_AUTH_TOKEN` is set, a request must carry the same value in `x-api-key`, `Authorization: Bearer …` or `anthropic-auth-token`, or it gets `401 Missing API key` or `401 Invalid API key`. When the setting is empty, the check is skipped. It guards `/v1/messages`, `/v1/messages/count_tokens`, `/v1/models`, `/` and `/stop`; only `/health` is open.
2. **The default became `freecc`.** Upstream changed `.env.example` from `ANTHROPIC_AUTH_TOKEN=` (empty) to `ANTHROPIC_AUTH_TOKEN="freecc"` on Apr 28, 2026 (commit `0294e04`). This copy was taken from a clone on May 5, after that, and the setup step is `cp .env.example .env`. Optional authentication itself arrived on Mar 27 (`f703a0e`).
3. **Without the token, Claude Code sends your claude.ai login.** The Claude Code docs ([LLM gateways](https://code.claude.com/docs/en/llm-gateway), *Subscriptions and gateways*): setting only `ANTHROPIC_BASE_URL` "doesn't replace the subscription… a saved claude.ai login remains the active credential". So the proxy receives your claude.ai credential, which is not its token, and refuses it.

So the bare line fails whenever the proxy's `.env` sets a token. That it does here is the likely story (the default changed, and the fuller line works), but this page was written without opening `.env`, which holds the NIM key. **To tell for certain**, with the proxy running:

```sh
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8082/v1/models                       # 401: a token is set
curl -s -o /dev/null -w '%{http_code}\n' -H 'x-api-key: freecc' http://localhost:8082/v1/models  # 200: and it is freecc
```

**Where the token is set.** The proxy reads, in order, each later one winning: `~/.config/free-claude-code/.env`, then `.env` in the folder you start it from, then the file named by `FCC_ENV_FILE` if you set one (`config/settings.py`). A value exported in the proxy's own shell counts only when no `.env` sets one: any `.env` value wins over the shell (`prefer_dotenv_anthropic_auth_token` in `config/settings.py`), and a shell-only token makes the proxy print a startup warning. Change it in `.env` yourself, then use the same value in tab 2.

The proxy does no more with the token than compare it. It is a lock on the door to your NIM key, not the key itself.

## <img src="../assets/icons-phosphor/scan-search.svg" width="24" height="24" alt=""> What `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1` does

From the Claude Code docs ([gateway compatibility guide](https://code.claude.com/docs/en/llm-gateway-protocol), *Model discovery*):

- At start-up, Claude Code asks the gateway for `GET /v1/models?limit=1000` (3 seconds, no redirects) and adds what comes back to the `/model` picker. **It is off unless this variable is `1`.**
- It keeps only IDs containing `claude` or `anthropic`. The proxy names its models to pass that filter (`api/gateway_model_ids.py`): `anthropic/nvidia_nim/z-ai/glm4.7`, and a `claude-3-freecc-no-thinking/...` twin of each for models that fail with thinking turned on. The proxy decodes the name back to the real NIM model.
- It sends the credential with the request, so **it also needs `ANTHROPIC_AUTH_TOKEN`**; with no credential, discovery is skipped.
- The list is cached in `~/.claude/cache/gateway-models.json` and refreshed at each start. If the proxy is down, the picker falls back to that cache or to the built-in list.
- Nothing listed? Start `claude --debug` with the same variables and look for `[gatewayDiscovery]` lines.

**Without the variable** Claude Code still works through the proxy: it sends its usual model names, and the proxy maps them to `MODEL_OPUS`, `MODEL_SONNET`, `MODEL_HAIKU` or the fallback `MODEL` from `.env`. You only lose the picker. The proxy's `README.md` says Claude Code 2.1.126 or later reads `/v1/models` on its own; today's docs say the switch is needed, and this Mac runs 2.1.319.

## <img src="../assets/icons-phosphor/footprints.svg" width="24" height="24" alt=""> The virtual environment: what `source .venv/bin/activate` was for

The project keeps its own Python 3.14 and packages in `~/code-forked/free-claude-code/.venv`. `source .venv/bin/activate` puts that folder's `bin/` first on the tab's `PATH`, so `python`, `uvicorn`, `pytest`, `free-claude-code` and `fcc-init` come from the project. `deactivate` undoes it.

- **With `uv run` it is not needed.** `uv run` finds `.venv` in the project folder by itself, brings it up to date with `pyproject.toml`, and runs the command inside it. The project's `AGENTS.md` asks for `uv run` every time.
- **It is still needed** when you type a command bare in that tab: `uvicorn server:app ...`, `python ...`, `pytest`, or the installed `free-claude-code`. Without it, those either are not found or come from another Python.
- **Never needed in tab 2.** Claude Code is not a Python program.

## <img src="../assets/icons-phosphor/circle-check.svg" width="24" height="24" alt=""> Check it is up

```sh
curl -s http://localhost:8082/health                                  # {"status":"healthy"}  (no token needed)
curl -s -H 'x-api-key: freecc' http://localhost:8082/                 # status, provider and fallback model
curl -s -H 'x-api-key: freecc' http://localhost:8082/v1/models | head -c 400   # what /model will list
lsof -nP -iTCP:8082 -sTCP:LISTEN                                      # which process holds the port
```

`curl: (7) Failed to connect` means nothing is listening: start tab 1. In Claude, `/status` shows the base URL in use.

## <img src="../assets/icons-phosphor/loader-circle.svg" width="24" height="24" alt=""> Stop it

- **Claude (tab 2):** `/exit`, or Ctrl-C twice.
- **The proxy (tab 1):** Ctrl-C. It shuts down its provider connections and exits.
- **Tab 1 closed, port still held:** `lsof -nP -iTCP:8082 -sTCP:LISTEN` names the process; `kill <PID>` stops it.

## <img src="../assets/icons-phosphor/files.svg" width="24" height="24" alt=""> The log files piling up

Where they come from (`config/logging_config.py`, `config/settings.py`): the proxy writes JSON lines at DEBUG level to `server.log`, a path relative to the folder you start it in. Each fresh start empties `server.log`. At 50 MB the log library rotates it to `server.<date>_<time>.log` and starts a new one, and **no retention is set**, so the rotated files are never cleaned up. On Nov 6 there were 146 of them, May 5 to Aug 10, about 6.8 GB, beside the code.

Two more reasons to move them: the fork's `.gitignore` lists `server.log` but not `server.*.log`, so `git status` shows 146 untracked files and a careless `git add -A` would stage them; and the copy is public on GitHub. Even with raw logging off (the default), debug logs describe your sessions.

**Delete nothing: move them.** Run these yourself:

```sh
mkdir -p ~/Archive/free-claude-code-logs && mv -n ~/code-forked/free-claude-code/server.2026-*.log ~/Archive/free-claude-code-logs/
mkdir -p ~/Library/Logs/free-claude-code      # then start tab 1 with LOG_FILE set (below), or put LOG_FILE= in .env
LOG_FILE="$HOME/Library/Logs/free-claude-code/server.log" uv run uvicorn server:app --host 127.0.0.1 --port 8082
printf '%s\n' 'server.*.log' >> ~/code-forked/free-claude-code/.gitignore   # then commit it in that repository
```

`mv -n` never overwrites. `LOG_FILE` is the environment name of the `log_file` setting; make the folder first, because the proxy writes the file before it starts logging. Rotated files then land in `~/Library/Logs/free-claude-code/`, out of the repository, where Console.app can read them. They still pile up there; move them to the archive now and then.

## <img src="../assets/icons-phosphor/shield-check.svg" width="24" height="24" alt=""> Safer, if only this Mac uses it

**Who can reach the proxy.** Every command on this page uses `--host 127.0.0.1`: only this Mac can reach the proxy, and `localhost:8082` in tab 2 works unchanged. The old note's `--host 0.0.0.0` listens on every network this Mac joins, and `freecc` is a published default, so anyone on the same Wi-Fi could spend your NIM quota. Use `0.0.0.0` only when another machine of yours must reach the proxy, and then set your own token in `.env` first.

## <img src="../assets/icons-phosphor/wrench.svg" width="24" height="24" alt=""> Two optional aliases

To type `fcc-server` in tab 1 and `claude-nim` in tab 2, append these to `~/.zshrc` yourself (a helper never edits it), then open new tabs:

```sh
printf '%s\n' '# >>> alfred-nim aliases' "alias fcc-server='cd ~/code-forked/free-claude-code && uv run uvicorn server:app --host 127.0.0.1 --port 8082'" "alias claude-nim='CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1 ANTHROPIC_AUTH_TOKEN=\"freecc\" ANTHROPIC_BASE_URL=\"http://localhost:8082\" claude'" '# <<< alfred-nim aliases' >> ~/.zshrc
```

`claude-nim` ends in `claude`, so the parent-folder guard still applies: run it inside a repository, or add `--here` ([Start a Claude session](CLAUDE-SESSION-START.md)).

## <img src="../assets/icons-phosphor/git-branch.svg" width="24" height="24" alt=""> Commits from this lane

A commit made in a Claude session that runs through the proxy names the gateway and the model maker, not Anthropic:

```
Co-Authored-By: Alfred-NIM · ClaudeCodeCLI · NVIDIA NIM · Z.ai [GLM-4.7]
```

Read the `/model` string left to right: `anthropic/nvidia_nim/z-ai/glm4.7` is NVIDIA NIM (the gateway), then Z.ai (who made GLM-4.7). Kimi is `Moonshot AI`, MiniMax is `MiniMaxAI`. The proxy lane is Alfred's alone. The session line and the full field table: [the attribution spec](https://github.com/drasticstatic/my-template/blob/main/AGENT-SYNC/README.md), the single source.

## <img src="../assets/icons-phosphor/history.svg" width="24" height="24" alt=""> Change log

| Date | Change |
|---|---|
| 2026-11-06 | First version, from the proxy's `README.md`, `AGENTS.md`, `pyproject.toml`, `api/dependencies.py`, `api/routes.py`, `api/gateway_model_ids.py`, `config/settings.py`, `config/logging_config.py` and git log, and the Claude Code gateway docs. `.env` was not opened. |

## <img src="../assets/icons-phosphor/git-pull-request.svg" width="24" height="24" alt=""> Suggest a change

Noticed something wrong, or know a better way? Open an [issue](https://github.com/drasticstatic/my-template/issues) or a pull request against `main`; the lab steward reads them, and a person with the role merges with a merge commit so your name stays on it. Not on GitHub? Tell any steward you know, or your helper, in your own words.

<sub>Part of [`my-template`](../README.md) › [`startup/`](README.md). Icons: Phosphor duotone (MIT).</sub>

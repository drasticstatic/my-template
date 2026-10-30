# SOP-IT-001 · VPN and DNS resolver stalls: how to tell, how to check, how to fix

**Department:** IT · **ID:** 001 · **Status:** draft (approved when tagged) · **Owner:** whoever runs an observer on their machine · **Last changed:** 2026-10-30

## Purpose
A machine behind a VPN can lose the ability to resolve some hostnames while everything else keeps working. Bots and helpers then time out silently. This procedure says how to recognise it, prove it in a minute, and fix it, and keeps the growing list of what was found.

## Scope
macOS machines running NordVPN (NordLynx) or another tunnel, on any uplink (Starlink included). The symptoms below were observed on Christopher's machine, Oct 29–30, 2026.

## How to tell
- A long-running observer (the DEX-arb monitor, a poller) stops logging while its process is still alive.
- `gh`, `git push` or `curl` to one host hangs or says `i/o timeout`, while other sites load.
- The observer's log says `request timeout` or `getaddrinfo ENOTFOUND`.

## Steps: check in one minute
1. Which resolver is first?
   ```sh
   scutil --dns | head -20
   ```
   *You should see:* `nameserver[0]` and the interface. A `100.64.x.x` address on a `utun` interface is the VPN's resolver (NordLynx on Oct 30, 2026 used `100.64.0.2` on `utun6`); `192.168.x.x` is the home router; a `100.64.x.x` address on `en0` would be Starlink's carrier-grade NAT instead.
2. Does the system resolver answer for the host that is failing?
   ```sh
   dig +short +time=3 +tries=1 arb-mainnet.g.alchemy.com
   dig +short +time=3 +tries=1 api.github.com
   ```
   *You should see:* an address or alias within three seconds. Nothing, or `connection timed out`, is the stall.
3. Does a public resolver answer the same name?
   ```sh
   dig +short +time=3 +tries=1 @1.1.1.1 arb-mainnet.g.alchemy.com
   ```
   *You should see:* an answer. If step 2 fails and step 3 works, the VPN's resolver is the cause, not the uplink.
4. Is the VPN up and which interface carries the default route?
   ```sh
   netstat -rn | grep -E '^default'
   pgrep -il nord
   ```

## Steps: fix
1. **Give the VPN a resolver that works:** in NordVPN → Settings → Connection, set a custom DNS (for example `1.1.1.1` and `1.0.0.1`), or turn off Threat Protection's DNS filtering and reconnect. *You should see:* step 2 above answers.
2. **If it is a one-off stall:** disconnect and reconnect the VPN, then `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`.
3. **Make the observer independent:** the DEX-arb bot fails over to public RPC endpoints and comes home (`helpers/rpc.js`) and alerts after ten quiet minutes. Any observer in the fleet should do the same: try the next endpoint on a transport error, and raise an alert on silence.
4. **Record what you saw** in the troubleshooting table below, by pull request.

## Verification
Steps 2 and 3 of the check answer alike; the observer's log shows a new tick; the stall alert has not fired for an hour.

## Troubleshooting (grows)
| Date | Symptom | Finding | Fix |
|---|---|---|---|
| 2026-10-29 07:35 ET → 10-30 05:59 ET | DEX-arb monitor silent 26 h, process alive, `request timeout` in `monitor.err` | NordLynx resolver `100.64.0.2` on `utun6` stopped resolving `arb-mainnet.g.alchemy.com`; `api.github.com` intermittently too; `1.1.1.1` resolved both | failover to public RPC in the bot; stall alert; custom DNS in NordVPN recommended |
| 2026-10-30 ~05:40 ET | `gh api` to api.github.com `dial tcp … i/o timeout` for ~20 min, then fine | same resolver; Starlink reconnects can make the tunnel re-establish and the resolver stall | wait or reconnect; run pushes in the background with a time limit |

## Related
- SOP-OPS-002 (what to do when a push hangs)
- The DEX-arb bot's `RUNBOOK.md` Stage 1.3a and `helpers/rpc.js`
- Proposal: THEF 010 (treasury) only in that a read-only observer has the same failure mode

## Change log
| Date | Change | By |
|---|---|---|
| 2026-10-30 | Drafted from the Oct 29–30 outage | Alfred (FortunaTradesARB session) |

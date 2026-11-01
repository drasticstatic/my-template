---
marp: true
theme: default
paginate: true
size: 16:9
title: Welcome to Your Organisation
description: A first walk through Your Organisation for a newcomer and the AI helper beside them, in seven stops.
style: |
  /* Tone: the organisation's four shades from my-template/proposals-template/TONES.md (bare hex, no #). The ground is
     the walkthrough deck's slate for every family; the family shows in the left rule, the stops, the headings' rule and
     the colour strip. Headings and links mix the primary with white, so purple, blue and amber all read on slate.
     Do not hand-edit colours below; change the four placeholders. Icons are inline Lucide SVG (ISC), drawn in the
     text's own colour. */
  section { background: #0f172a; color: #e2e8f0; font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; font-size: 25px; padding: 52px 64px 56px; border-left: 10px solid #d97706; }
  section::after { color: #94a3b8; font-size: 0.6em; }
  section h1 { color: color-mix(in srgb, #d97706 55%, white) !important; border-bottom: 2px solid #b45309; padding-bottom: 8px; font-size: 1.45em; margin-bottom: 0.45em; }
  section h2 { color: #fef3c7 !important; font-size: 1.1em; margin: 0.2em 0 0.4em; }
  strong { color: color-mix(in srgb, #fef3c7 70%, white); }
  em { color: #cbd5e1; }
  a { color: color-mix(in srgb, #d97706 40%, white); text-decoration: underline; text-decoration-color: #b45309; }
  code { background: #334155; color: color-mix(in srgb, #fef3c7 80%, white); padding: 1px 6px; border-radius: 4px; font-size: 0.82em; }
  pre { background: #1e293b; color: color-mix(in srgb, #fef3c7 80%, white); border: 1px solid #334155; border-radius: 8px; padding: 12px 16px; font-size: 0.68em; line-height: 1.35; }
  pre code { background: transparent; color: inherit; padding: 0; font-size: 1em; }
  table { border-collapse: collapse; width: 100%; font-size: 0.72em; }
  section table th { background: #334155; color: color-mix(in srgb, #d97706 45%, white); padding: 6px 10px; text-align: left; border: 1px solid #475569; }
  section table td { background: #1e293b; color: #e2e8f0; padding: 5px 10px; border: 1px solid #334155; }
  blockquote { border-left: 4px solid #d97706; background: #1e293b; color: #e2e8f0; padding: 8px 16px; margin: 0.6em 0; font-style: normal; }
  ul, ol { margin-top: 0.2em; }
  li { margin: 0.18em 0; }
  .small { font-size: 0.66em; color: #94a3b8; }
  .stop { display: inline-block; min-width: 1.6em; height: 1.6em; line-height: 1.6em; border-radius: 50%; text-align: center; background: color-mix(in srgb, #d97706 60%, white); color: #0f172a; font-weight: 700; font-size: 0.8em; margin-right: 0.35em; }
  svg.i { width: 1em; height: 1em; vertical-align: -0.15em; margin-right: 0.3em; color: color-mix(in srgb, #d97706 55%, white); }
  h1 svg.i, h2 svg.i { margin-right: 0.35em; }
  .rail { display: flex; height: 14px; margin: 18px 0 0; border-radius: 3px; overflow: hidden; }
  .rail span { flex: 1; }
  .s1 { background: #6b4f1d } .s2 { background: #b45309 } .s3 { background: #d97706 } .s4 { background: #fef3c7 }
  section.lead { border-left: none; background: linear-gradient(135deg, color-mix(in srgb, #6b4f1d 55%, #1e293b) 0%, #0f172a 70%); justify-content: center; }
  section.lead h1 { border: none; font-size: 2.3em; color: #f8fafc !important; margin-bottom: 0.1em; }
  section.lead h2 { color: #fef3c7 !important; font-size: 1.15em; font-weight: 400; }
  section.lead .kicker { color: color-mix(in srgb, #d97706 60%, white); letter-spacing: 0.25em; font-size: 0.6em; font-weight: 700; }
---

<!--
  Welcome deck template (my-template/decks-template), redesigned 2026-11-01 in the style of the walkthrough deck
  (decks/my-template-walkthrough.marp.md). Placeholders are names in double braces: ORG_NAME, TONE_PRIMARY, TONE_DEEP,
  TONE_MID, TONE_TINT, READING_ROOM_URL, SOP_PUBLIC_URL, PROPOSALS_URL, ACCESS_CONTACT. decks-template/README.md says
  what each one takes, fills them in one command, and renders. After filling, `grep -c '[{][{]' welcome.marp.md` prints 0.
-->

<!-- _class: lead -->
<!-- _paginate: false -->

<span class="kicker">WELCOME · Your Organisation</span>

# Welcome to Your Organisation

## Seven stops from "I have no GitHub account" to "I read, I answer, and my helper reads with me"

<span class="small">For a newcomer, and for the AI helper beside them. Every slide points at a real page; the deck only shows the order to open them in. Nothing here asks you to type a command.</span>

<div class="rail"><span class="s1"></span><span class="s2"></span><span class="s3"></span><span class="s4"></span></div>

---

# <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m16.24 7.76-1.804 5.411a2 2 0 0 1-1.265 1.265L7.76 16.24l1.804-5.411a2 2 0 0 1 1.265-1.265z" /> <circle cx="12" cy="12" r="10" /></svg> Who this is for, and how to read it

- <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="8" r="5" /> <path d="M20 21a8 8 0 0 0-16 0" /></svg> **You**, if you have just been invited to Your Organisation, or are about to be.
- <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 8V4H8" /> <rect width="16" height="12" x="4" y="8" rx="2" /> <path d="M2 14h2" /> <path d="M20 14h2" /> <path d="M15 13v2" /> <path d="M9 13v2" /></svg> **Your helper** (Claude, ChatGPT, Codex, Littlebird, any of them), which reads the same pages you do, never more than you can.
- <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="6" cy="19" r="3" /> <path d="M9 19h8.5a3.5 3.5 0 0 0 0-7h-11a3.5 3.5 0 0 1 0-7H15" /> <circle cx="18" cy="5" r="3" /></svg> Every slide points at a real page. The deck shows the **order**; the pages hold the detail.

> Read it once top to bottom. After that, jump to the stop you need. Everything Your Organisation writes wears these four shades, so you can tell whose page it is before you read a word.

<div class="rail"><span class="s1"></span><span class="s2"></span><span class="s3"></span><span class="s4"></span></div>

---

# <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14.106 5.553a2 2 0 0 0 1.788 0l3.659-1.83A1 1 0 0 1 21 4.619v12.764a1 1 0 0 1-.553.894l-4.553 2.277a2 2 0 0 1-1.788 0l-4.212-2.106a2 2 0 0 0-1.788 0l-3.659 1.83A1 1 0 0 1 3 19.381V6.618a1 1 0 0 1 .553-.894l4.553-2.277a2 2 0 0 1 1.788 0z" /> <path d="M15 5.764v15" /> <path d="M9 3.236v15" /></svg> The path at a glance

| | Stop | What you leave with |
|---|---|---|
| <span class="stop">1</span> | <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" /> <circle cx="9" cy="7" r="4" /> <line x1="19" x2="19" y1="8" y2="14" /> <line x1="22" x2="16" y1="11" y2="11" /></svg> Your first hour | your own account, two-factor sign-in, the invitation accepted |
| <span class="stop">2</span> | <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 7v14" /> <path d="M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z" /></svg> Five words | repository, branch, pull request, issue, merge |
| <span class="stop">3</span> | <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M7 20h10" /> <path d="M10 20c5.5-2.5.8-6.4 3-10" /> <path d="M9.5 9.4c1.1.8 1.8 2.2 2.3 3.7-2 .4-3.5.4-4.8-.3-1.2-.6-2.3-1.9-3-4.2 2.8-.5 4.4 0 5.5.8z" /> <path d="M14.1 6a7 7 0 0 0-1.1 4c1.9-.1 3.3-.6 4.3-1.4 1-1 1.6-2.3 1.7-4.6-2.7.1-4 1-4.9 2z" /></svg> Proposals | how an idea asks for a decision, and where yours is waiting |
| <span class="stop">4</span> | <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 12h-5" /> <path d="M15 8h-5" /> <path d="M19 17V5a2 2 0 0 0-2-2H4" /> <path d="M8 21h12a2 2 0 0 0 2-2v-1a1 1 0 0 0-1-1H11a1 1 0 0 0-1 1v1a2 2 0 1 1-4 0V5a2 2 0 1 0-4 0v2a1 1 0 0 0 1 1h3" /></svg> Procedures | how an approved thing is done, step by step |
| <span class="stop">5</span> | <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M13 4h3a2 2 0 0 1 2 2v14" /> <path d="M2 20h3" /> <path d="M13 20h9" /> <path d="M10 12v.01" /> <path d="M13 4.562v16.157a1 1 0 0 1-1.242.97L5 20V5.562a2 2 0 0 1 1.515-1.94l4-1A2 2 0 0 1 13 4.561Z" /></svg> The reading room, and your helper | where members read, and how a helper reads with you |
| <span class="stop">6</span> | <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="18" cy="18" r="3" /> <circle cx="6" cy="6" r="3" /> <path d="M6 21V9a9 9 0 0 0 9 9" /></svg> How a change travels | rehearsal, Promote, live, the public twin |
| <span class="stop">7</span> | <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /></svg> How to answer | the right door for a yes, a question or a request |

---

# <span class="stop">1</span> Your first hour

| | Step | You should see |
|---|---|---|
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" /> <circle cx="9" cy="7" r="4" /> <line x1="19" x2="19" y1="8" y2="14" /> <line x1="22" x2="16" y1="11" y2="11" /></svg> | Sign up at `github.com/signup` with **your own** email; **you type your own password** | your empty dashboard |
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 10a2 2 0 0 0-2 2c0 1.02-.1 2.51-.26 4" /> <path d="M14 13.12c0 2.38 0 6.38-1 8.88" /> <path d="M17.29 21.02c.12-.6.43-2.3.5-3.02" /> <path d="M2 12a10 10 0 0 1 18-6" /> <path d="M2 16h.01" /> <path d="M21.8 16c.2-2 .131-5.354 0-6" /> <path d="M5 19.5C5.5 18 6 15 6 12a6 6 0 0 1 .34-2" /> <path d="M8.65 22c.21-.66.45-1.32.57-2" /> <path d="M9 6.8a6 6 0 0 1 9 5.2v2" /></svg> | Turn on two-factor sign-in; keep the recovery codes with important papers | "Two-factor authentication is enabled" |
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect width="20" height="16" x="2" y="4" rx="2" /> <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7" /></svg> | Send your **username** (never the password) to a steward, through an issue on the members' page | an invitation by email, or on the bell icon |
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M13 4h3a2 2 0 0 1 2 2v14" /> <path d="M2 20h3" /> <path d="M13 20h9" /> <path d="M10 12v.01" /> <path d="M13 4.562v16.157a1 1 0 0 1-1.242.97L5 20V5.562a2 2 0 0 1 1.515-1.94l4-1A2 2 0 0 1 13 4.561Z" /></svg> | Click **Join** | Your Organisation under your profile's Organizations |

> <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z" /> <path d="m9 12 2 2 4-4" /></svg> Nobody needs your password or a sign-in code: not a steward, not a friend, not a helper. Invitations go to your username.

<span class="small">The full procedure is **SOP-COM-001 "New to GitHub: your first hour"** in the procedures: [https://github.com/your-org/ops-standard-operating-procedures-public](https://github.com/your-org/ops-standard-operating-procedures-public).</span>

---

# <span class="stop">2</span> Five words, and you can find your way

| | Word | Means |
|---|---|---|
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect width="8" height="5" x="14" y="17" rx="1" /> <path d="M10 20H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h3.9a2 2 0 0 1 1.69.9l.81 1.2a2 2 0 0 0 1.67.9H20a2 2 0 0 1 2 2v2.5" /> <path d="M20 17v-2a2 2 0 1 0-4 0v2" /></svg> | **Repository** | a folder that remembers every change and who made it |
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="6" x2="6" y1="3" y2="15" /> <circle cx="18" cy="6" r="3" /> <circle cx="6" cy="18" r="3" /> <path d="M18 9a9 9 0 0 1-9 9" /></svg> | **Branch** | one line of that history: `main` is the live copy, `preview` the rehearsal |
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="18" cy="18" r="3" /> <circle cx="6" cy="6" r="3" /> <path d="M13 6h3a2 2 0 0 1 2 2v7" /> <line x1="6" x2="6" y1="9" y2="21" /></svg> | **Pull request** | a change asking to move from one branch to another, with a place to comment |
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /></svg> | **Issue** | a conversation thread: the easiest way to ask or answer |
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="18" cy="18" r="3" /> <circle cx="6" cy="6" r="3" /> <path d="M6 21V9a9 9 0 0 0 9 9" /></svg> | **Merge** | accepting a pull request so the change lands; a person with the role does it |

<span class="small">You never need to type a branch command. You read, you comment, and you say yes or no.</span>

---

# <span class="stop">3</span> Proposals: *should we?*

1. <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m16.24 7.76-1.804 5.411a2 2 0 0 1-1.265 1.265L7.76 16.24l1.804-5.411a2 2 0 0 1 1.265-1.265z" /> <circle cx="12" cy="12" r="10" /></svg> **TL;DR**: five lines, the only part you have to read.
2. <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z" /> <path d="M20 3v4" /> <path d="M22 5h-4" /> <path d="M4 17v2" /> <path d="M5 18H3" /></svg> **What is offered**: how things are today, beside what is proposed.
3. <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m3 17 2 2 4-4" /> <path d="m3 7 2 2 4-4" /> <path d="M13 6h8" /> <path d="M13 12h8" /> <path d="M13 18h8" /></svg> **Decisions log**: what was chosen, when, and by whom. Yours stay blank until you choose.
4. <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z" /> <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3" /> <path d="M12 17h.01" /></svg> **Asks**: usually none, sometimes one.
5. <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="11" cy="11" r="8" /> <path d="m21 21-4.34-4.34" /></svg> **Sources, and what could not be confirmed**: folded away, never hidden.

Each proposal is a **PDF for your eyes** and the **markdown it was made from** for your helper's. Start with **000 Start here** in [https://github.com/your-org/proposals](https://github.com/your-org/proposals).

---

# <span class="stop">4</span> Procedures: *this is how we do it now*

- <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 12h-5" /> <path d="M15 8h-5" /> <path d="M19 17V5a2 2 0 0 0-2-2H4" /> <path d="M8 21h12a2 2 0 0 0 2-2v-1a1 1 0 0 0-1-1H11a1 1 0 0 0-1 1v1a2 2 0 1 1-4 0V5a2 2 0 1 0-4 0v2a1 1 0 0 0 1 1h3" /></svg> Named `SOP-<Department>-<ID>-<name>`: `SOP-OPS-001` is the first operations procedure.
- <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3.85 8.62a4 4 0 0 1 4.78-4.77 4 4 0 0 1 6.74 0 4 4 0 0 1 4.78 4.78 4 4 0 0 1 0 6.74 4 4 0 0 1-4.77 4.78 4 4 0 0 1-6.75 0 4 4 0 0 1-4.78-4.77 4 4 0 0 1 0-6.76Z" /> <path d="m9 12 2 2 4-4" /></svg> A **draft** until the officers tag an approved version; the tag is the approval.
- <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 3h20" /> <path d="M21 3v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V3" /> <path d="m7 21 5-5 5 5" /></svg> Each one opens with a badge row in **Your Organisation's colour**, puts an icon beside each idea and a diagram where a picture explains the mechanism, and is also a PDF.

| Start with | Says |
|---|---|
| SOP-COM-001 | your first hour (stop 1, in full) |
| SOP-OPS-001 | how a change travels (stop 6, in full) |
| SOP-GOV-002 | how GitHub collaboration works here: teams, issues, pull requests, Pages |

<span class="small">The procedures visitors may read: [https://github.com/your-org/ops-standard-operating-procedures-public](https://github.com/your-org/ops-standard-operating-procedures-public).</span>

---

# <span class="stop">5</span> The reading room, and your helper

- <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M13 4h3a2 2 0 0 1 2 2v14" /> <path d="M2 20h3" /> <path d="M13 20h9" /> <path d="M10 12v.01" /> <path d="M13 4.562v16.157a1 1 0 0 1-1.242.97L5 20V5.562a2 2 0 0 1 1.515-1.94l4-1A2 2 0 0 1 13 4.561Z" /></svg> The reading room gathers what members read: proposals, procedures and decks, each a page and a PDF. Open [https://github.com/your-org/reading-room](https://github.com/your-org/reading-room) while signed in.
- <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3" /> <path d="M12 9v4" /> <path d="M12 17h.01" /></svg> A **404** there means "not yet in the readers team" or "signed out", not "broken": ask a steward, through an issue on the members' page.
- <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10" /> <path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20" /> <path d="M2 12h20" /></svg> What is ready for visitors also appears in the **public room**, which links back to this one.
- <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 8V4H8" /> <rect width="16" height="12" x="4" y="8" rx="2" /> <path d="M2 14h2" /> <path d="M20 14h2" /> <path d="M15 13v2" /> <path d="M9 13v2" /></svg> **Your helper** reads the same pages once you connect it with your permission, never more than you can. Point it at the markdown, not the PDF.

> A good first question for your helper: *"Read 000 Start here and tell me, in five lines, what is waiting for my answer."*

---

# <span class="stop">6</span> How a change travels

```
  an edit  ──→  preview  (the rehearsal: read it here, comment here)
                   │
                   │  "Promote: <what>"  pull request, preview into main
                   │  a person with the role merges it, with a merge commit
                   ▼
                  main  (the live copy)
                   │
                   │  automatic sync: only pages an officer listed, after a tripwire reads every file
                   ▼
            the public twin  (what visitors see)
```

- <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="18" cy="18" r="3" /> <circle cx="6" cy="6" r="3" /> <path d="M6 21V9a9 9 0 0 0 9 9" /></svg> **Merge, never squash**, so every author's name and every helper's signature survives.
- <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 8V4H8" /> <rect width="16" height="12" x="4" y="8" rx="2" /> <path d="M2 14h2" /> <path d="M20 14h2" /> <path d="M15 13v2" /> <path d="M9 13v2" /></svg> **A helper opens the Promote; a person merges it.** Helpers never merge.
- <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect width="18" height="11" x="3" y="11" rx="2" ry="2" /> <path d="M7 11V7a5 5 0 0 1 10 0v4" /></svg> A page that is not listed never leaves the private repository, on any branch.

---

# <span class="stop">7</span> How to answer

| You want to… | Do this |
|---|---|
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10" /> <path d="m9 12 2 2 4-4" /></svg> say yes, no, or "not yet" to a proposal | open an **issue** titled with its number, or ask a steward to note it in the decisions log |
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="18" cy="18" r="3" /> <circle cx="6" cy="6" r="3" /> <path d="M13 6h3a2 2 0 0 1 2 2v7" /> <line x1="6" x2="6" y1="9" y2="21" /></svg> comment on a change before it goes live | comment on the **Promote** pull request |
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z" /> <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3" /> <path d="M12 17h.01" /></svg> ask about a procedure | open an issue in the procedures repository, naming the SOP |
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 8V4H8" /> <rect width="16" height="12" x="4" y="8" rx="2" /> <path d="M2 14h2" /> <path d="M20 14h2" /> <path d="M15 13v2" /> <path d="M9 13v2" /></svg> let your helper draft an answer | let it draft; **you** read it and post it under your name |
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2.586 17.414A2 2 0 0 0 2 18.828V21a1 1 0 0 0 1 1h3a1 1 0 0 0 1-1v-1a1 1 0 0 1 1-1h1a1 1 0 0 0 1-1v-1a1 1 0 0 1 1-1h.172a2 2 0 0 0 1.414-.586l.814-.814a6.5 6.5 0 1 0-4-4z" /> <circle cx="16.5" cy="7.5" r=".5" fill="currentColor" /></svg> get access, or more of it | ask a steward, through an issue on the members' page |

> <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z" /></svg> There is no wrong door. A question in the wrong place gets moved, not lost.

---

# <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m16.24 7.76-1.804 5.411a2 2 0 0 1-1.265 1.265L7.76 16.24l1.804-5.411a2 2 0 0 1 1.265-1.265z" /> <circle cx="12" cy="12" r="10" /></svg> Where to start

| You are… | Open |
|---|---|
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" /> <circle cx="9" cy="7" r="4" /> <line x1="19" x2="19" y1="8" y2="14" /> <line x1="22" x2="16" y1="11" y2="11" /></svg> brand new to GitHub | **SOP-COM-001** in [https://github.com/your-org/ops-standard-operating-procedures-public](https://github.com/your-org/ops-standard-operating-procedures-public) |
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="8" r="5" /> <path d="M20 21a8 8 0 0 0-16 0" /></svg> a member with an account | **000 Start here** in [https://github.com/your-org/proposals](https://github.com/your-org/proposals) |
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M13 4h3a2 2 0 0 1 2 2v14" /> <path d="M2 20h3" /> <path d="M13 20h9" /> <path d="M10 12v.01" /> <path d="M13 4.562v16.157a1 1 0 0 1-1.242.97L5 20V5.562a2 2 0 0 1 1.515-1.94l4-1A2 2 0 0 1 13 4.561Z" /></svg> looking for what to read | the reading room: [https://github.com/your-org/reading-room](https://github.com/your-org/reading-room) |
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 8V4H8" /> <rect width="16" height="12" x="4" y="8" rx="2" /> <path d="M2 14h2" /> <path d="M20 14h2" /> <path d="M15 13v2" /> <path d="M9 13v2" /></svg> an AI helper | the repository's `AGENTS.md`, then **SOP-OPS-002** (helpers open pull requests; people merge) |
| <svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M11 12h2a2 2 0 1 0 0-4h-3c-.6 0-1.1.2-1.4.6L3 14" /> <path d="m7 18 1.6-1.4c.3-.4.8-.6 1.4-.6h4c1.1 0 2.1-.4 2.8-1.2l4.6-4.4a2 2 0 0 0-2.75-2.91l-4.2 3.9" /> <path d="m2 13 6 6" /></svg> stuck anywhere | a steward, through an issue on the members' page |

<span class="small">Questions go where the work is: an issue on the repository, or a comment on the Promote.</span>

<div class="rail"><span class="s1"></span><span class="s2"></span><span class="s3"></span><span class="s4"></span></div>

<div align="center">

<img src="../assets/icons-phosphor/file-text.svg" width="56" height="56" alt="">

# Markdown beside the PDF: one document, two readers

*The markdown is the source, for helpers and editors. The PDF is rendered from it, for human eyes. We send both.*

![Kind](https://img.shields.io/badge/Walkthrough-markdown_beside_PDF-800020?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--04-5c1a2b?style=flat-square)
![For](https://img.shields.io/badge/For-Partners_who_send_us_documents-64748b?style=flat-square)

<img src="../assets/icons-phosphor/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](../README.md) › [walkthroughs](README.md) › `MARKDOWN-BESIDE-PDF.md` · public · `main` is the working branch

</div>

## <img src="../assets/icons-phosphor/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="../assets/icons-phosphor/files.svg" width="16" height="16" alt=""> Every proposal, brief or paper the fleet sends has two forms.
2. <img src="../assets/icons-phosphor/file-text.svg" width="16" height="16" alt=""> The **markdown** (`README.md`) is the source, written for AI helpers and for anyone editing.
3. <img src="../assets/icons-phosphor/file-check.svg" width="16" height="16" alt=""> The **PDF** is rendered from it for human eyes.
4. <img src="../assets/icons-phosphor/handshake.svg" width="16" height="16" alt=""> We send both, and we ask partners to send both too.
5. <img src="../assets/icons-phosphor/bot.svg" width="16" height="16" alt=""> A page you can point any helper at: *"Read my-template/walkthroughs/MARKDOWN-BESIDE-PDF.md."*

## <img src="../assets/icons-phosphor/brain-circuit.svg" width="24" height="24" alt=""> Why the markdown matters to a helper

- <img src="../assets/icons-phosphor/scan-search.svg" width="16" height="16" alt=""> **A PDF is a picture of a page.** A helper has to extract the text back out of it, column by column, losing links,
  headings and tables along the way, and paying tokens for the extraction. The same words as markdown arrive as
  words: smaller, exact, with their structure intact.
- <img src="../assets/icons-phosphor/type.svg" width="16" height="16" alt=""> **Formatting is for people.** Unless a file *is* art (a render, a poster, a photograph), a helper does not care how
  the text looks. It cares what the text says and how it is organised.
- <img src="../assets/icons-phosphor/history.svg" width="16" height="16" alt=""> **Markdown is editable and diffable.** A reply can quote a line, a later revision can show what changed, and git
  keeps every version. A PDF can only be replaced.
- <img src="../assets/icons-phosphor/leaf.svg" width="16" height="16" alt=""> **It saves everyone tokens**, on both sides of a conversation, which keeps a helper's weekly budget for the work
  rather than for reading.

## <img src="../assets/icons-phosphor/files.svg" width="24" height="24" alt=""> What we send

A folder per proposal, `NNN-short-name/README.md`, with its rendered `pdf/NNN-short-name.pdf` beside it. The PDF is
the one a person opens; the markdown is the one a helper opens. Both say the same thing because one is made from the
other ([the template](../proposals-template/README.md), [the tones](../proposals-template/TONES.md)).

## <img src="../assets/icons-phosphor/handshake.svg" width="24" height="24" alt=""> What we ask of a partner

When you share a document with us, please include the text form alongside the PDF, whichever is easiest:

| If it was made with | Send |
|---|---|
| ChatGPT, Claude, Gemini or another assistant | the markdown or plain-text export of the same answer (most assistants offer "copy" or "export as Markdown"; the PDF was made from that text) |
| Google Docs or Word | **File → Download → Markdown** (Docs) or **Save as → Plain text** (Word), beside the PDF |
| A notes app or a chat message | the message itself is already text; paste it into a GitHub Issue or send it as is |
| A scan or a photograph of a page | the PDF or image is fine; say so, and we will transcribe it once and keep the transcription beside it |

Nothing about the PDF changes. It is still the thing you read.

## <img src="../assets/icons-phosphor/bot.svg" width="24" height="24" alt=""> For a helper reading this on behalf of a partner

Prefer the `.md` next to any `.pdf` in a `proposals/` folder. If only a PDF arrived, read it once, write the
transcription as `NNN-name/README.md` (or `source.md` beside the PDF when it is not ours), and say in the commit that
it was transcribed. Never retype a document that already exists as text somewhere; ask for the text.

## <img src="../assets/icons-phosphor/git-pull-request.svg" width="24" height="24" alt=""> Suggest a change

Noticed something wrong, or a step that could be kinder? Open an [issue](https://github.com/drasticstatic/my-template/issues)
or a pull request against `main`, changing this page. A person with the role reads it and merges with a merge commit, so
your name stays on it. An AI helper may do all of that up to the merge. Not on GitHub? Tell any steward you know, or your
helper, in your own words.

<sub>Written 2026-10-29 in the drasticstatic lab after a week of PDFs that began life as markdown. Related:
[`MANY-AI-TOOLS-ONE-TEAM.md`](MANY-AI-TOOLS-ONE-TEAM.md). Part of the [walkthroughs](README.md).</sub>

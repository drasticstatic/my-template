# 📄 Markdown beside the PDF: one document, two readers

**TL;DR:** every proposal, brief or paper the fleet sends has two forms. The **markdown** (`README.md`) is the
source, written for AI helpers and for anyone editing. The **PDF** is rendered from it for human eyes. We send both,
and we ask partners to send both too. A page you can point any helper at: *"Read my-template/walkthroughs/MARKDOWN-BESIDE-PDF.md."*

## Why the markdown matters to a helper

- **A PDF is a picture of a page.** A helper has to extract the text back out of it, column by column, losing links,
  headings and tables along the way, and paying tokens for the extraction. The same words as markdown arrive as
  words: smaller, exact, with their structure intact.
- **Formatting is for people.** Unless a file *is* art (a render, a poster, a photograph), a helper does not care how
  the text looks. It cares what the text says and how it is organised.
- **Markdown is editable and diffable.** A reply can quote a line, a later revision can show what changed, and git
  keeps every version. A PDF can only be replaced.
- **It saves everyone tokens**, on both sides of a conversation, which keeps a helper's weekly budget for the work
  rather than for reading.

## What we send

A folder per proposal, `NNN-short-name/README.md`, with its rendered `pdf/NNN-short-name.pdf` beside it. The PDF is
the one a person opens; the markdown is the one a helper opens. Both say the same thing because one is made from the
other ([the template](../proposals-template/README.md), [the tones](../proposals-template/TONES.md)).

## What we ask of a partner

When you share a document with us, please include the text form alongside the PDF, whichever is easiest:

| If it was made with | Send |
|---|---|
| ChatGPT, Claude, Gemini or another assistant | the markdown or plain-text export of the same answer (most assistants offer "copy" or "export as Markdown"; the PDF was made from that text) |
| Google Docs or Word | **File → Download → Markdown** (Docs) or **Save as → Plain text** (Word), beside the PDF |
| A notes app or a chat message | the message itself is already text; paste it into a GitHub Issue or send it as is |
| A scan or a photograph of a page | the PDF or image is fine; say so, and we will transcribe it once and keep the transcription beside it |

Nothing about the PDF changes. It is still the thing you read.

## For a helper reading this on behalf of a partner

Prefer the `.md` next to any `.pdf` in a `proposals/` folder. If only a PDF arrived, read it once, write the
transcription as `NNN-name/README.md` (or `source.md` beside the PDF when it is not ours), and say in the commit that
it was transcribed. Never retype a document that already exists as text somewhere; ask for the text.

<sub>Written 2026-10-29 in the drasticstatic lab after a week of PDFs that began life as markdown. Related:
[`MANY-AI-TOOLS-ONE-TEAM.md`](MANY-AI-TOOLS-ONE-TEAM.md).</sub>

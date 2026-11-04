---
name: compress-images
description: >
  Use before committing or uploading any picture (png jpg jpeg gif webp svg heic): check its size,
  shrink it with scripts/shrink-images.sh when it is over 2 MB, and never let one over 15 MB into a
  commit. TRIGGER when: "add this image", "commit the screenshot", "the banner is huge", "image too
  large", "pre-commit refused an image", "shrink", "compress images", "pngquant", "resize the photo",
  the image-size-check workflow failed, or `git add` is about to include a picture.
  Do NOT use for: drawing or choosing a banner (that is README-STANDARD.md and make-banner.py),
  deciding whether a picture may be public (NAMES-POLICY.md and the public-lane tripwire), SVG
  authoring, or video and PDF files.
---

# Skill: /compress-images — keep every picture under the limits before it is committed

Two numbers, and where they come from. **15 MB** is the public-lane tripwire's limit
(`scripts/scan-public-lane.sh`, `MAX_BYTES`): a file that size is refused at every public twin, so
`.githooks/pre-commit` refuses it before it is committed and
`sop-template/repo/.github/workflows/image-size-check.yml` fails the pull request if it arrives another
way. **2 MB** is the warning line: a README banner or a screenshot that size is nearly always a resize
away from a tenth of it, and a repository that carries forty of them clones slowly for everyone.

## Before Starting

- Read the header of `scripts/shrink-images.sh`: it says what is installed on this machine (sips and
  pngquant) and what is not (oxipng, jpegoptim, cwebp, magick), so you do not reach for a tool that is
  not there. Everything falls back to `sips`.
- Know what kind of picture you hold. A **banner, diagram, icon or screenshot** has flat colours and
  survives pngquant unchanged to the eye. A **photograph** has smooth gradients; quantising it to 256
  colours bands them. The script cannot tell the two apart: you can.

## What pngquant does to colours (why a photograph is flagged, not forced)

`pngquant` is **lossy**. It replaces the image's colours with a palette of at most 256, chosen to be
close to the originals (quantisation), and dithers between them. On a banner, a Mermaid export, a UI
screenshot or an icon the result is 60-80 % smaller with no visible change, because those pictures used
few colours to begin with. On a photograph, a gradient sky, a soft shadow or skin tones, the palette
shows as bands or grain; `--quality=65-80` makes it refuse (exit 99) when it cannot stay above that
floor, and `--skip-if-larger` keeps the original when quantising would not help, but neither protects
a photograph that must stay lossless. So: **when a PNG is a photograph, or its owner said it must stay
as it is, run `--no-quantise` (resize only) and say in your report that the file was not quantised and
why.** Do not force it. If it is still over 2 MB after resizing, that is a fact to report, not a reason
to quantise anyway. A photograph is usually better saved as JPEG in the first place (`sips -s format
jpeg -s formatOptions 80 in.png --out out.jpg`); offer that, and let the person choose.

## Steps

1. **Check first, touch nothing.** For the files you are about to add, or the folder they sit in:
   ```sh
   sh scripts/shrink-images.sh --check <files or folder>
   ```
   It prints size, pixels and a verdict per file (`REFUSE` over 15 MB, `shrink` over 2 MB, `ok`) and exits
   1 when anything is over 15 MB. Run this before every `git add` that includes a picture.
2. **Shrink what is over 2 MB.** Default is resize to 2500 px on the longer side, then pngquant for PNG
   and a quality-80 re-save for JPEG. A file is replaced only when the result is smaller.
   ```sh
   sh scripts/shrink-images.sh <files>                  # banners, diagrams, screenshots
   sh scripts/shrink-images.sh --no-quantise <files>    # a photograph as PNG, or anything that must stay lossless
   sh scripts/shrink-images.sh --max 1600 <files>       # a README banner needs no more than ~1600 px
   ```
   GIF and SVG are listed and left alone (an animated GIF would be flattened; an SVG is text). A large SVG
   almost always embeds a raster: export the raster, shrink it, and link to that instead.
3. **Look at the result** when the picture is for people (a banner, a cover): open it. A number is not
   a picture.
4. **`git add` the shrunk files again.** The hook reads the staged blob, so a shrink that was not
   re-added is still refused or warned.
5. **Never upload an image over 15 MB**, anywhere: not in a commit, not through a browser to a
   repository, not as a release asset or a Pages file. The scanner refuses it on the lane and the
   workflow fails the pull request; bypassing the hook only moves the refusal later.
6. **Over 15 MB even after shrinking?** Lower `--max`, or ask whether a picture that size belongs in a
   repository at all (a print-resolution original belongs in Drive or a release, with a small copy in the
   repository). Do not commit it with `--no-verify`.

## Output Format

One line per file, as the script prints it: `shrunk path before → after (what was done, final pixels)`
or `left path (why)`, then the summary line. In your report to the person: which files were shrunk and
by how much, which were left and why (especially any PNG photograph you did not quantise), and anything
still over 2 MB.

## After Completing

- `git add` the changed images; commit with the house trailers. The subject is usually
  `:recycle: refactor(assets): shrink <what>` or part of the commit that adds the picture.
- If the pre-commit hook or the workflow refused something, say so in the report with the file and size.
- Do not spread this skill or the hook to other repositories by hand: they travel with the next
  `.githooks/` and `sop-template/` sync from `my-template`.

## Quick Commands

```sh
sh scripts/shrink-images.sh --check assets                       # list, touch nothing; exit 1 if anything is over 15 MB
sh scripts/shrink-images.sh assets/banner.png                     # resize to 2500 px, then pngquant
sh scripts/shrink-images.sh --no-quantise photos/[FILE].png       # resize only: keep the colours
sh scripts/shrink-images.sh --max 1600 --quality 70-85 [FILE].png
pngquant --quality=65-80 --speed=1 --skip-if-larger --ext .png --force [FILE].png   # the exact line the hook prints
sips -Z 2500 [FILE].jpg                                           # resize one file by hand (sips upscales too: check the pixels first)
sips -s format jpeg -s formatOptions 80 [FILE].png --out [FILE].jpg   # a photograph saved as PNG, offered as JPEG
```

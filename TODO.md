# Upstream TODOs (MetOffice org)

Tracks what needs a reaction from @ickc across the upstream
[MetOffice](https://github.com/MetOffice) org: issues opened by ickc, and open
PRs that mention or involve ickc. This file lives only on the `fork` branch.

Last updated: 2026-09-23

## How to update this file (instructions for the next Claude session)

1. Re-run the searches below (whole org, not just this repo):

   ```sh
   # Issues opened by ickc (open and closed; closed ones just get moved to "Done")
   gh search issues --owner MetOffice --author ickc --limit 100 \
     --json repository,number,title,state,commentsCount,updatedAt \
     --jq '.[] | "\(.repository.nameWithOwner)#\(.number) [\(.state)] c=\(.commentsCount) \(.updatedAt[:10]) \(.title)"'
   # Open PRs that mention / involve ickc (includes PRs authored by and review-requested from ickc)
   gh search prs --owner MetOffice --involves ickc --state open --limit 100 \
     --json repository,number,title,author,updatedAt \
     --jq '.[] | "\(.repository.nameWithOwner)#\(.number) by \(.author.login) \(.updatedAt[:10]) \(.title)"'
   ```

2. For every item whose `updatedAt` is newer than "Last updated" above, read
   the new activity:

   ```sh
   gh issue view N -R OWNER/REPO --json comments --jq '.comments[] | "\(.author.login) \(.createdAt[:10]): \(.body)"'
   gh pr view N -R OWNER/REPO --json comments,reviews,reviewRequests,statusCheckRollup
   gh api repos/OWNER/REPO/pulls/N/comments --jq '.[] | "\(.user.login) \(.path):\(.line) \(.body)"'  # inline review comments
   ```

3. Update each entry: summarise *new* comments (who, date, gist), set
   **Ball in court** (`ickc` = ickc owes a reply/action; `others` = waiting on
   someone else; `none`), and write a concrete **Next** action. Keep entries
   short; link to the thread rather than copying it.
4. Move closed/merged items to "Done" with a one-line outcome. Add new items.
5. Re-sort "Action needed" by priority, bump "Last updated", and commit on
   `fork` (`git commit -m "Update upstream TODOs"`).

## Summary

| Item | Ball in court | Last activity | Next |
| --- | --- | --- | --- |
| [LFRic-AT#358](https://github.com/MetOffice/LFRic-Atmosphere-Training/issues/358) quiz quality | **ickc** | 2026-09-17 | PR fixing clear errors |
| [LFRic-AT#355](https://github.com/MetOffice/LFRic-Atmosphere-Training/issues/355) further-reading sections | **ickc** | 2026-09-17 | PR using `seealso` |
| [LFRic-AT#354](https://github.com/MetOffice/LFRic-Atmosphere-Training/issues/354) explain figures | **ickc** (unblocked: #360 merged) | 2026-09-17 | PR on top of the new SVGs |
| #360 follow-ups (no issue yet) | **ickc** | 2026-09-22 | Open follow-up issue/PR |
| [LFRic-AT#357](https://github.com/MetOffice/LFRic-Atmosphere-Training/issues/357) structured vs unstructured | others (@jcmt) | 2026-09-17 | Wait; maybe propose phasing |
| [LFRic-AT#233](https://github.com/MetOffice/LFRic-Atmosphere-Training/issues/233) formatter / style check in CI | **ickc** | 2026-06-08 | PR: doc8 on changed files |
| [LFRic-AT#356](https://github.com/MetOffice/LFRic-Atmosphere-Training/issues/356) trim JULES / Ocean pages | others | 2026-09-17 | Wait for feedback |
| [LFRic-AT#161](https://github.com/MetOffice/LFRic-Atmosphere-Training/issues/161) document allowed Actions | others | 2026-05-21 | Check git-github-docs#436 |
| [LFRic-AT#162](https://github.com/MetOffice/LFRic-Atmosphere-Training/issues/162) Pixi proposal | none (declined) | 2026-05-29 | Consider closing |
| [shumlib#39](https://github.com/MetOffice/shumlib/pull/39) link OpenMP targets (PR by ickc, fixes #37) | others (review: t00sa) | 2026-09-17 | Wait; CI green |
| [shumlib#37](https://github.com/MetOffice/shumlib/issues/37) BUILD_OPENMP has no effect | others | 2026-09-09 | Closed by #39 |
| [shumlib#38](https://github.com/MetOffice/shumlib/issues/38) 2026.07.2 reports 2026.07.1 | others | 2026-09-09 | Wait |

## Action needed (ickc)

### #360 follow-ups (raster → vector, merged 2026-09-22)

- wxtim merged #360 without answering ickc's question on whether
  `seamless_dev_cycle.svg` dropping the ✓/✗ gates (and making all Evaluation
  arrows two-way) is still accurate. wxtim also said "there are other images
  which ought to be converted".
- Non-blocking points from ickc's review, never raised on the PR:
  - `unstructured_tools.svg` is 1.7 MB / 22k lines with embedded base64
    PNG/SVG logos; `components.svg` embeds 5 base64 PNGs. Not really vector
    or diffable. Link or inline the vector logos, then run `svgo`/`scour`.
  - `source/_static/logos/` (PNG, SVG, `.ico`, `.provenance`) isn't
    referenced from any `.rst`; check intent and third-party logo licensing.
  - `intro_components.html`: empty `id=""`, unescaped `&`, no `aria-hidden`
    on arrow SVGs, overflows at phone width, lost its figure caption/number.
  - Trialling table has no label/intro sentence; "Long (100yr) coupled
    climate runs" and "Seasonal hindcast" from the original 3rd column are
    missing.
- **Next:** open one issue listing these (plus a checklist of remaining
  rasters to convert), and re-ask the ✓/✗ gates question there. Then send
  small PRs (SVG size first, then `intro_components.html` accessibility).

### LFRic-AT#358 — Quiz quality

- wxtim (2026-09-17): quizzes are a mix of self-check and understanding
  check; distractors should reveal misconceptions; favours fewer, harder
  questions with explanatory feedback; fixing clear errors (placeholder
  question, contradictory feedback, unrecognised settings) separately is
  "probably worth doing" and uncontroversial. Suggests testing on new users.
- **Next:** open a small PR fixing the clear errors first; then propose a
  redesign for one quiz as a pilot.

### LFRic-AT#355 — Further-reading sections on landing pages

- wxtim (2026-09-17): agrees about digressions; likes the proposed rewording
  of the prior-knowledge note; no comms reason to keep links at top;
  suggests Sphinx `.. seealso::` at the end of the *section* rather than page.
- **Next:** PR implementing the rewording + `seealso` boxes.

### LFRic-AT#354 — Introduce and explain figures

- wxtim (2026-09-17): "mesh3.png should _not_ be a picture IMO!" — #360
  (merged 2026-09-22) replaced it with a table.
- **Next:** unblocked. Rework figure intros/captions/alt text on top of the
  new SVGs (use `:numref:`); can fold in the lost `intro_components`
  caption from the #360 follow-ups.

### LFRic-AT#233 — Formatter / style check in CI

- Consensus (liamjberrisford, wxtim, ickc): lint only files changed in the
  PR and report, don't auto-format. doc8 + (reviewdog or a
  `git diff --name-only` loop). wxtim offered a ~30 min setup they didn't post.
- The `fork` branch already has doc8 as a pixi task/dep.
- **Next:** PR a GitHub Actions job running doc8 on changed `.rst` files
  (no third-party actions — see the org allow-list, #161).

## Waiting on others

- **LFRic-AT#357** — wxtim wants @jcmt to respond (chunky restructure); asks
  whether it can be done in parts. Could reply with a phased plan to unblock.
- **LFRic-AT#356** — no comments yet.
- **LFRic-AT#161** — wxtim pointed to
  [MetOffice/git-github-docs#436](https://github.com/MetOffice/git-github-docs/issues/436)
  for documenting the allowed-Actions policy. Check its status; close #161
  if it's handled there.
- **LFRic-AT#162** — Pixi proposal declined by wxtim (2026-05-28) as extra
  maintenance. Pixi lives on `fork` only. Consider closing.
- **shumlib#39** (fixes #37) — review requested from t00sa, CI green, no
  comments yet.
- **shumlib#38** — version not bumped for 2026.07.2; no response yet.

## Done

- LFRic-AT#365 — higher-resolution Momentum logo, PR by ickc (merged by
  wxtim 2026-09-23; no SVG available per wxtim). Local branch
  `better-image-on-main` can be deleted.
- LFRic-AT#360 — raster → vector images, PR by wxtim (ickc approved
  2026-09-21 after pushing 3 fixes; merged 2026-09-22). Follow-ups above.

- LFRic-AT#232 — line-length safeguard (closed).
- LFRic-AT#163 — sphinxcontrib-quizdown dependency risk (closed).
- LFRic-AT#160 — commit lockfiles (closed).

# Isambard 3 support: status and notes

Working notes for the **Isambard 3** platform tab. Records what was verified on
Isambard 3, what the training needs beyond
[lfric-env-isambard](https://github.com/ickc/lfric-env-isambard), and open
blockers.

## Environments

| What | Where | Provided by |
|------|-------|-------------|
| LFRic build + workflow tools | `module use "$LFRIC_TRAINING_PREFIX/modulefiles"; module load lfric-env/v2026.08.18/cray` | lfric-env-isambard |
| Python analysis env | `$LFRIC_TRAINING_PREFIX/conda/envs/lfric-training-v2026.09.28` | `etc/isambard3/build-python-env.sh` (this repo) |
| micromamba (for activation) | `$LFRIC_TRAINING_PREFIX/conda/bin/micromamba` | same script |

The versions are pinned in `source/include/isambard3-lfric-env.rst` and
`source/include/isambard3-python-env.rst` only.

Test area used while verifying: `$SCRATCHDIR/lfric-training`.

## Needed beyond lfric-env-isambard

- **Python analysis stack** (Iris, GeoVista, esmpy, JupyterLab, ...): provided
  by the separate micromamba env above rather than Spack.
- **Rosie site config**: the module ships `rosie` but no `[rosie-id]` prefix
  map, so `rosie checkout u-...` fails with `u: cannot determine prefix
  location`. lfric-env-isambard keeps one in
  `examples/science-suites/site/rose.conf`; the module should set
  `ROSE_SITE_CONF_PATH` to a shipped copy. Until then learners add it to
  `~/.metomi/rose.conf`.
- **`cylc gui`** (cylc-uiserver) is not installed; the docs use `cylc tui`.
- **`rose edit`** does not exist in Rose 2; the docs point to a text editor.
- **`fcm`** is not in the module (not needed by the practicals so far).

## Isambard 3 facts the docs rely on

- Login nodes are assigned at random; there is no login-to-login SSH. So
  JupyterLab listens on the login node's HSN name
  (`$(hostname -s).hsn.cm.i3.isambard.ac.uk`) and the tunnel is
  `ssh -T -L localhost:PORT:HOST:PORT <PROJECT>.3.isambard`. Verified reachable
  from another host on the HSN.
- Compute nodes reach GitHub over HTTPS. SSH to GitHub does not work in jobs:
  the key lives in the login-node ssh-agent.

## Status by page

| Page | Status on Isambard 3 |
|------|----------------------|
| Mesh tutorial (`mesh_overview/exercises/practical_exercises`) | Verified: all 11 notebooks run in the Python env; JupyterLab via SSH tunnel |
| LFRic infrastructure setup (`lfric_infrastructure/practical_exercises`) | Written |
| Practical 1, command line | Verified end to end (clone, compile, run, `ncdump`, `iodef.xml` changes, recompiled log message) |
| Practical 2, standard suite | **Blocked**: `MetOffice/momentum_user_training.example_lfric_workflow` is private (404 for our GitHub account) |
| Practical 3, rose stem | **Blocked**, see below; the page says so |

### Practical 1 details

- Upstream `lfric_apps` (tested at `aef51e27`) compiles **unpatched** with the
  module; none of lfric-env-isambard's `patches/` were needed.
- `local_build.py` clones lfric_core and the physics repositories from
  `git@github.com:` URLs. In a Slurm job there is no ssh-agent, so the docs
  set `GIT_CONFIG_COUNT/KEY_0/VALUE_0` to rewrite them to HTTPS (all are
  public). This avoids changing the learner's global git config.
- Compile: `srun --partition=grace --ntasks=1 --cpus-per-task=24
  --mem-per-cpu=1600M ... -j 24`, about 4 minutes.
- Run: about 26 s via `srun --ntasks=1 --cpus-per-task=4`. On a login node it
  was still at timestep 35 of 72 after 5 minutes (OpenMP threads competing
  with other users), so the docs run it through `srun`.

### Practical 3 (rose stem) blockers

1. `rose-stem/flow.cylc` uses `CYLC_WORKFLOW_SRC_DIR`, which cylc-flow only
   provides from **8.6.0**. lfric-env v2026.08.18 has cylc-flow 8.4.2 (and
   cylc-rose 1.5.1), so `cylc vip ... ./rose-stem` fails validation with
   `'CYLC_WORKFLOW_SRC_DIR' is undefined`. **Needs cylc-flow >= 8.6 in
   lfric-env-isambard.**
2. No rose-stem site for Isambard 3: `site/uoe` covers only the `epic` and
   `dial3` platforms. **Needs a `site/isambard3` (or an Isambard platform in
   `site/uoe`) upstream in lfric_apps**, plus `SITE` from
   `rose config rose-stem automatic-options` (site `rose.conf`).
3. `SOURCE_DIRECTORY` is always `ROSE_ORIG_HOST:path`, and
   `lib/python/read_sources.py` fetches `dependencies.yaml` with `scp` to that
   host. Isambard 3 login nodes reject SSH, even to themselves ("Too many
   authentication failures"). **Needs rose-stem to use a local path when the
   source is on a shared filesystem**, or host-based SSH between nodes.

## Tracked in lfric-env-isambard

| Issue | Topic |
|-------|-------|
| [#18](https://github.com/ickc/lfric-env-isambard/issues/18) | cylc-flow >= 8.6 for lfric_apps rose-stem |
| [#19](https://github.com/ickc/lfric-env-isambard/issues/19) | Isambard 3 rose-stem site |
| [#20](https://github.com/ickc/lfric-env-isambard/issues/20) | rose-stem `scp` to `ROSE_ORIG_HOST` |
| [#21](https://github.com/ickc/lfric-env-isambard/issues/21) | rosie `[rosie-id]` site config in the module |
| [#22](https://github.com/ickc/lfric-env-isambard/issues/22) | MOSRS password-caching recipe |
| [#23](https://github.com/ickc/lfric-env-isambard/issues/23) | cylc-uiserver for `cylc gui` (optional) |
| [#24](https://github.com/ickc/lfric-env-isambard/issues/24) | u-dz612, global practicals |
| [#25](https://github.com/ickc/lfric-env-isambard/issues/25) | u-by395, regional practicals |
| [#26](https://github.com/ickc/lfric-env-isambard/issues/26) | u-dz791, idealised practicals |
| [#27](https://github.com/ickc/lfric-env-isambard/issues/27) | Standard suite for Practical 2 |

When a suite is supported there, copy its instructions into the Isambard 3
tabs of the corresponding training pages.

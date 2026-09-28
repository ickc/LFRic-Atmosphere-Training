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

# Isambard 3 support: status and notes

Working notes for the **Isambard 3** platform tab. Records what was verified on
Isambard 3, what the training needs beyond
[lfric-env-isambard](https://github.com/ickc/lfric-env-isambard), and open
blockers.

## Environments

| What | Where | Provided by |
|------|-------|-------------|
| LFRic build + workflow tools | `module use /projects/u35v/khcheung.u35v/opt/Linux-aarch64/modulefiles; module load lfric-env/v2026.09.28/cray` | lfric-env-isambard |
| Python analysis env | `/projects/u35v/khcheung.u35v/opt/Linux-aarch64/conda/envs/lfric-training-v2026.09.28` | `etc/isambard3/build-python-env.sh` (this repo) |
| micromamba (for activation) | `/projects/u35v/khcheung.u35v/opt/Linux-aarch64/conda/bin/micromamba` | same script |

The versions are pinned in `source/include/isambard3-lfric-env.rst` and
`source/include/isambard3-python-env.rst` only.

Test area used while verifying: `$SCRATCHDIR/lfric-training`.

## Needed beyond lfric-env-isambard

- **Python analysis stack** (Iris, GeoVista, esmpy, JupyterLab, ...): provided
  by the separate micromamba env above rather than Spack.
- **`rose edit`** is an optional extra of Rose 2.7 (GTK) and is not installed;
  the docs point to a text editor.
- **`fcm`** is not in the module. The global and regional training suites
  would need it (see #24, #25).

Everything else first found missing (cylc 8.6, the rosie site config,
`mosrs-cache-password`, `cylc gui`, a rose-stem site) arrived in
lfric-env v2026.09.28; see the issue table below.

## Isambard 3 facts the docs rely on

- Login nodes are assigned at random; there is no login-to-login SSH. So
  JupyterLab listens on the login node's HSN name
  (`$(hostname -s).hsn.cm.i3.isambard.ac.uk`) and the tunnel is
  `ssh -T -L localhost:PORT:HOST:PORT <PROJECT>.3.isambard`. Verified reachable
  from another host on the HSN.
- Cylc across login nodes (tested 2026-09-30, using a compute node as the
  "other host"): `cylc ping/scan/dump/pause/play (resume)/cat-log/stop`
  all work over TCP. Restarting a scheduler that died uncleanly fails from
  any other host: `cylc play` runs `ssh <origin> cylc psutil` and stops with
  "Cannot tell if the workflow is running". Removing
  `runN/.service/contact` first lets it start. Documented in the appendix.
- `ssh localhost` is refused too, so setting the host to `localhost` does not
  avoid SSH. The rose-stem patch's plain-path fallback is what works.
- Compute nodes reach GitHub over HTTPS. SSH to GitHub does not work in jobs:
  the key lives in the login-node ssh-agent.

## Status by page

Verified with `lfric-env/v2026.09.28/cray` on 2026-09-30.

| Page | Status on Isambard 3 |
|------|----------------------|
| Mesh tutorial | Verified: all 11 notebooks run in the Python env; JupyterLab via SSH tunnel |
| Practical 1, command line | Verified end to end with lfric_apps `main` @ `2a3e9b1d` |
| Practical 2, standard suite | Verified with **u-dn704** in place of the private example repository (see below) |
| Practical 3, rose stem | Verified for the `scripts` group, with the lfric-env-isambard site patch (see below) |
| Global practicals (u-dz612) | **Cannot run**: coupled GC6 (UM, NEMO, SI3) and Met Office data. Tabs say so. #24 |
| Regional practicals (u-by395) | **Cannot run**: UM-driven nesting suite needing operational analyses. Tabs say so. #25 |
| Idealised practicals (u-dz791) | **Pending** the port in lfric-env-isambard, #26. No Isambard 3 tabs yet |

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

### Practical 2 details

- `MetOffice/momentum_user_training.example_lfric_workflow` is private (404
  for us). Training PR #183 introduced it as a "temporary fix" replacing
  `rosie co u-dn674`. The Isambard 3 tab uses u-dn704 (GAL9 at C12, same task
  graph), checked out at r361458 and launched with lfric-env-isambard's
  `examples/science-suites/run-suite.sh`, from a plain clone (no submodules).
- Run `u-dn704/run7`: extract, build_mesh, build_lfric_atm (9 min),
  generate_mesh, lfric_atm (43 s on 2 nodes) all succeeded; 144 timesteps,
  29 NetCDF files in `work/1/lfric_atm`.
- The timestep count is in `work/1/lfric_atm/PET00.lfric_atm.Log`, not
  `job.out`.
- Exercise: `timestep_end=72`, then `cylc vr u-dn704` and
  `cylc trigger u-dn704//1/lfric_atm` reran only the model and stopped at
  step 72. The work directory is reused, so old `*.nc` must be removed first
  for the file count to mean anything.
- MOSRS verified on 2026-09-30 after `mosrs-cache-password`: `rosie checkout
  u-dn704` and `svn update -r 361458` run without prompting. `rosie lookup`
  (the web service) still asks for a username; the practicals do not use it.
- The pinned revision (361458) must track lfric-env-isambard's stager
  (`patches/suites/42-roses-u-u-dn704-patch.sh`), which refuses any other.

### Practical 3 details

- Needs `patches/rose-stem/lfric_apps-isambard3-site.patch` from
  lfric-env-isambard applied to the learner's `lfric_apps` clone (#19, #20).
  It targets lfric_apps `main`; validated there at `801edbfa`, and it still
  applied at `2a3e9b1d`. It will need refreshing as `main` moves.
- The patch's site does not set `USE_TOKENS`, so `export-source` clones over
  SSH and fails without a GitHub key (#40). The docs append the one line that
  fixes it; drop that step once the patch carries it.
- `scripts` group: 12 of 12 tasks succeed. A trailing space fails
  `style_checker` ("Found trailing white space") and `fortitude_linter`.
- The Practical 1 hint code used `.lt.`, which `fortitude_linter` rejects
  (MOD021). Fixed in the training page to use `<`.
- The page mentions a `trac.log` summary; none was written in the run
  directory here.
- The `developer` group is not defined for the Isambard 3 site.

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
| [#40](https://github.com/ickc/lfric-env-isambard/issues/40) | rose-stem site should set `USE_TOKENS` |

#18 to #23 and #27 are closed. #24 and #25 are open and blocked on Met Office
data. #26 and #40 are open. When u-dz791 is supported there, add Isambard 3
tabs to the idealised practical pages.

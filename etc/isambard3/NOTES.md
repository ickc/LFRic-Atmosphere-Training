# Isambard 3 support: status and notes

Working notes for the **Isambard 3** platform tab. Records what was verified on
Isambard 3, what the training needs beyond
[lfric-env-isambard](https://github.com/ickc/lfric-env-isambard), and open
blockers.

## Environments

| What | Where | Provided by |
|------|-------|-------------|
| LFRic build + workflow tools | `module use "$LFRIC_TRAINING_PREFIX/modulefiles"; module load lfric-env/v2026.10.08/cray` | lfric-env-isambard |
| Python analysis env | `$LFRIC_TRAINING_PREFIX/conda/envs/lfric-training-v2026.09.28` | `etc/isambard3/build-python-env.sh` (this repo) |
| micromamba (for activation) | `$LFRIC_TRAINING_PREFIX/conda/bin/micromamba` | same script |

The versions are pinned in `source/include/isambard3-lfric-env.rst` and
`source/include/isambard3-python-env.rst` only.

Since lfric-env v2026.10.08 (lfric-env-isambard #46) both live under a
shared, non-personal prefix that only members of the course's Isambard 3
project can read, so learners must be added to that project (the access note
in the appendix says to ask the University of Exeter). The docs do not name
the prefix: learners are given it and save it as `LFRIC_TRAINING_PREFIX` in
`~/.bashrc`, as the appendix says. The Python env there was recreated from
the old one's `conda-explicit.txt` (same 480 packages), so its name keeps the
v2026.09.28 date. v2026.10.08 is frozen for the course: fixes go into a new
version, and the pin here is bumped.

The appendix also has learners put `export OMP_NUM_THREADS=4` in `~/.bashrc`.
Login nodes cap each user at 16 CPUs and 16 GiB (per-user cgroup), and with
`OMP_NUM_THREADS` unset `lfric_atm` starts 144 threads (22 of 72 steps in 3
minutes) and NumPy's OpenBLAS starts 128. The suites set `OMP_NUM_THREADS=1`
for their model tasks, so the exported value does not reach them.

Since lfric-env-isambard PR #54 (rebuilt in place, 14:23-16:58 UTC on
2026-10-01) the module no longer sets `PYTHONPATH`, and its own `python3` has
Iris, cartopy and matplotlib (enough for rose-stem's `plot_*` tasks, not for
the notebooks). Load the module first, then `micromamba activate`, as the
appendix says: `python3` and `jupyter` then come from the Python env, which
sees only its own packages, and `cylc`, `rose` and `psyclone` still come from
the module (checked in a fresh shell). Before #54 the module's older jinja2,
yaml and dateutil shadowed the Python env's. A shell or Jupyter server
started before the rebuild keeps the old `PYTHONPATH` even after `module
purge`; log in again.

Test area used while verifying: `$SCRATCH/lfric-training`.

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

Re-verified on 2026-10-08 with `lfric-env/v2026.10.08/cray` at the shared
prefix, as a fresh learner (new `HOME` and `SCRATCH`; lfric-env-isambard
`7a04a9d`; lfric_apps `8cfce297`; real `rosie checkout`s): Practical 1 on the
login node (build, run, hint edit: 72 hint lines, step 72 "ENJOY THE MODEL
TUTORIAL"); Practical 2 u-dn704 run4 (144 steps, 29 files); Practical 3
`scripts` 12/12; u-dz791 run14 cycle 1. The rest (run14 cycle 2, run15) is
still queued: from about 17:00 UTC on 2026-10-08 no job of the project
started for 18+ hours at `Priority=1`, and `sbatch --test-only` projected a
1-core job to 2026-10-13. Queue waits like this are expected for self-paced
learners; lfric-env-isambard #59 proposes smaller, non-exclusive model jobs,
since 24-core jobs started within 30 s while whole-node exclusive ones
waited 1.5 h in the same window.


Verified with `lfric-env/v2026.09.28/cray` on 2026-09-30. Practicals 1 and 2
and u-dz791 were re-verified on 2026-10-01 after the in-place XIOS rebuild
(#38) and the rose-meta addition (#51), as a trainee with a fresh `HOME`.
Runs started while the module was being regenerated (about 20:40-21:00 UTC
on 2026-09-30) failed (missing `xios.mod`, `cylc` and `jinja2` in jobs); they
are not environment bugs, but in-place updates during a course would break
learners' running builds.

Re-verified again on 2026-10-01 (20:57-21:45 UTC), after the in-place #54
rebuild, as a fresh trainee (new `HOME` and `SCRATCHDIR`; lfric-env-isambard
`4f1c6a7`; lfric_apps `d2b54a76`; rosie checkouts copied from the earlier
pass and reset with `svn revert`, because the MOSRS cache had expired).
Practical 1, Practical 2 (u-dn704 run3, then the 72-step rerun: 17 files),
u-dz791 run12 (control, 200 levels) and run13 (Experiment 2, 100 levels), and
page 05's code on both all passed. Practical 3 failed until #55 was fixed;
it passes again (see below).

| Page | Status on Isambard 3 |
|------|----------------------|
| Mesh tutorial | Verified: all 11 notebooks run in the Python env; JupyterLab via SSH tunnel |
| Practical 1, command line | Verified end to end with lfric_apps `main` @ `d2b54a76` (2026-10-01) |
| Practical 2, standard suite | Verified with **u-dn704** in place of the private example repository (see below) |
| Practical 3, rose stem | Verified for the `scripts` group, with the lfric-env-isambard site patch (see below) |
| Global practicals (u-dz612) | **Cannot run**: coupled GC6 (UM, NEMO, SI3) and Met Office data. Tabs say so. #24 |
| Regional practicals (u-by395) | **Cannot run**: UM-driven nesting suite needing operational analyses. Tabs say so. #25 |
| Idealised practicals (u-dz791) | Verified with lfric-env-isambard's `run-suite.sh u-dz791` (see below) |

### Practical 1 details

- Upstream `lfric_apps` (tested at `aef51e27`) compiles **unpatched** with the
  module; none of lfric-env-isambard's `patches/` were needed.
- `local_build.py` clones lfric_core and the physics repositories from
  `git@github.com:` URLs, which need a GitHub SSH key. The docs set
  `GIT_CONFIG_COUNT/KEY_0/VALUE_0` to rewrite them to HTTPS (all are
  public). This avoids changing the learner's global git config.
- Like the other platforms' tabs, Practical 1 compiles and runs on the login
  node (2026-10-08, v2026.10.08). A from-scratch `-j 16` build took 247 s,
  peaking at 7.3 GB for the whole user cgroup; the run takes about 5 s with
  `OMP_NUM_THREADS=4`. The earlier slow login-node run (timestep 35 of 72
  after 5 minutes) was OpenMP starting 144 threads, not the login node.
  Earlier versions of the page used `srun` for both.

### Practical 2 details

- `MetOffice/momentum_user_training.example_lfric_workflow` is private (404
  for us). Training PR #183 introduced it as a "temporary fix" replacing
  `rosie co u-dn674`. The Isambard 3 tab uses u-dn704 (GAL9 at C12, same task
  graph), checked out at r361458 and launched with lfric-env-isambard's
  `examples/science-suites/run-suite.sh`, from a plain clone (no submodules).
- Run `u-dn704/run7`: extract, build_mesh, build_lfric_atm (9 min),
  generate_mesh, lfric_atm (43 s on 2 nodes) all succeeded; 144 timesteps,
  29 NetCDF files in `work/1/lfric_atm`. Re-verified 2026-10-01 after the
  XIOS rebuild (trainee `run1`): same result.
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

### Idealised practicals (u-dz791)

- Tested as a trainee on 2026-09-30: throwaway `HOME` on scratch with no
  `~/.cylc`, a pristine `svn checkout -r 368986` of u-dz791 (via
  `LFRIC_SUITE_DIR`), and a plain clone of lfric-env-isambard.
- The stager needs LFRic rose metadata for `rose app-upgrade`. Since #51 the
  module exports it as `LFRIC_ROSE_META_PATH`, so a plain clone is enough
  (verified 2026-10-01; the launcher prints `rose-meta: the environment's`).
  Before that the clone needed `git submodule update --init` for three
  vendored trees.
- Trainees **check out** rather than `rosie copy`: upstream u-dz791 builds
  2026.03.1 from a private Met Office path, and the stager is pinned to the
  upstream revision.
- Run 1 (control): extract, builds, mesh, and both 30-minute cycles
  succeeded. Output: `work/<cycle>/lfric_atm/lfric_crm_diag_*.nc`, one
  time per 10-minute file.
- Full trainee pass on 2026-10-01 (02:00-02:40 UTC): new `HOME` and
  `SCRATCHDIR`, real `rosie checkout`s with MOSRS cached, plain clone of
  lfric-env-isambard at `8fd78f8`, lfric_apps `main` @ `d2b54a76`. All passed:
  Practical 1 (build, run, hint edit, rebuild, 72 hint lines with step 72
  "ENJOY THE MODEL TUTORIAL"); Practical 2 u-dn704 run2 (full run, then
  `timestep_end=72` rerun: step 72, 17 files instead of 29); Practical 3
  `scripts` 12/12, then a trailing space fails `style_checker` and
  `fortitude_linter`; u-dz791 run10 (control) and run11 (Experiment 2); page
  05 code on both (all 11 blocks).
- Experiment 2 (page 08) edits `LFRIC_LEVS` in `rose-suite.conf`. That line
  is context in the site patch's `rose-suite.conf` hunk, so the stager's
  "already staged" reverse check fails and `run-suite.sh` stops with "site
  patch does not apply" (lfric-env-isambard #53). The page's Isambard 3 note
  passed it instead: `run-suite.sh u-dz791 -S "LFRIC_LEVS='uniform_l100_75km'"`
  (run11 has 100 levels). Fixed by lfric-env-isambard PR #57 (main `f4f96b9`
  or later): on 2026-10-08 a fresh learner edited `LFRIC_LEVS` in
  `rose-suite.conf` and `run-suite.sh u-dz791` relaunched it (run15), so the
  note was dropped. run15's jobs had not left the queue when this was
  written. App-config edits (Experiments 1 and 3) are fine.
- Run 9 (2026-10-01, after the XIOS rebuild, plain clone): both cycles
  succeeded; build_lfric_atm 11.5 min, each lfric_atm cycle about 1.6 min.
  Page 05's code runs on it unchanged.
- Re-running after an edit (run 2, `rotating=.true.`, both cycles succeeded):
  `run-suite.sh u-dz791` again recognises the
  staged checkout, keeps the edit and starts a new run.
- Every key the experiments edit (`rotating`, `cp`, `rd`, `perturb_*`, the
  `initial_vapour` opt block, `LFRIC_LEVS=uniform_l100_75km`) exists after
  the vn3.2 upgrade.
- Plotting page (05): its code used to fail on this output on any platform
  (a single-file load then `time_step = 30`, and slice/profile blocks indexing
  unstructured cubes). Fixed on this branch: it loads every
  `lfric_crm_diag_*.nc`, promotes the auxiliary `time` coordinate and
  equalises attributes before `concatenate()` (times are 600 to 3600 s), and
  reshapes the whole CubeList to x/y. All 11 blocks, including the
  animation, run on run 1 in the Python env.
- Experiment 3 (09) named `perturb_init` (a logical) as the value to change;
  fixed to `perturb_magnitude` (1 in the workflow). Not run on Isambard 3.

### Practical 3 details

- Needs `patches/rose-stem/lfric_apps-isambard3-site.patch` from
  lfric-env-isambard applied to the learner's `lfric_apps` clone (#19, #20).
  It targets lfric_apps `main`; validated there at `801edbfa`, and it still
  applied at `2a3e9b1d`. It will need refreshing as `main` moves.
- The patch now sets `USE_TOKENS` itself (#40), so dependencies are cloned
  over HTTPS without a GitHub key. Re-verified 2026-09-30 with a throwaway
  `HOME` on scratch (no `~/.cylc`): the module supplies the `isambard3`
  platform (#31). An earlier check set an empty `CYLC_CONF_PATH`, which also
  hides the module's site config, so it did not test #31.
- Since #54, `style_checker` fails in every run with
  `'stylist' is not a package` (lfric-env-isambard #55). Cylc's job script
  appends `:${PYTHONPATH:-}`, so an unset `PYTHONPATH` adds an empty entry,
  which puts the task's work directory, and the app's `stylist.py` config,
  ahead of the `stylist` package. Broadcasting
  `[environment]PYTHONPATH=${PYTHONPATH%:}` to the tasks fixes it (run4
  retriggered: 12/12; run5 with the trailing space: the expected failures).
  Fixed by lfric-env-isambard PR #56 (rebuilt in place on 2026-10-01): the
  module's cylc-flow appends `PYTHONPATH` only when it is non-empty, and the
  module still does not set it. Re-verified as a fresh trainee with
  `PYTHONPATH` unset: run6 12/12; run7 with the trailing space fails only
  `style_checker` ("Found trailing white space") and `fortitude_linter`. Runs
  installed before the rebuild keep the old `.service/etc/job.sh`.
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
| [#46](https://github.com/ickc/lfric-env-isambard/issues/46) | Shared, non-personal release prefix (done in v2026.10.08) |
| [#53](https://github.com/ickc/lfric-env-isambard/issues/53) | u-dz791 stager refuses to relaunch after `LFRIC_LEVS` edit (fixed) |
| [#59](https://github.com/ickc/lfric-env-isambard/issues/59) | Training mode: small shared-node model jobs for u-dz791 and u-dn704 |
| [#55](https://github.com/ickc/lfric-env-isambard/issues/55) | rose-stem `style_checker` failed after the module dropped `PYTHONPATH` (fixed) |

#18 to #23, #26, #27, #31, #40, #46, #53 and #55 are closed. #24 and #25 are blocked on Met
Office data (training issues #371, #372) and are postponed: the Met Office
plans a toy model for the global and regional practicals and is looking at
what could be moved to Isambard 3, but not in time for this course. The tabs
on those pages say they cannot run on Isambard 3.

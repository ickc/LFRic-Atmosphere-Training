#!/usr/bin/env bash
# Helper for maintaining a fork branch (this repo's "fork") alongside main,
# and for shepherding feature branches through a fork -> main PR.
#
# Workflow this supports:
#   1. Feature branch X is created off "fork" (which carries commits/files not on main).
#   2. `pr-create X` makes X-on-main: main plus just X's own commits (fork..X),
#      ready to open a PR against main.
#   3. As X and X-on-main evolve independently, `sync-up`/`sync-down` cherry-pick
#      only the genuinely new commits between them, using `git cherry` (patch-id
#      based) so already-ported commits are skipped automatically.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: fork-branch.sh <command> <branch> [base] [fork]

Commands:
  pr-create <branch> [base=main] [fork=fork]
      Create "<branch>-on-main" from <base>, containing the commits that
      <branch> has ahead of <fork> (i.e. <fork>..<branch>). Fails if the
      target branch already exists - use sync-up/sync-down after that.

  sync-up <branch> [base=main] [fork=fork]
      Cherry-pick commits in <fork>..<branch> whose patch content isn't
      already present in <base>..<branch>-on-main, onto <branch>-on-main.

  sync-down <branch> [base=main] [fork=fork]
      Cherry-pick commits in <base>..<branch>-on-main whose patch content
      isn't already present in <fork>..<branch>, onto <branch>.

  status <branch> [base=main] [fork=fork]
      Show, in both directions, which commits are new and which are already
      applied (by patch content) between <branch> and "<branch>-on-main". Read-only.

Commit comparison is by patch-id (diff content), not commit hash, and each
side's candidate commits are scoped to its own branch's history since it
diverged (<fork>..<branch> / <base>..<branch>-on-main) - not full ancestry -
so pre-existing fork/base commits are never mistaken for new feature commits.

On a cherry-pick conflict, git stops mid-pick as usual: resolve, then run
`git cherry-pick --continue` (or `--abort`), and re-run the sync command to
pick up any remaining commits.
EOF
}

require_branch() {
  local branch="$1"
  if ! git rev-parse --verify --quiet "refs/heads/${branch}" >/dev/null; then
    echo "error: branch '${branch}' does not exist" >&2
    exit 1
  fi
}

patch_id_of() {
  git show "$1" | git patch-id --stable | cut -d' ' -f1
}

# new_commits_in <candidate-range> <applied-range>
# Lists (oldest first) commits in <candidate-range> (e.g. "fork..branch")
# whose patch content does not already appear among commits in
# <applied-range> (e.g. "main..branch-on-main"). Comparison is scoped to
# each range explicitly, so it never reaches back past the fork/base point.
new_commits_in() {
  local candidate_range="$1" applied_range="$2"
  local applied_ids=""
  local c
  for c in $(git log --format=%H "${applied_range}" -- 2>/dev/null || true); do
    applied_ids+="$(patch_id_of "${c}")"$'\n'
  done

  for c in $(git log --reverse --format=%H "${candidate_range}" -- 2>/dev/null || true); do
    local pid
    pid=$(patch_id_of "${c}")
    if ! grep -qxF "${pid}" <<<"${applied_ids}"; then
      echo "${c}"
    fi
  done
}

cherry_pick_new_commits() {
  # cherry_pick_new_commits <candidate-range> <applied-range> <checkout-target>
  local candidate_range="$1" applied_range="$2" target="$3"
  local commits
  commits=$(new_commits_in "${candidate_range}" "${applied_range}")

  if [[ -z "${commits}" ]]; then
    echo "Nothing to do: no new commits in '${candidate_range}' relative to '${applied_range}'."
    return 0
  fi

  echo "Cherry-picking onto '${target}':"
  echo "${commits}" | while read -r sha; do
    echo "  ${sha} $(git log -1 --format=%s "${sha}")"
  done

  git checkout "${target}"
  echo "${commits}" | xargs git cherry-pick
}

cmd_pr_create() {
  local branch="$1" base="${2:-main}" fork="${3:-fork}"
  local pr_branch="${branch}-on-main"

  require_branch "${branch}"
  require_branch "${base}"
  require_branch "${fork}"

  if git rev-parse --verify --quiet "refs/heads/${pr_branch}" >/dev/null; then
    echo "error: '${pr_branch}' already exists. Use 'sync-up'/'sync-down' to keep it in sync instead." >&2
    exit 1
  fi

  local commits
  commits=$(git log --reverse --format=%H "${fork}..${branch}")
  if [[ -z "${commits}" ]]; then
    echo "error: '${branch}' has no commits ahead of '${fork}' - nothing to put in a PR." >&2
    exit 1
  fi

  echo "Creating '${pr_branch}' from '${base}' with commits from '${fork}..${branch}':"
  echo "${commits}" | while read -r sha; do
    echo "  ${sha} $(git log -1 --format=%s "${sha}")"
  done

  git checkout -b "${pr_branch}" "${base}"
  echo "${commits}" | xargs git cherry-pick
}

cmd_sync_up() {
  local branch="$1" base="${2:-main}" fork="${3:-fork}"
  local pr_branch="${branch}-on-main"
  require_branch "${branch}"
  require_branch "${pr_branch}"
  require_branch "${fork}"
  require_branch "${base}"
  cherry_pick_new_commits "${fork}..${branch}" "${base}..${pr_branch}" "${pr_branch}"
}

cmd_sync_down() {
  local branch="$1" base="${2:-main}" fork="${3:-fork}"
  local pr_branch="${branch}-on-main"
  require_branch "${branch}"
  require_branch "${pr_branch}"
  require_branch "${fork}"
  require_branch "${base}"
  cherry_pick_new_commits "${base}..${pr_branch}" "${fork}..${branch}" "${branch}"
}

cmd_status() {
  local branch="$1" base="${2:-main}" fork="${3:-fork}"
  local pr_branch="${branch}-on-main"
  require_branch "${branch}"
  require_branch "${pr_branch}"
  require_branch "${fork}"
  require_branch "${base}"

  echo "New on '${branch}' (not yet in '${pr_branch}'):"
  local up
  up=$(new_commits_in "${fork}..${branch}" "${base}..${pr_branch}")
  if [[ -z "${up}" ]]; then echo "  (none)"; else echo "${up}" | while read -r sha; do echo "  ${sha} $(git log -1 --format=%s "${sha}")"; done; fi

  echo
  echo "New on '${pr_branch}' (not yet in '${branch}'):"
  local down
  down=$(new_commits_in "${base}..${pr_branch}" "${fork}..${branch}")
  if [[ -z "${down}" ]]; then echo "  (none)"; else echo "${down}" | while read -r sha; do echo "  ${sha} $(git log -1 --format=%s "${sha}")"; done; fi
}

main() {
  local command="${1:-}"
  case "${command}" in
    pr-create) shift; [[ $# -ge 1 ]] || { usage; exit 1; }; cmd_pr_create "$@" ;;
    sync-up)   shift; [[ $# -ge 1 ]] || { usage; exit 1; }; cmd_sync_up "$@" ;;
    sync-down) shift; [[ $# -ge 1 ]] || { usage; exit 1; }; cmd_sync_down "$@" ;;
    status)    shift; [[ $# -ge 1 ]] || { usage; exit 1; }; cmd_status "$@" ;;
    -h|--help|"") usage ;;
    *) echo "error: unknown command '${command}'" >&2; usage; exit 1 ;;
  esac
}

main "$@"

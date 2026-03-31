# ── Git section ─────────────────────────────────────────────
# Sourced by scripts/statusline — not executable on its own.
# Requires: CONTEXT_DIR, color variables, compact_num()

git_section() {
  # Guard: are we inside a git repo?
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return
  fi

  local git_dir
  git_dir=$(git rev-parse --git-dir 2>/dev/null)

  # -- Core parse: branch, ahead/behind, staged/unstaged/untracked/conflicts --
  local branch="" ahead=0 behind=0 staged=0 unstaged=0 untracked=0 conflicts=0
  local detached=false has_commits=true

  local status_output
  status_output=$(git status --porcelain=v2 --branch 2>/dev/null) || true

  # Check for fresh repo (no commits yet)
  if echo "$status_output" | grep -q "^# branch.oid (initial)"; then
    has_commits=false
  fi

  # Parse with a single perl pass
  eval "$(echo "$status_output" | perl -e '
    my ($br, $ah, $bh, $st, $us, $ut, $cf) = ("", 0, 0, 0, 0, 0, 0);
    while (<STDIN>) {
      if (/^# branch\.head (.+)/) {
        $br = $1;
      } elsif (/^# branch\.ab \+(\d+) -(\d+)/) {
        ($ah, $bh) = ($1, $2);
      } elsif (/^[12] (.)(.)/) {
        my ($x, $y) = ($1, $2);
        if ($x eq "U" || $y eq "U" || ($x eq "A" && $y eq "A") || ($x eq "D" && $y eq "D")) {
          $cf++;
        } else {
          $st++ if $x ne ".";
          $us++ if $y ne ".";
        }
      } elsif (/^u /) {
        $cf++;
      } elsif (/^\? /) {
        $ut++;
      }
    }
    print "branch=\"$br\" ahead=$ah behind=$bh staged=$st unstaged=$us untracked=$ut conflicts=$cf\n";
  ')"

  # Handle detached HEAD
  if [ "$branch" = "(detached)" ]; then
    detached=true
    branch="@$(git rev-parse --short HEAD 2>/dev/null || echo '???')"
  fi

  # Handle fresh repo
  if [ "$has_commits" = false ]; then
    branch="(init)"
  fi

  # Truncate branch name to 20 chars
  if [ "${#branch}" -gt 20 ]; then
    branch="${branch:0:20}…"
  fi

  # -- Operation state --
  local operation=""
  if [ -d "${git_dir}/rebase-merge" ] || [ -d "${git_dir}/rebase-apply" ]; then
    operation="REBASING"
  elif [ -f "${git_dir}/MERGE_HEAD" ]; then
    operation="MERGING"
  elif [ -f "${git_dir}/CHERRY_PICK_HEAD" ]; then
    operation="PICKING"
  elif [ -f "${git_dir}/BISECT_LOG" ]; then
    operation="BISECTING"
  fi

  # -- Diff stats (only when dirty) --
  local diff_add=0 diff_del=0
  local is_dirty=false
  if [ "$staged" -gt 0 ] || [ "$unstaged" -gt 0 ] || [ "$conflicts" -gt 0 ]; then
    is_dirty=true
  fi

  if [ "$is_dirty" = true ] && [ "$has_commits" = true ]; then
    eval "$(git diff HEAD --numstat 2>/dev/null | perl -e '
      my ($a, $d) = (0, 0);
      while (<STDIN>) {
        my @f = split /\t/;
        next if $f[0] eq "-";  # binary files
        $a += $f[0];
        $d += $f[1];
      }
      print "diff_add=$a diff_del=$d\n";
    ')"
  fi

  # -- Stash count --
  local stash=0
  stash=$(git stash list 2>/dev/null | wc -l | tr -d ' ')

  # -- Worktree info --
  local wt_count=0 wt_name=""
  local wt_output
  wt_output=$(git worktree list 2>/dev/null) || true
  if [ -n "$wt_output" ]; then
    wt_count=$(echo "$wt_output" | wc -l | tr -d ' ')
  fi
  local wt_main_path wt_current_path
  wt_main_path=$(echo "$wt_output" | head -1 | awk '{print $1}')
  wt_current_path=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ "$wt_current_path" = "$wt_main_path" ]; then
    wt_name="main"
  else
    wt_name=$(basename "$wt_current_path")
  fi
  [ "${#wt_name}" -gt 15 ] && wt_name="${wt_name:0:15}..."

  # -- Branch counts (cached 30s) --
  local branches=0 unmerged=0
  local repo_hash
  repo_hash=$(echo "$PWD" | perl -MDigest::MD5=md5_hex -ne 'chomp; print md5_hex($_)')
  local cache_file="${CONTEXT_DIR}/.git-branches-${repo_hash}"
  local cache_age=999

  if [ -f "$cache_file" ]; then
    local now
    now=$(date +%s)
    local mtime
    mtime=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo 0)
    cache_age=$(( now - mtime ))
  fi

  if [ "$cache_age" -le 30 ] && [ -f "$cache_file" ]; then
    eval "$(cat "$cache_file")"
  else
    branches=$(git for-each-ref refs/heads/ --format='x' 2>/dev/null | wc -l | tr -d ' ')
    # Check for unmerged branches — only if a main/master branch exists
    local main_branch=""
    if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
      main_branch="main"
    elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
      main_branch="master"
    fi
    if [ -n "$main_branch" ]; then
      unmerged=$(git branch --no-merged "$main_branch" 2>/dev/null | wc -l | tr -d ' ')
    fi
    echo "branches=$branches unmerged=$unmerged" > "$cache_file"
  fi

  # -- Assemble output --
  local out="🌿 "

  # Branch name (red if detached, white otherwise)
  if [ "$detached" = true ]; then
    out="${out}${RED}${branch}${RESET}"
  else
    out="${out}${branch}"
  fi

  # Worktree indicator
  out="${out}  ${DIM}🌳 ${wt_count}wt·${wt_name}${RESET}"

  # Operation state
  if [ -n "$operation" ]; then
    out="${out}  ${MAGENTA}🔀 ${operation}${RESET}"
  fi

  # Clean check — everything zero and no operation
  local is_clean=true
  if [ "$staged" -gt 0 ] || [ "$unstaged" -gt 0 ] || [ "$untracked" -gt 0 ] || \
     [ "$conflicts" -gt 0 ] || [ "$ahead" -gt 0 ] || [ "$behind" -gt 0 ] || \
     [ -n "$operation" ]; then
    is_clean=false
  fi

  if [ "$is_clean" = true ]; then
    out="${out} ${GREEN}✅${RESET}"
  else
    # Push/pull
    [ "$ahead" -gt 0 ]    && out="${out}  ${GREEN}⬆ ${ahead} push${RESET}"
    [ "$behind" -gt 0 ]   && out="${out}  ${RED}⬇ ${behind} pull${RESET}"

    # Conflicts (highest priority problem)
    [ "$conflicts" -gt 0 ] && out="${out}  ${RED}${BOLD}💥 ${conflicts} conflicts${RESET}"

    # File states
    [ "$staged" -gt 0 ]    && out="${out}  ${GREEN}✏️ ${staged} staged${RESET}"
    [ "$unstaged" -gt 0 ]  && out="${out}  ${YELLOW}📝 ${unstaged} changed${RESET}"
    [ "$untracked" -gt 0 ] && out="${out}  ${DIM}📄 ${untracked} new${RESET}"

    # Diff lines
    if [ "$diff_add" -gt 0 ] || [ "$diff_del" -gt 0 ]; then
      out="${out}  ${GREEN}+$(compact_num $diff_add)${RESET} ${RED}−$(compact_num $diff_del)${RESET}"
    fi
  fi

  # Stash (shown regardless of clean/dirty)
  [ "$stash" -gt 0 ]   && out="${out}  ${DIM}📦 ${stash} stash${RESET}"

  # Unmerged branches (shown regardless of clean/dirty)
  [ "$unmerged" -gt 0 ] && out="${out}  ${YELLOW}⚠️ ${unmerged} unmerged${RESET}"

  # Export for context.json
  _git_branch="$branch"
  _git_ahead="$ahead"
  _git_behind="$behind"
  _git_staged="$staged"
  _git_unstaged="$unstaged"
  _git_untracked="$untracked"
  _git_conflicts="$conflicts"
  _git_stash="$stash"
  _git_diff_add="$diff_add"
  _git_diff_del="$diff_del"
  _git_branches="$branches"
  _git_unmerged="$unmerged"
  _git_operation="$operation"
  _git_worktree_count="$wt_count"
  _git_worktree_name="$wt_name"

  git="$out"
}

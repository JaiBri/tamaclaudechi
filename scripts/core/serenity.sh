# tamaclaudechi - Serenity computation from git repo state

# --- Serenity: inspect a single git repo ---
# Returns: adjustment dirty_count branch_count merged_count diff_insertions diff_deletions last_commit_ago_secs in_git_repo
_compute_serenity_single_repo() {
  local repo_dir="${1:-.}"
  local adjustment=0

  # Only run git commands if it's a git repo
  if ! (cd "$repo_dir" && git rev-parse --is-inside-work-tree &>/dev/null); then
    echo "0 0 0 0 0 0 0 false"
    return
  fi

  # Count dirty files
  local dirty_count
  dirty_count=$(cd "$repo_dir" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$dirty_count" -eq 0 ]; then
    adjustment=$((adjustment + 15))
  else
    adjustment=$((adjustment - 2 * (dirty_count / 10 + (dirty_count % 10 > 0 ? 1 : 0)) ))
  fi

  # Count open branches
  local branch_count
  branch_count=$(cd "$repo_dir" && git branch 2>/dev/null | wc -l | tr -d ' ')
  if [ "$branch_count" -le 2 ]; then
    adjustment=$((adjustment + 10))
  elif [ "$branch_count" -gt 3 ]; then
    adjustment=$((adjustment - 3 * (branch_count - 3) ))
  fi

  # Count merged branches not deleted (excluding main/master/current)
  local merged_count
  merged_count=$(cd "$repo_dir" && git branch --merged 2>/dev/null | grep -v '^\*' | grep -v -E '^\s*(main|master|develop)\s*$' | wc -l | tr -d ' ')
  if [ "$merged_count" -gt 0 ]; then
    adjustment=$((adjustment - 5 * merged_count))
  fi

  # Check uncommitted diff size
  local diff_insertions diff_deletions
  diff_insertions=$(cd "$repo_dir" && git diff --stat 2>/dev/null | tail -1 | perl -ne 'print $1 if /(\d+) insertion/' || echo "0")
  diff_deletions=$(cd "$repo_dir" && git diff --stat 2>/dev/null | tail -1 | perl -ne 'print $1 if /(\d+) deletion/' || echo "0")
  diff_insertions=${diff_insertions:-0}
  diff_deletions=${diff_deletions:-0}
  local total_diff=$(( diff_insertions + diff_deletions ))
  if [ "$total_diff" -gt 500 ]; then
    adjustment=$((adjustment - 8))
  fi

  # Recent commit time
  local last_commit_epoch now_ep last_commit_ago
  last_commit_epoch=$(cd "$repo_dir" && git log -1 --format='%ct' 2>/dev/null || echo "0")
  now_ep=$(now_epoch)
  last_commit_ago=$(( now_ep - ${last_commit_epoch:-0} ))
  if [ "${last_commit_epoch:-0}" -gt 0 ] && [ "$last_commit_ago" -lt 3600 ]; then
    adjustment=$((adjustment + 5))
  fi

  echo "$adjustment $dirty_count $branch_count $merged_count $diff_insertions $diff_deletions $last_commit_ago true"
}

# --- Serenity: inspect git state (multi-repo aware) ---
# Returns: adjustment dirty_count branch_count merged_count diff_insertions diff_deletions last_commit_ago_secs in_git_repo
compute_serenity_from_git() {
  ensure_config

  # Read configured repo roots
  local roots_json
  roots_json=$(config_repo_roots)
  local paths=()
  while IFS= read -r p; do
    [ -n "$p" ] && [ -d "$p" ] && paths+=("$p")
  done < <(echo "$roots_json" | perl -ne 'while (/"([^"]+)"/g) { print "$1\n" }')

  # If no configured roots, fall back to script's own repo
  if [ ${#paths[@]} -eq 0 ]; then
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # Walk up from script dir to find a git root
    local d="$script_dir"
    while [ "$d" != "/" ]; do
      if (cd "$d" && git rev-parse --is-inside-work-tree &>/dev/null); then
        _compute_serenity_single_repo "$d"
        return
      fi
      d=$(dirname "$d")
    done
    # No git found anywhere
    echo "0 0 0 0 0 0 0 false"
    return
  fi

  # Iterate roots, aggregate results
  local total_adj=0 total_dirty=0 total_branches=0 total_merged=0
  local total_ins=0 total_del=0 min_commit_ago=999999999 any_git=false
  local count=0

  for root in "${paths[@]}"; do
    local result
    result=$(_compute_serenity_single_repo "$root")
    local adj dc bc mc di dd lca igr
    read -r adj dc bc mc di dd lca igr <<< "$result"
    if [ "$igr" = "true" ]; then
      any_git=true
      total_adj=$((total_adj + adj))
      total_dirty=$((total_dirty + dc))
      total_branches=$((total_branches + bc))
      total_merged=$((total_merged + mc))
      total_ins=$((total_ins + di))
      total_del=$((total_del + dd))
      [ "$lca" -lt "$min_commit_ago" ] && min_commit_ago="$lca"
      count=$((count + 1))
    fi
  done

  if [ "$any_git" = "false" ] || [ "$count" -eq 0 ]; then
    echo "0 0 0 0 0 0 0 false"
    return
  fi

  # Average the adjustment across repos
  local avg_adj=$((total_adj / count))
  echo "$avg_adj $total_dirty $total_branches $total_merged $total_ins $total_del $min_commit_ago true"
}

# --- Serenity: convert git adjustment to convergence target ---
# Returns target score (0-100) and sets _d_* detail variables
compute_serenity_target() {
  local result
  result=$(compute_serenity_from_git)
  local adj
  read -r adj _d_dirty_count _d_branch_count _d_merged_count _d_diff_insertions _d_diff_deletions _d_last_commit_ago _d_in_git_repo <<< "$result"

  if [ "$_d_in_git_repo" != "true" ]; then
    echo "-1"  # Sentinel: no git, don't converge
    return
  fi

  # Convert adjustment (-30 to +30) into a 0-100 target score
  # Clean repo: adj ~+30 → target ~80; messy repo: adj ~-20 → target ~30
  local target=$((50 + adj))
  [ "$target" -lt 10 ] && target=10
  [ "$target" -gt 95 ] && target=95
  echo "$target"
}

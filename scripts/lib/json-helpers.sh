# tamaclaudechi - JSON parsing helpers (pure bash/perl, no jq dependency)

# Read a scalar value from STATE_FILE by key
json_val() {
  local key="$1"
  perl -ne '
    while (/"'"$key"'"\s*:\s*("(?:[^"\\]|\\.)*"|-?[0-9.]+|true|false|null)/g) {
      my $v = $1;
      $v =~ s/^"|"$//g;
      print "$v\n";
      last;
    }
  ' "$STATE_FILE" | head -1
}

# Alias — read a stat value (same implementation)
stat_val() {
  json_val "$1"
}

# Read a JSON array value (returns the raw JSON array string)
json_array_val() {
  local key="$1"
  perl -0777 -ne '
    if (/"'"$key"'"\s*:\s*(\[.*?\])/s) {
      print $1;
    } else {
      print "[]";
    }
  ' "$STATE_FILE"
}

# Read a scalar value from CONFIG_FILE by key
config_val() {
  local key="$1"
  perl -ne '
    while (/"'"$key"'"\s*:\s*("(?:[^"\\]|\\.)*"|-?[0-9.]+|true|false|null)/g) {
      my $v = $1;
      $v =~ s/^"|"$//g;
      print "$v\n";
      last;
    }
  ' "$CONFIG_FILE" | head -1
}

# Read the repoRoots JSON array from CONFIG_FILE
config_repo_roots() {
  perl -0777 -ne '
    if (/"repoRoots"\s*:\s*(\[.*?\])/s) {
      print $1;
    } else {
      print "[]";
    }
  ' "$CONFIG_FILE"
}

# Add a path to repoRoots in CONFIG_FILE
config_repo_roots_add() {
  local path="$1"
  # Validate directory exists
  if [ ! -d "$path" ]; then
    echo "Error: directory does not exist: $path" >&2
    return 1
  fi
  # Resolve to absolute path
  path=$(cd "$path" && pwd)
  # Check for duplicates
  local existing
  existing=$(config_repo_roots)
  if echo "$existing" | grep -q "\"$path\""; then
    echo "Path already in repoRoots: $path" >&2
    return 0
  fi
  # Rewrite config with new path appended using env var to avoid quoting issues
  ADDPATH="$path" perl -i -0777 -pe '
    my $p = $ENV{ADDPATH};
    if (/"repoRoots"\s*:\s*\[(.*?)\]/s) {
      my $inner = $1;
      $inner =~ s/^\s+|\s+$//g;
      if ($inner eq "") {
        s/"repoRoots"\s*:\s*\[.*?\]/"repoRoots": ["$p"]/s;
      } else {
        s/"repoRoots"\s*:\s*\[.*?\]/"repoRoots": [$inner, "$p"]/s;
      }
    }
  ' "$CONFIG_FILE"
}

# Remove a path from repoRoots in CONFIG_FILE
config_repo_roots_remove() {
  local path="$1"
  RMPATH="$path" perl -i -0777 -pe '
    my $p = $ENV{RMPATH};
    if (/"repoRoots"\s*:\s*\[(.*?)\]/s) {
      my $inner = $1;
      my @items;
      while ($inner =~ /"([^"]+)"/g) {
        push @items, $1 unless $1 eq $p;
      }
      my $new = join(", ", map { "\"$_\"" } @items);
      s/"repoRoots"\s*:\s*\[.*?\]/"repoRoots": [$new]/s;
    }
  ' "$CONFIG_FILE"
}

# Scan configured repo roots for .claude/git status
config_repo_roots_scan() {
  local roots_json
  roots_json=$(config_repo_roots)
  local paths=()
  while IFS= read -r p; do
    [ -n "$p" ] && paths+=("$p")
  done < <(echo "$roots_json" | perl -ne 'while (/"([^"]+)"/g) { print "$1\n" }')

  echo "["
  local first=true
  for p in "${paths[@]}"; do
    local has_claude=false is_git=false
    [ -d "$p/.claude" ] && has_claude=true
    [ -d "$p/.git" ] && is_git=true
    if [ "$first" = true ]; then
      first=false
    else
      echo ","
    fi
    printf '  {"path": "%s", "hasClaudeDir": %s, "isGitRepo": %s}' "$p" "$has_claude" "$is_git"
  done
  echo ""
  echo "]"
}

# Read usage.json and return: session_pct session_elapsed_pct week_all_pct week_all_elapsed_pct
# Returns empty string if file missing or stale (>30 min)
read_usage_json() {
  local usage_file="$STATE_DIR/usage.json"
  [ -f "$usage_file" ] || return 1

  # Check staleness (30 min = 1800 sec)
  local file_epoch now_ep
  file_epoch=$(stat -f %m "$usage_file" 2>/dev/null || echo 0)
  now_ep=$(date +%s)
  [ $(( now_ep - file_epoch )) -gt 1800 ] && return 1

  perl -0777 -ne '
    my ($sp, $se, $wp, $we) = (0, 0, 0, 0);
    $sp = $1 if /"session_pct"\s*:\s*(-?[0-9.]+)/;
    $se = $1 if /"session_elapsed_pct"\s*:\s*(-?[0-9.]+)/;
    $wp = $1 if /"week_all_pct"\s*:\s*(-?[0-9.]+)/;
    $we = $1 if /"week_all_elapsed_pct"\s*:\s*(-?[0-9.]+)/;
    print "$sp $se $wp $we\n";
  ' "$usage_file"
}

# Read system.json and return: cpu ram swap disk gpu (all 0-100 percentages)
# Returns empty string if file missing or stale (>10 min)
read_system_json() {
  local system_file="$STATE_DIR/system.json"
  [ -f "$system_file" ] || return 1

  # Check staleness (10 min = 600 sec)
  local file_epoch now_ep
  file_epoch=$(stat -f %m "$system_file" 2>/dev/null || echo 0)
  now_ep=$(date +%s)
  [ $(( now_ep - file_epoch )) -gt 600 ] && return 1

  perl -0777 -ne '
    my ($cpu, $ram, $swap, $disk, $gpu) = (0, 0, 0, 0, 0);
    $cpu = $1 if /"cpu"\s*:\s*(-?[0-9.]+)/;
    $ram = $1 if /"ram"\s*:\s*(-?[0-9.]+)/;
    $swap = $1 if /"swap"\s*:\s*(-?[0-9.]+)/;
    $disk = $1 if /"disk"\s*:\s*(-?[0-9.]+)/;
    $gpu = $1 if /"gpu"\s*:\s*(-?[0-9.]+)/;
    printf "%d %d %d %d %d\n", $cpu, $ram, $swap, $disk, $gpu;
  ' "$system_file"
}

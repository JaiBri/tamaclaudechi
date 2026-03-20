# ── Usage section ──────────────────────────────────────────
# Sourced by scripts/statusline — not executable on its own.
# Requires: CONTEXT_DIR, color variables

# Pace delta display: usage_pct - elapsed_pct
# Positive = ahead (burning fast, chill) -> yellow/red
# Negative = behind (room to spare, prompt more) -> green
pace_delta_display() {
  local usage_pct=$1 elapsed_pct=${2:-}

  # No elapsed data or elapsed is 0 -> skip delta
  if [ -z "$elapsed_pct" ] || [ "$elapsed_pct" -eq 0 ]; then
    echo ""
    return
  fi

  local delta=$(( usage_pct - elapsed_pct ))
  local color="" sign=""

  if [ "$delta" -le -10 ]; then
    color="$GREEN"                    # well behind pace — lots of room, prompt more
  elif [ "$delta" -ge 25 ]; then
    color="$RED"; sign="+"            # way ahead — chill out
  elif [ "$delta" -ge 10 ]; then
    color="$YELLOW"; sign="+"         # ahead — ease off a bit
  else
    color="$DIM"
    [ "$delta" -gt 0 ] && sign="+"
  fi

  echo "${color}(${sign}${delta})${RESET}"
}

usage_section() {
  local usage_file="${CONTEXT_DIR}/usage.json"
  [ ! -f "$usage_file" ] && return

  # Staleness check: skip if > 15 min old
  local now mtime
  now=$(date +%s)
  mtime=$(stat -f %m "$usage_file" 2>/dev/null || stat -c %Y "$usage_file" 2>/dev/null || echo 0)
  [ $(( now - mtime )) -gt 900 ] && return

  # Parse fields with perl (single pass) — includes countdown computation
  eval "$(perl -e '
    use POSIX qw(mktime);
    my %vals;
    open my $fh, "<", $ARGV[0] or exit;
    while (<$fh>) {
      $vals{session_pct}     = $1 if /"session_pct"\s*:\s*(\d+)/;
      $vals{sess_elapsed}    = $1 if /"session_elapsed_pct"\s*:\s*(\d+)/;
      $vals{week_pct}        = $1 if /"week_all_pct"\s*:\s*(\d+)/;
      $vals{week_elapsed}    = $1 if /"week_all_elapsed_pct"\s*:\s*(\d+)/;
      $vals{extra_spent}     = $1 if /"extra_spent"\s*:\s*([0-9.]+)/;
      $vals{extra_budget}    = $1 if /"extra_budget"\s*:\s*([0-9.]+)/;
      $vals{sess_resets}     = $1 if /"session_resets"\s*:\s*"([^"]*)"/;
      $vals{week_resets}     = $1 if /"week_all_resets"\s*:\s*"([^"]*)"/;
      $vals{scraped_at}      = $1 if /"scraped_at"\s*:\s*"([^"]*)"/;
    }
    close $fh;

    # Print basic vars
    for my $k (qw(session_pct sess_elapsed week_pct week_elapsed extra_spent extra_budget scraped_at)) {
      my $prefix = {session_pct=>"u_sess_pct", sess_elapsed=>"u_sess_elapsed",
                    week_pct=>"u_week_pct", week_elapsed=>"u_week_elapsed",
                    extra_spent=>"u_extra_spent", extra_budget=>"u_extra_budget",
                    scraped_at=>"u_scraped_at"}->{$k};
      if (defined $vals{$k}) {
        my $v = $vals{$k};
        $v = "\"$v\"" if $k eq "scraped_at";
        print "$prefix=$v\n";
      }
    }
    for my $k (qw(sess_resets week_resets)) {
      my $prefix = $k eq "sess_resets" ? "u_sess_resets" : "u_week_resets";
      print "$prefix=\"$vals{$k}\"\n" if defined $vals{$k};
    }

    # Compute countdowns
    my $now = time();

    # Helper: format seconds as compact countdown
    sub fmt_countdown {
      my $secs = shift;
      return "" if $secs <= 0;
      my $d = int($secs / 86400);
      my $h = int(($secs % 86400) / 3600);
      my $m = int(($secs % 3600) / 60);
      if ($d > 0) { return "${d}d${h}h" }
      elsif ($h > 0) { return "${h}h${m}m" }
      else { return "${m}m" }
    }

    # Session countdown: parse "1:59pm" or "2pm"
    if (defined $vals{sess_resets} && $vals{sess_resets} =~ /^(\d+)(?::(\d+))?(am|pm)$/i) {
      my ($h, $m, $ampm) = ($1, $2 // 0, lc($3));
      $h = $h % 12;
      $h += 12 if $ampm eq "pm";
      my @lt = localtime($now);
      my $reset = mktime(0, $m, $h, $lt[3], $lt[4], $lt[5]);
      $reset += 86400 if $reset < $now;
      my $cd = fmt_countdown($reset - $now);
      print "u_sess_countdown=\"$cd\"\n" if $cd;
    }

    # Week countdown: parse "Mar 23 at 10am" or "Mar 23 at 9:59am"
    if (defined $vals{week_resets} && $vals{week_resets} =~ /^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d+)\s+at\s+(\d+)(?::(\d+))?(am|pm)$/i) {
      my %months = (Jan=>0,Feb=>1,Mar=>2,Apr=>3,May=>4,Jun=>5,Jul=>6,Aug=>7,Sep=>8,Oct=>9,Nov=>10,Dec=>11);
      my ($mon, $day, $h, $m, $ampm) = ($1, $2, $3, $4 // 0, lc($5));
      $h = $h % 12;
      $h += 12 if $ampm eq "pm";
      my @lt = localtime($now);
      my $reset = mktime(0, $m, $h, $day, $months{$mon}, $lt[5]);
      $reset = mktime(0, $m, $h, $day, $months{$mon}, $lt[5]+1) if $reset < $now;
      my $cd = fmt_countdown($reset - $now);
      print "u_week_countdown=\"$cd\"\n" if $cd;
    }
  ' "$usage_file")"

  # Need at least one percentage to show anything
  [ -z "${u_sess_pct:-}" ] && [ -z "${u_week_pct:-}" ] && return

  local out="📊 "
  local parts=()

  if [ -n "${u_week_pct:-}" ]; then
    local wpc="" wdelta wcd=""
    [ "$u_week_pct" -gt 90 ] && wpc="$RED"
    wdelta=$(pace_delta_display "$u_week_pct" "${u_week_elapsed:-}")
    [ -n "${u_week_countdown:-}" ] && wcd=" ${DIM}⟳${u_week_countdown}${RESET}"
    parts+=("${wpc}${u_week_pct}%${RESET} week${wdelta}${wcd}")
  fi

  if [ -n "${u_sess_pct:-}" ]; then
    local spc="" sdelta scd=""
    [ "$u_sess_pct" -gt 90 ] && spc="$RED"
    sdelta=$(pace_delta_display "$u_sess_pct" "${u_sess_elapsed:-}")
    [ -n "${u_sess_countdown:-}" ] && scd=" ${DIM}⟳${u_sess_countdown}${RESET}"
    parts+=("${spc}${u_sess_pct}%${RESET} sess${sdelta}${scd}")
  fi

  # Join parts with " · "
  local joined=""
  for i in "${!parts[@]}"; do
    [ "$i" -gt 0 ] && joined="${joined} · "
    joined="${joined}${parts[$i]}"
  done

  # Compute pace deltas for context.json
  _usage_session_pace_delta=""
  if [ -n "${u_sess_pct:-}" ] && [ -n "${u_sess_elapsed:-}" ] && [ "${u_sess_elapsed}" -gt 0 ]; then
    _usage_session_pace_delta=$(( u_sess_pct - u_sess_elapsed ))
  fi
  _usage_week_pace_delta=""
  if [ -n "${u_week_pct:-}" ] && [ -n "${u_week_elapsed:-}" ] && [ "${u_week_elapsed}" -gt 0 ]; then
    _usage_week_pace_delta=$(( u_week_pct - u_week_elapsed ))
  fi

  # Export for context.json
  _usage_session_pct="${u_sess_pct:-}"
  _usage_session_elapsed="${u_sess_elapsed:-}"
  _usage_session_resets="${u_sess_resets:-}"
  _usage_week_pct="${u_week_pct:-}"
  _usage_week_elapsed="${u_week_elapsed:-}"
  _usage_week_resets="${u_week_resets:-}"
  _usage_extra_spent="${u_extra_spent:-}"
  _usage_extra_budget="${u_extra_budget:-}"
  _usage_scraped_at="${u_scraped_at:-}"

  usage="${out}${joined}"
}

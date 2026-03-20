# tamaclaudechi - Usage command: system resource usage with personality

# --- System usage command ---
cmd_usage() {
  ensure_state

  # Run system-monitor synchronously for a fresh sample
  local monitor="${BASH_SOURCE[0]%/*}/../system-monitor"
  if [ -x "$monitor" ]; then
    "$monitor" 2>/dev/null
  fi

  local system_file="${STATE_DIR}/system.json"
  if [ ! -f "$system_file" ]; then
    echo "No system data available. Run: ${monitor}"
    return 1
  fi

  # Parse system.json — extract all metrics + top 3 CPU/RAM processes
  eval "$(perl -e '
    open my $fh, "<", $ARGV[0] or exit;
    my $json = do { local $/; <$fh> };
    close $fh;

    my ($cpu, $ram, $disk, $gpu, $swap, $swap_pct, $swap_total) = (0, 0, 0, "", 0, 0, 0);
    my ($ram_used, $ram_total) = (0, 0);

    $cpu        = $1 if $json =~ /"cpu_pct"\s*:\s*(\d+)/;
    $ram        = $1 if $json =~ /"ram_pct"\s*:\s*(\d+)/;
    $ram_used   = $1 if $json =~ /"ram_used_gb"\s*:\s*([0-9.]+)/;
    $ram_total  = $1 if $json =~ /"ram_total_gb"\s*:\s*([0-9.]+)/;
    $disk       = $1 if $json =~ /"disk_pct"\s*:\s*(\d+)/;
    $swap       = $1 if $json =~ /"swap_used_gb"\s*:\s*([0-9.]+)/;
    $swap_pct   = $1 if $json =~ /"swap_pct"\s*:\s*(\d+)/;
    $swap_total = $1 if $json =~ /"swap_total_gb"\s*:\s*([0-9.]+)/;
    $gpu        = $1 if $json =~ /"gpu_pct"\s*:\s*(\d+)/;
    $gpu = "" if $json =~ /"gpu_pct"\s*:\s*null/;

    # Alerts
    my @alerts;
    if ($json =~ /"alerts"\s*:\s*\[([^\]]*)\]/) {
      while ($1 =~ /"(\w+)"/g) { push @alerts, $1; }
    }
    my $alerts_str = join(",", @alerts);

    # Top CPU processes (all 3)
    my @cpu_procs;
    while ($json =~ /\{"pct"\s*:\s*([0-9.]+)\s*,\s*"name"\s*:\s*"([^"]+)"\s*\}/g) {
      push @cpu_procs, [$1, $2] if @cpu_procs < 3;
    }
    # Try alternate key order (name before pct)
    if (!@cpu_procs) {
      while ($json =~ /\{"name"\s*:\s*"([^"]+)"\s*,\s*"pct"\s*:\s*([0-9.]+)\s*\}/g) {
        push @cpu_procs, [$2, $1] if @cpu_procs < 3;
      }
    }

    # Top RAM processes (all 3) — have mem_mb field
    my @ram_procs;
    if ($json =~ /"top_ram"\s*:\s*(\[.*?\])/s) {
      my $ram_arr = $1;
      while ($ram_arr =~ /\{[^}]*?"name"\s*:\s*"([^"]+)"[^}]*?"mem_mb"\s*:\s*(\d+)[^}]*?\}/g) {
        push @ram_procs, [$1, $2];
      }
      if (!@ram_procs) {
        while ($ram_arr =~ /\{[^}]*?"mem_mb"\s*:\s*(\d+)[^}]*?"name"\s*:\s*"([^"]+)"[^}]*?\}/g) {
          push @ram_procs, [$2, $1];
        }
      }
    }

    print "u_cpu=$cpu\n";
    print "u_ram=$ram\n";
    print "u_ram_used=$ram_used\n";
    print "u_ram_total=$ram_total\n";
    print "u_disk=$disk\n";
    print "u_swap=$swap\n";
    print "u_swap_pct=$swap_pct\n";
    print "u_swap_total=$swap_total\n";
    print "u_gpu=\"$gpu\"\n";
    print "u_alerts=\"$alerts_str\"\n";

    # Export top CPU (up to 3)
    for my $i (0..2) {
      my $pct  = defined $cpu_procs[$i] ? $cpu_procs[$i][0] : "";
      my $name = defined $cpu_procs[$i] ? $cpu_procs[$i][1] : "";
      my $n = $i + 1;
      print "u_cpu${n}_name=\"$name\"\n";
      print "u_cpu${n}_pct=\"$pct\"\n";
    }
    # Export top RAM (up to 3)
    for my $i (0..2) {
      my $name   = defined $ram_procs[$i] ? $ram_procs[$i][0] : "";
      my $mem_mb = defined $ram_procs[$i] ? $ram_procs[$i][1] : "";
      my $n = $i + 1;
      print "u_ram${n}_name=\"$name\"\n";
      print "u_ram${n}_mb=\"$mem_mb\"\n";
    }
    # Backward compat aliases for dashboard
    print "u_cpu_hog=\"" . ($cpu_procs[0] ? $cpu_procs[0][1] : "") . "\"\n";
    print "u_cpu_hog_pct=\"" . ($cpu_procs[0] ? $cpu_procs[0][0] : "") . "\"\n";
    print "u_ram_hog=\"" . ($ram_procs[0] ? $ram_procs[0][0] : "") . "\"\n";
    # Ram hog MB for dashboard display
    print "u_ram_hog_mb=\"" . ($ram_procs[0] ? $ram_procs[0][1] : "") . "\"\n";
  ' "$system_file")"

  # Get current mood
  local mood
  mood=$(json_val currentMood)
  mood=${mood:-NEUTRAL}

  # ── ASCII dashboard ──
  local bar_cpu bar_ram bar_disk
  bar_cpu=""; bar_ram=""; bar_disk=""
  local i=0
  while [ $i -lt $((u_cpu / 10)) ]; do bar_cpu="${bar_cpu}█"; i=$((i + 1)); done
  i=0
  while [ $i -lt $((u_ram / 10)) ]; do bar_ram="${bar_ram}█"; i=$((i + 1)); done
  i=0
  while [ $i -lt $((u_disk / 10)) ]; do bar_disk="${bar_disk}█"; i=$((i + 1)); done

  local name
  name=$(json_val name)
  local display_name="${name}"
  [ "$display_name" = "null" ] || [ -z "$display_name" ] && display_name="Claude Mascot"

  echo "╭──────────────────────────────╮"
  printf "│  %-28s│\n" "$display_name — System"
  echo "│──────────────────────────────│"
  printf "│  CPU:  %3s%%  %-15s│\n" "$u_cpu" "$bar_cpu"
  printf "│  RAM:  %3s%%  %-15s│\n" "$u_ram" "$bar_ram"
  printf "│  Disk: %3s%%  %-15s│\n" "$u_disk" "$bar_disk"
  printf "│  Swap: %3s%%  %-15s│\n" "$u_swap_pct" "(${u_swap}/${u_swap_total}GB)"
  if [ -n "$u_gpu" ]; then
    printf "│  GPU:  %3s%%                  │\n" "$u_gpu"
  else
    printf "│  GPU:  %-22s│\n" "n/a"
  fi
  echo "│                              │"
  printf "│  Top CPU: %-18s│\n" "${u_cpu_hog} (${u_cpu_hog_pct}%)"
  printf "│  Top RAM: %-18s│\n" "${u_ram_hog} (${u_ram_hog_mb}MB)"

  # Alerts line
  if [ -n "$u_alerts" ]; then
    printf "│  Alerts: %-19s│\n" "$u_alerts"
  else
    printf "│  %-28s│\n" "All systems nominal"
  fi
  echo "╰──────────────────────────────╯"

  # ── Generate personality message ──
  local msg
  msg=$(_usage_personality_message "$mood")

  echo ""
  echo "$msg"

  # Dynamic duration: ~15 chars/sec reading speed, clamped 4–10s
  local msg_len=${#msg}
  local duration=$(( msg_len / 15 ))
  [ "$duration" -lt 4 ] && duration=4
  [ "$duration" -gt 10 ] && duration=10

  # Fire toast with cooldown (1800s / 30min) — dashboard always prints
  local cooldown_file="${STATE_DIR}/.system-toast-cooldown"
  local can_toast=true
  if [ -f "$cooldown_file" ]; then
    local last_ts now_ts
    last_ts=$(cat "$cooldown_file")
    now_ts=$(date +%s)
    [ $(( now_ts - last_ts )) -lt 1800 ] && can_toast=false
  fi
  if [ "$can_toast" = true ]; then
    local toast_script="${BASH_SOURCE[0]%/*}/../toast"
    if [ -x "$toast_script" ]; then
      "$toast_script" --mode done --mood "$mood" "$msg" "$duration" &
      disown
    fi
    date +%s > "$cooldown_file"
  fi
}

# Generate a personality-driven system message with smart investigation.
# Reads u_* vars from outer scope (set by cmd_usage's perl parser).
_usage_personality_message() {
  local mood="$1"
  local alerts="$u_alerts"

  # No alerts — all good
  if [ -z "$alerts" ]; then
    echo "All clear — nothing flagged."
    return
  fi

  # ── Build investigation description based on alert types ──
  local desc=""
  local alert_count=0
  local part=""
  IFS="," read -ra _alert_arr <<< "$alerts"

  for _a in "${_alert_arr[@]}"; do
    part=""
    case "$_a" in
      cpu)
        # Name all 3 top CPU processes with %
        local cpu_parts="${u_cpu1_name} (${u_cpu1_pct}%)"
        [ -n "$u_cpu2_name" ] && cpu_parts="${cpu_parts}, ${u_cpu2_name} (${u_cpu2_pct}%)"
        [ -n "$u_cpu3_name" ] && cpu_parts="${cpu_parts}, and ${u_cpu3_name} (${u_cpu3_pct}%)"
        part="${cpu_parts} are eating your CPU"
        ;;
      ram)
        # Name top 2-3 RAM processes with MB→GB
        local ram_parts=""
        if [ -n "$u_ram1_name" ] && [ -n "$u_ram1_mb" ]; then
          local r1_gb=$(perl -e "printf '%.1f', $u_ram1_mb / 1024" 2>/dev/null)
          ram_parts="${u_ram1_name} (${r1_gb}GB)"
        fi
        if [ -n "$u_ram2_name" ] && [ -n "$u_ram2_mb" ]; then
          local r2_gb=$(perl -e "printf '%.1f', $u_ram2_mb / 1024" 2>/dev/null)
          ram_parts="${ram_parts} and ${u_ram2_name} (${r2_gb}GB)"
        fi
        if [ -n "$ram_parts" ]; then
          part="${ram_parts} are the biggest memory hogs"
        else
          part="RAM is at ${u_ram}%"
        fi
        ;;
      swap)
        # Correlate with top RAM processes — swap is caused by RAM pressure
        local swap_detail="Swap is at ${u_swap_pct}% (${u_swap}GB)"
        if [ -n "$u_ram1_name" ] && [ -n "$u_ram1_mb" ]; then
          local sr1_gb=$(perl -e "printf '%.1f', $u_ram1_mb / 1024" 2>/dev/null)
          swap_detail="${swap_detail} — RAM is nearly full. ${u_ram1_name} (${sr1_gb}GB)"
          if [ -n "$u_ram2_name" ] && [ -n "$u_ram2_mb" ]; then
            local sr2_gb=$(perl -e "printf '%.1f', $u_ram2_mb / 1024" 2>/dev/null)
            swap_detail="${swap_detail} and ${u_ram2_name} (${sr2_gb}GB) are the heaviest"
          else
            swap_detail="${swap_detail} is the heaviest"
          fi
          swap_detail="${swap_detail}. Quitting one would help"
        fi
        part="$swap_detail"
        ;;
      disk)
        part="Disk is at ${u_disk}%. Check ~/Library/Caches and ~/Downloads for easy wins"
        ;;
      gpu)
        local gpu_culprit="${u_cpu1_name:-something}"
        part="GPU is at ${u_gpu}%. Probably ${gpu_culprit} — check Activity Monitor"
        ;;
    esac
    if [ -n "$part" ]; then
      [ -n "$desc" ] && desc="${desc}. Also, "
      desc="${desc}${part}"
      alert_count=$((alert_count + 1))
    fi
    # For multi-alert, combine the top 2
    [ "$alert_count" -ge 2 ] && break
  done

  echo "${desc}."
}

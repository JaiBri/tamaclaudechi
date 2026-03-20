# ── System resources section ───────────────────────────────
# Sourced by scripts/statusline — not executable on its own.
# Requires: CONTEXT_DIR, color variables

system_section() {
  local system_file="${CONTEXT_DIR}/system.json"
  [ ! -f "$system_file" ] && return

  # Staleness: hide if > 2 min old; trigger background refresh if > 30s old
  local now mtime age
  now=$(date +%s)
  mtime=$(stat -f %m "$system_file" 2>/dev/null || stat -c %Y "$system_file" 2>/dev/null || echo 0)
  age=$(( now - mtime ))
  [ "$age" -gt 120 ] && return

  # Trigger background refresh if stale (>30s)
  if [ "$age" -gt 30 ]; then
    local monitor="${SCRIPT_DIR}/system-monitor"
    if [ -x "$monitor" ]; then
      "$monitor" >/dev/null 2>&1 &
      disown
    fi
  fi

  # Parse with perl (single pass)
  eval "$(perl -e '
    open my $fh, "<", $ARGV[0] or exit;
    my $json = do { local $/; <$fh> };
    close $fh;

    my ($cpu, $ram, $disk, $gpu, $swap, $swap_pct) = (0, 0, 0, "null", 0, 0);
    my $alerts = "[]";
    my $top_cpu_name = "";
    my $top_ram_name = "";

    $cpu      = $1 if $json =~ /"cpu_pct"\s*:\s*(\d+)/;
    $ram      = $1 if $json =~ /"ram_pct"\s*:\s*(\d+)/;
    $disk     = $1 if $json =~ /"disk_pct"\s*:\s*(\d+)/;
    $swap     = $1 if $json =~ /"swap_used_gb"\s*:\s*([0-9.]+)/;
    $swap_pct = $1 if $json =~ /"swap_pct"\s*:\s*(\d+)/;
    $gpu      = $1 if $json =~ /"gpu_pct"\s*:\s*(\d+)/;
    # gpu might be null
    if ($json =~ /"gpu_pct"\s*:\s*null/) { $gpu = "null"; }

    # Extract alerts array
    if ($json =~ /"alerts"\s*:\s*\[([^\]]*)\]/) {
      my $inner = $1;
      my @a;
      while ($inner =~ /"(\w+)"/g) { push @a, $1; }
      $alerts = join(",", @a);
    }

    # Top CPU process name (first in array)
    if ($json =~ /"top_cpu"\s*:\s*\[.*?"name"\s*:\s*"([^"]+)"/s) {
      $top_cpu_name = $1;
    }
    # Top RAM process name (first in array)
    if ($json =~ /"top_ram"\s*:\s*\[.*?"name"\s*:\s*"([^"]+)"/s) {
      $top_ram_name = $1;
    }

    print "s_cpu=$cpu\n";
    print "s_ram=$ram\n";
    print "s_disk=$disk\n";
    print "s_swap=$swap\n";
    print "s_swap_pct=$swap_pct\n";
    print "s_gpu=$gpu\n";
    print "s_alerts=\"$alerts\"\n";
    print "s_top_cpu_name=\"$top_cpu_name\"\n";
    print "s_top_ram_name=\"$top_ram_name\"\n";
  ' "$system_file")"

  # Only render when alerts exist
  [ -z "$s_alerts" ] && return

  # Build display: only show metrics that are alerting
  local out="🖥️"
  local IFS=","
  for alert in $s_alerts; do
    case "$alert" in
      cpu)  out="${out} ${RED}CPU ${s_cpu}%${RESET}" ;;
      ram)  out="${out} ${RED}RAM ${s_ram}%${RESET}" ;;
      swap) out="${out} ${RED}Swap ${s_swap_pct}%${RESET}" ;;
      disk) out="${out} ${RED}Disk ${s_disk}%${RESET}" ;;
      gpu)  out="${out} ${RED}GPU ${s_gpu}%${RESET}" ;;
    esac
  done
  unset IFS

  # Export for context.json
  _system_cpu="$s_cpu"
  _system_ram="$s_ram"
  _system_disk="$s_disk"
  _system_swap="$s_swap"
  _system_swap_pct="$s_swap_pct"
  _system_gpu="$s_gpu"
  _system_alerts="$s_alerts"
  _system_top_cpu="$s_top_cpu_name"
  _system_top_ram="$s_top_ram_name"

  system="$out"
}

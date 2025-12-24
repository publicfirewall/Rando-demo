#!/usr/bin/env bash
# RandoTron™ Public Demo Stub - Merry Christmas love from Jay
# Purpose: Safe, non-destructive demo that showcases operator-grade UX and visibility.
# NOTE: This script performs READ-ONLY checks only. No firewall changes, no installs, no edits.

set -euo pipefail

# ---------- Styling ----------
RST=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RED=$'\033[31m'
GRN=$'\033[32m'
YLW=$'\033[33m'
BLU=$'\033[34m'
CYN=$'\033[36m'

# ---------- Helpers ----------
hr(){ printf "%s\n" "${DIM}────────────────────────────────────────────────────────────────${RST}"; }
ok(){ printf "%s[OK]%s %s\n" "${GRN}" "${RST}" "$*"; }
warn(){ printf "%s[!!]%s %s\n" "${YLW}" "${RST}" "$*"; }
bad(){ printf "%s[XX]%s %s\n" "${RED}" "${RST}" "$*"; }
info(){ printf "%s[i]%s %s\n" "${CYN}" "${RST}" "$*"; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }

require_root_note(){
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    warn "Running without root. Some details may be limited (this is fine for demo)."
  else
    ok "Running as root (read-only checks still enforced)."
  fi
}

banner(){
  clear 2>/dev/null || true
  printf "%s%s\n" "${BOLD}${CYN}" "╔══════════════════════════════════════════════════════════════╗"
  printf "%s\n" "║                      RandoTron™ Demo Stub                    ║"
  printf "%s\n" "║      Operator Visibility • Traffic Intel • Safe Preview      ║"
  printf "%s%s\n" "╚══════════════════════════════════════════════════════════════╝" "${RST}"
  printf "%s\n" "${DIM}Public release: non-destructive, no installs, no writes.${RST}"
  hr
}

# ---------- System Snapshot ----------
sys_snapshot(){
  printf "%s%s%s\n" "${BOLD}" "SYSTEM SNAPSHOT" "${RST}"
  local host os kernel up cpu mem
  host="$(hostname 2>/dev/null || echo unknown)"
  kernel="$(uname -r 2>/dev/null || echo unknown)"
  up="$(uptime -p 2>/dev/null || uptime 2>/dev/null || echo unknown)"
  os="unknown"
  if [ -r /etc/os-release ]; then
    os="$(. /etc/os-release; echo "${PRETTY_NAME:-unknown}")"
  fi
  cpu="unknown"
  if need_cmd lscpu; then
    cpu="$(lscpu 2>/dev/null | awk -F: '/Model name/ {gsub(/^[ \t]+/,"",$2); print $2; exit}')"
    [ -n "${cpu}" ] || cpu="unknown"
  fi
  mem="unknown"
  if need_cmd free; then
    mem="$(free -h 2>/dev/null | awk '/Mem:/ {print $2 " total, " $3 " used, " $7 " avail"}')"
  fi

  printf "%-18s %s\n" "Host:" "$host"
  printf "%-18s %s\n" "OS:" "$os"
  printf "%-18s %s\n" "Kernel:" "$kernel"
  printf "%-18s %s\n" "Uptime:" "$up"
  printf "%-18s %s\n" "CPU:" "$cpu"
  printf "%-18s %s\n" "Memory:" "$mem"
  hr
}

# ---------- Network Snapshot ----------
net_snapshot(){
  printf "%s%s%s\n" "${BOLD}" "NETWORK SNAPSHOT" "${RST}"

  if need_cmd ip; then
    info "Interfaces (UP):"
    ip -br link 2>/dev/null | awk '$2 ~ /UP/ {print "  - " $1 " (" $2 ")"}' || true
    echo
    info "Addresses:"
    ip -br addr 2>/dev/null | sed 's/^/  - /' || true
    echo
    info "Routes (default first):"
    ip route 2>/dev/null | awk 'BEGIN{shown=0} $1=="default"{print "  - " $0; shown=1} END{if(!shown) print "  - (no default route detected)"}'
    ip route 2>/dev/null | awk '$1!="default"{print "  - " $0}' | head -n 10 || true
  else
    warn "'ip' not found. Limited network view."
  fi
  hr
}

# ---------- Connectivity Tests (Read-only) ----------
connectivity_tests(){
  printf "%s%s%s\n" "${BOLD}" "CONNECTIVITY TESTS" "${RST}"
  local targets=("1.1.1.1" "8.8.8.8")
  if need_cmd ping; then
    for t in "${targets[@]}"; do
      if ping -c 2 -W 2 "$t" >/dev/null 2>&1; then
        ok "ICMP reachable: $t"
      else
        warn "ICMP not reachable: $t (may be blocked — not automatically bad)"
      fi
    done
  else
    warn "'ping' not found."
  fi

  if need_cmd curl; then
    if curl -fsS --max-time 3 https://api.ipify.org >/dev/null 2>&1; then
      local pubip
      pubip="$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)"
      [ -n "$pubip" ] && ok "Public egress IP: $pubip" || warn "Public IP lookup failed."
    else
      warn "HTTPS reachability check failed."
    fi
  else
    warn "'curl' not found (skipping HTTPS check)."
  fi
  hr
}

# ---------- Traffic Intelligence Preview ----------
traffic_preview(){
  printf "%s%s%s\n" "${BOLD}" "TRAFFIC INTEL PREVIEW (SAFE)" "${RST}"
  info "This is a demo view: it samples counters and estimates rates."
  info "No packet capture. No firewall edits. No active mitigation."
  echo

  if ! need_cmd ip; then
    warn "'ip' not found. Cannot sample interface counters."
    hr
    return
  fi

  local iface
  iface="$(ip route 2>/dev/null | awk '$1=="default"{print $5; exit}')"
  iface="${iface:-}"
  if [ -z "$iface" ]; then
    warn "Could not determine default interface."
    hr
    return
  fi

  local rx1 tx1 rx2 tx2
  rx1="$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null || echo 0)"
  tx1="$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null || echo 0)"
  sleep 1
  rx2="$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null || echo 0)"
  tx2="$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null || echo 0)"

  # bytes per second over 1 sec window
  local rxbps=$((rx2-rx1))
  local txbps=$((tx2-tx1))

  # Human-ish formatting
  fmt_rate() {
    local bps="$1"
    if [ "$bps" -ge 1073741824 ]; then awk -v b="$bps" 'BEGIN{printf "%.2f GB/s", b/1073741824}'
    elif [ "$bps" -ge 1048576 ]; then awk -v b="$bps" 'BEGIN{printf "%.2f MB/s", b/1048576}'
    elif [ "$bps" -ge 1024 ]; then awk -v b="$bps" 'BEGIN{printf "%.2f KB/s", b/1024}'
    else printf "%d B/s" "$bps"
    fi
  }

  printf "%-18s %s\n" "Default IF:" "$iface"
  printf "%-18s %s\n" "RX rate:" "$(fmt_rate "$rxbps")"
  printf "%-18s %s\n" "TX rate:" "$(fmt_rate "$txbps")"

  # Simple “signal vs noise” demo logic
  local rx_mbps tx_mbps
  rx_mbps="$(awk -v b="$rxbps" 'BEGIN{printf "%.3f", (b*8)/1000000}')"
  tx_mbps="$(awk -v b="$txbps" 'BEGIN{printf "%.3f", (b*8)/1000000}')"

  echo
  info "Signal classifier (demo thresholds):"
  info " - < 20 Mbps = normal"
  info " - 20–150 Mbps = elevated"
  info " - > 150 Mbps = potential flood (requires correlation)"
  echo

  # decide based on max of rx/tx
  local max_mbps
  max_mbps="$(awk -v a="$rx_mbps" -v b="$tx_mbps" 'BEGIN{print (a>b)?a:b}')"

  awk -v m="$max_mbps" -v grn="$GRN" -v ylw="$YLW" -v red="$RED" -v rst="$RST" '
    BEGIN{
      if (m < 20)  {printf "  %sSTATUS%s  NORMAL (%.3f Mbps)\n", grn, rst, m}
      else if (m < 150) {printf "  %sSTATUS%s  ELEVATED (%.3f Mbps)\n", ylw, rst, m}
      else {printf "  %sSTATUS%s  POTENTIAL FLOOD (%.3f Mbps)\n", red, rst, m}
    }'
  hr
}

# ---------- Menu ----------
menu(){
  while true; do
    printf "%s%s%s\n" "${BOLD}" "MENU" "${RST}"
    echo "  [1] System snapshot"
    echo "  [2] Network snapshot"
    echo "  [3] Connectivity tests"
    echo "  [4] Traffic intel preview (safe)"
    echo "  [5] Run all (recommended)"
    echo "  [0] Exit"
    echo
    read -rp "Select: " choice
    echo
    case "${choice:-}" in
      1) sys_snapshot ;;
      2) net_snapshot ;;
      3) connectivity_tests ;;
      4) traffic_preview ;;
      5) sys_snapshot; net_snapshot; connectivity_tests; traffic_preview ;;
      0) break ;;
      *) warn "Invalid choice." ;;
    esac
  done
}

# ---------- Main ----------
main(){
  banner
  require_root_note
  info "Public demo stub loaded. Read-only checks only."
  info "Contact: netfiltervpn@gmail.com"
  hr
  menu
  echo
  ok "Done."
}

main "$@"

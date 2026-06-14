#!/usr/bin/env bash

# ==========================================================
# NX220 SOC Analyst Project: CHECKER
# Student Name: David Rozi
# Student Code: s16
# Unit Name: PERES25B
# Program Code: NX220
# Lecturer Name: Tzah Azoalis
#
# Purpose:
# This script helps SOC teams run controlled lab attack simulations,
# select a target IP, execute a selected activity, and log each action.
#
# Use only in authorized lab environments.
# ==========================================================

set -u

LOG_FILE="/var/log/nx220_checker.log"
RESULTS_DIR="$(pwd)/nx220-checker-results"
DISCOVERY_FILE="$RESULTS_DIR/discovered_ips.txt"

STUDENT_NAME="David Rozi"
STUDENT_CODE="s16"
UNIT_NAME="PERES25B"
PROGRAM_CODE="NX220"
LECTURER_NAME="Tzah Azoalis"

declare -a DISCOVERED_IPS=()
SELECTED_ATTACK=""
SELECTED_TARGET=""

print_banner() {
    echo "=========================================================="
    echo " NX220 SOC Analyst Project: CHECKER"
    echo " Student: $STUDENT_NAME"
    echo " Student Code: $STUDENT_CODE"
    echo " Unit: $UNIT_NAME"
    echo " Program: $PROGRAM_CODE"
    echo " Lecturer: $LECTURER_NAME"
    echo "=========================================================="
    echo
}

require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "[ERROR] Run this script with sudo because it writes logs to /var/log."
        echo "Example:"
        echo "sudo ./checker.sh"
        exit 1
    fi
}

prepare_dirs() {
    mkdir -p "$RESULTS_DIR"
    touch "$LOG_FILE" 2>/dev/null || {
        echo "[ERROR] Cannot write to $LOG_FILE"
        exit 1
    }
}

check_tools() {
    local missing=0
    local tools=("nmap" "curl" "ip" "awk" "sort" "shuf" "tee")

    echo "[*] Checking required tools..."
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo "[OK] $tool found"
        else
            echo "[MISSING] $tool is not installed"
            missing=1
        fi
    done

    if [[ "$missing" -ne 0 ]]; then
        echo
        echo "[ERROR] Install missing tools and run again:"
        echo "sudo apt update && sudo apt install -y nmap curl iproute2 coreutils"
        exit 1
    fi

    echo
}

get_default_interface() {
    ip route | awk '/default/ {print $5; exit}'
}

get_interface_cidr() {
    local iface="$1"
    ip -o -f inet addr show "$iface" | awk '{print $4}' | head -n 1
}

discover_ips() {
    local iface
    local cidr

    iface="$(get_default_interface)"

    if [[ -z "$iface" ]]; then
        echo "[ERROR] Could not detect default network interface."
        exit 1
    fi

    cidr="$(get_interface_cidr "$iface")"

    if [[ -z "$cidr" ]]; then
        echo "[ERROR] Could not detect network CIDR for interface $iface."
        exit 1
    fi

    echo "[*] Default interface: $iface"
    echo "[*] Detected network: $cidr"
    echo "[*] Discovering live IP addresses with nmap ping scan..."
    echo

    nmap -sn -n --max-retries 1 --host-timeout 10s "$cidr" -oG - 2>/dev/null \
        | awk '/Up$/{print $2}' \
        | sort -V \
        | tee "$DISCOVERY_FILE"

    mapfile -t DISCOVERED_IPS < "$DISCOVERY_FILE"

    echo
    echo "[*] Total live IPs detected: ${#DISCOVERED_IPS[@]}"
    echo "[*] Discovery file: $DISCOVERY_FILE"
    echo
}

show_attacks() {
    echo "Available attack simulations:"
    echo
    echo "1) TCP Top Ports Scan"
    echo "   Description: Scans the target for common open TCP ports using Nmap."
    echo
    echo "2) Service Version Detection"
    echo "   Description: Detects service versions on common ports using Nmap."
    echo
    echo "3) SMB Security Probe"
    echo "   Description: Checks SMB exposure and security settings on TCP port 445 using Nmap scripts."
    echo
    echo "R) Random attack"
    echo
}

log_attack() {
    local attack_name="$1"
    local target_ip="$2"
    local output_file="$3"
    local timestamp

    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    echo "$timestamp | student=$STUDENT_NAME | unit=$UNIT_NAME | program=$PROGRAM_CODE | attack=$attack_name | target=$target_ip | output=$output_file" >> "$LOG_FILE"
}

select_attack() {
    local choice

    read -rp "Select attack number [1-3] or R for random: " choice

    if [[ "$choice" =~ ^[Rr]$ ]]; then
        choice="$(shuf -i 1-3 -n 1)"
        echo "[*] Random attack selected: $choice"
    fi

    if ! [[ "$choice" =~ ^[1-3]$ ]]; then
        echo "[ERROR] Invalid attack selection. Terminating program."
        exit 1
    fi

    SELECTED_ATTACK="$choice"
}

select_target() {
    local target

    if [[ "${#DISCOVERED_IPS[@]}" -eq 0 ]]; then
        echo "[ERROR] No discovered IP addresses available."
        exit 1
    fi

    echo "Detected IP addresses:"
    local i=1
    for ip_addr in "${DISCOVERED_IPS[@]}"; do
        echo "$i) $ip_addr"
        ((i++))
    done

    echo
    read -rp "Enter target IP manually or type R for random target: " target

    if [[ "$target" =~ ^[Rr]$ ]]; then
        target="$(printf "%s
" "${DISCOVERED_IPS[@]}" | shuf -n 1)"
        echo "[*] Random target selected: $target"
    fi

    if ! [[ "$target" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo "[ERROR] Invalid IP address format. Terminating program."
        exit 1
    fi

    SELECTED_TARGET="$target"
}

attack_tcp_top_ports() {
    local target_ip="$1"
    local output_file="$RESULTS_DIR/tcp_top_ports_${target_ip}_$(date '+%Y%m%d_%H%M%S').txt"

    echo "[*] Attack Simulation: TCP Top Ports Scan"
    echo "[*] Target: $target_ip"
    echo "[*] Output: $output_file"
    echo

    log_attack "TCP_TOP_PORTS_SCAN" "$target_ip" "$output_file"

    nmap -Pn -sT -T3 --top-ports 30 "$target_ip" | tee "$output_file"
}

attack_service_version() {
    local target_ip="$1"
    local output_file="$RESULTS_DIR/service_version_${target_ip}_$(date '+%Y%m%d_%H%M%S').txt"

    echo "[*] Attack Simulation: Service Version Detection"
    echo "[*] Target: $target_ip"
    echo "[*] Output: $output_file"
    echo

    log_attack "SERVICE_VERSION_DETECTION" "$target_ip" "$output_file"

    nmap -Pn -sV -T3 --top-ports 20 "$target_ip" | tee "$output_file"
}

attack_smb_probe() {
    local target_ip="$1"
    local output_file="$RESULTS_DIR/smb_security_probe_${target_ip}_$(date '+%Y%m%d_%H%M%S').txt"

    echo "[*] Attack Simulation: SMB Security Probe"
    echo "[*] Target: $target_ip"
    echo "[*] Output: $output_file"
    echo

    log_attack "SMB_SECURITY_PROBE" "$target_ip" "$output_file"

    nmap -Pn -p445 --script smb-protocols,smb-security-mode "$target_ip" | tee "$output_file"
}

execute_attack() {
    local attack_id="$1"
    local target_ip="$2"

    case "$attack_id" in
        1)
            attack_tcp_top_ports "$target_ip"
            ;;
        2)
            attack_service_version "$target_ip"
            ;;
        3)
            attack_smb_probe "$target_ip"
            ;;
        *)
            echo "[ERROR] Invalid attack ID. Terminating program."
            exit 1
            ;;
    esac
}

show_summary() {
    echo
    echo "=========================================================="
    echo "Execution completed."
    echo "Log file:"
    echo "$LOG_FILE"
    echo
    echo "Results directory:"
    echo "$RESULTS_DIR"
    echo
    echo "Last log entries:"
    tail -n 5 "$LOG_FILE"
    echo "=========================================================="
}

main() {
    print_banner
    require_root
    prepare_dirs
    check_tools
    discover_ips
    show_attacks

    select_attack
    echo

    select_target
    echo

    execute_attack "$SELECTED_ATTACK" "$SELECTED_TARGET"
    show_summary
}

main "$@"


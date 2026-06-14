# NX220 SOC Analyst Project: CHECKER

Automatic SOC attack simulation and logging system built for the NX220 SOC Analyst module.

## Overview

CHECKER is a Bash-based lab tool that helps a SOC manager run controlled security checks against hosts in an authorized lab network. The script discovers live IP addresses, displays available attack simulations, allows manual or random attack selection, allows manual or random target selection, executes the selected activity, and writes an audit log under `/var/log`.

This project is intended for defensive SOC training, documentation, and lab validation only.

## Lab Topology

| Role | Machine | IP Address | Purpose |
|---|---|---:|---|
| Attacker | Kali Linux | `192.168.47.136` | Runs the CHECKER script |
| Target | Windows | `192.168.47.129` | Receives controlled scans |
| Network | VMware NAT | `192.168.47.0/24` | Shared lab subnet |

## Features

- Discovers live hosts on the local subnet with Nmap.
- Shows a menu of available attack simulations and descriptions.
- Supports manual attack selection: `1`, `2`, or `3`.
- Supports random attack selection with `R`.
- Supports manual or random target IP selection.
- Validates invalid attack and target input.
- Saves execution logs to `/var/log/nx220_checker.log`.
- Stores scan outputs in `nx220-checker-results/`.

## Attack Simulations

| ID | Name | Purpose |
|---:|---|---|
| 1 | TCP Top Ports Scan | Finds common open TCP ports using Nmap |
| 2 | Service Version Detection | Identifies service versions on common ports |
| 3 | SMB Security Probe | Checks SMB exposure and supported SMB dialects on TCP/445 |

## Requirements

Run on Kali Linux or a Debian-based lab machine with:

- `bash`
- `nmap`
- `curl`
- `iproute2`
- `coreutils`
- `awk`, `sort`, `tee`, `shuf`

Install dependencies on Kali/Debian:

```bash
sudo apt update
sudo apt install -y nmap curl iproute2 coreutils
```

## Usage

Clone the repository or copy the script to Kali:

```bash
chmod +x PERES25B.s16.nx220.sh
sudo ./PERES25B.s16.nx220.sh
```

The script requires `sudo` because it writes to:

```text
/var/log/nx220_checker.log
```

## Output Locations

Execution log:

```text
/var/log/nx220_checker.log
```

Result files:

```text
./nx220-checker-results/
```

## Example Log Entry

```text
2026-06-14 12:51:07 | student=David Rozi | unit=PERES25B | program=NX220 | attack=SMB_SECURITY_PROBE | target=192.168.47.129 | output=/home/david/nx220-checker-project/nx220-checker-results/smb_security_probe_192.168.47.129_20260614_125107.txt
```

## Report

The final project report is available in:

```text
docs/PERES25B.s16.nx220.pdf
```

## Safety and Scope

Use this script only in systems you own or in an authorized lab environment. Do not run it against public IP addresses, third-party systems, production systems, or networks where you do not have explicit permission.

The implemented activities are controlled lab scans and are not designed to cause disruption.

## Suggested Repository Structure

```text
.
├── README.md
├── PERES25B.s16.nx220.sh
├── docs/
│   └── PERES25B.s16.nx220.pdf
├── .gitignore
└── SECURITY.md
```

## Submission Files

For official course submission, submit only:

```text
PERES25B.s16.nx220.sh
PERES25B.s16.nx220.pdf
```

Do not submit temporary logs, result files, DOCX drafts, or backup scripts unless specifically requested.

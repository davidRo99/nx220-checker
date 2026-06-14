# Security Policy

## Authorized Use Only

This repository contains a lab-oriented SOC training script. Use it only in systems and networks where you have explicit authorization.

Do not run the script against public targets, production networks, third-party infrastructure, or any system you do not own or administer.

## Scope

The script performs controlled Nmap-based checks:

- TCP top ports scan
- Service version detection
- SMB security probe on TCP/445

These checks are intended for local lab validation and SOC documentation.

## Reporting Issues

If you identify a bug or unsafe behavior in the script, document:

1. The command you ran.
2. The target lab IP.
3. The exact terminal output.
4. The expected behavior.
5. The actual behavior.

Do not include real credentials, public IPs, or sensitive organizational data in issue reports.

# Log Analyser - Real-Time Brute Force Detection (Bash)

Beginner friendly blue team tool written in Bash that monitors SSH logs. Checks for brute-force login attemtps and blacklisted IPs
Simulates behaviour of a lightweight intrusion detection system (IDS) using synthetic log data and simple detection rules.

## Prerequisites
- Bash (I ran using WSL)
- Standard UNIX tools (`awk`, `tail`, `date`)

## Setup
1. Clone the repo
2. Make `monitor.sh` executable: `chmod +x monitor.sh`
3. Run `./monitor.sh` to start monitoring
4. Time window and attempt threshold can be adjusted at the top of `monitor.sh`

## Simulate Attacks
Open a second terminal in the same location and run the following command 5+ times:
`echo "Jul  9 12:00:01 localhost sshd[12345]: Failed password for invalid user root from 192.168.1.10 port 22 ssh2" >> sample_logs/auth.log`

## See Also
The same tool I've built in Python: https://github.com/louis-wain/log-analyser-python

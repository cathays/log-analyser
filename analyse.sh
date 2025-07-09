#!/bin/bash

LOGFILE="sample_logs/auth.log"
TMPFILE="temp_attempts.txt"
BLACKLIST="blacklist.txt"
THRESHOLD=5
WINDOW=60

echo "===Checking logs for more then $THRESHOLD failed attempts in $WINDOW seconds==="

# Check blacklist exists
if [[ ! -f "$BLACKLIST" ]]; then
    echo "Blacklist file not found: $BLACKLIST"
    exit 1
fi

declare -A blacklist_ips
while IFS= read -r ip; do
    ip=$(echo "$ip" | tr -d '\r' | xargs)  # Strip CR + trim spaces
    blacklist_ips["$ip"]=1
done < "$BLACKLIST"

grep "Failed password" "$LOGFILE" | while read -r line ; do
    # Extract timestamp
    timestamp=$(echo "$line" | awk '{print $1, $2, $3}' )

    # Extract IP
    ip=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' | tr -d '\r' | xargs)

    # Convert timestamp to epoch
    epoch=$(date -d "$timestamp $(date +%Y)" +%s)

    echo "$epoch $ip"
done > "$TMPFILE"

# Get unique IPs
ips=$(awk '{print $2}' "$TMPFILE" | sort | uniq)

for ip in $ips; do
    # Extract timestamps for IP
    times=($(awk -v ip="$ip" '$2==ip {print $1}' "$TMPFILE" | sort -n))

    # Number of attempts
    count=${#times[@]}

    # Skip when less than 5 attempts
    if (( count <= $THRESHOLD )); then
        continue
    fi

    # Sliding window over timestamps
    for ((i=0; i<count; i++)); do
        start=${times[i]}
        window_count=1

        # Count how many in 60 seconds
        for ((j=i+1; j<count; j++)); do
            if (( ${times[j]} <= start + $WINDOW)); then
                ((window_count++))
            else
                break
            fi
        done

        if (( window_count > $THRESHOLD )); then
            if [[ ${blacklist_ips["$ip"]} ]]; then
                echo "[ALERT][BLACKLISTED] $ip - $window_count failed attempts within $WINDOW seconds starting at $(date -d @$start)"
            else
                echo "[ALERT] $ip - $window_count failed attempts within $WINDOW seconds starting at $(date -d @$start)"
            fi
            break
            
        fi
    done
done
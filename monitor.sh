#!/bin/bash

LOGFILE="sample_logs/auth.log"
BLACKLIST="blacklist.txt"
TMPFILE="temp_attempts.txt"
OUTPUT="output/flagged_ips.csv"
THRESHOLD=5
WINDOW=60

mkdir -p output
> "$TMPFILE"
echo "timestamp,ip,count,blacklisted" > "$OUTPUT"

# Load blacklist
declare -A blacklist_ips
while IFS= read -r line; do
    ip=$(echo "$line" | tr -d '\r'  | xargs)
    [[ -z "$ip" ]] && continue
    blacklist_ips["$ip"]=1
done < "$BLACKLIST"

echo "[*] Monitoring $LOGFILE ..."

tail -Fn0 "$LOGFILE" | while read -r line; do
    # Only handle failed logins
    if [[ "$line" == *"Failed password"* ]]; then
        timestamp=$(echo "$line" | awk '{print $1, $2, $3}')
        ip=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}')
        epoch=$(date -d "$timestamp $(date +%Y)" +%s)

        # Add to temp file
        echo "$epoch $ip" >> "$TMPFILE"

        # Analyse recent attempts from ip
        times=($(awk -v ip="$ip" '$2==ip {print $1}' "$TMPFILE" | sort -n))
        count=${#times[@]}

        for ((i=0; i<count; i++)); do
            start=${times[i]}
            window_count=1
            for ((j=i+1; j<count; j++)); do
                if (( ${times[j]} <= start + WINDOW )); then
                    ((window_count++))
                else
                    break
                fi
            done

            if (( window_count > THRESHOLD )); then
                ts=$(date -d "@$start" +"%Y-%m-%d %H:%M:%S")
                if [[ ${blacklist_ips[$ip]} ]]; then
                    echo "[ALERT][BLACKLISTED] $ip - $window_count failed attempts at $ts"
                    echo "$ts,$ip,$window_count,yes" >> "$OUTPUT"
                else
                    echo "[ALERT] $ip - $window_count failed attempts at $ts"
                    echo "$ts,$ip,$window_count,no" >> "$OUTPUT"
                fi
                break  # Avoid duplicate alerts for same window
            fi
        done
    fi
done

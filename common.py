from datetime import datetime

RESET = "\033[0m"

BOLD = "\033[1m"
RED = "\033[31m"
GREEN = "\033[32m"
BLUE = "\033[34m"

BRIGHT_RED = "\033[91m"
BRIGHT_GREEN = "\033[92m"
BRIGHT_BLUE = "\033[94m"

def success(text):
	time = datetime.now().strftime("%H:%M:%S")
	message = f"{GREEN}{BOLD}[+]{RESET}{BRIGHT_GREEN}({time}){GREEN}-{BOLD}[ {BRIGHT_GREEN}Success{GREEN} ]{RESET}{GREEN}->{RESET} {text}"

	print(message)

def fail(text):
	time = datetime.now().strftime("%H:%M:%S")
	message = f"{RED}{BOLD}[-]{RESET}{BRIGHT_RED}({time}){RED}-{BOLD}[ {BRIGHT_RED}Failed{RED} ]{RESET}{RED}-->{RESET} {text}"

	print(message)

def info(text):
	time = datetime.now().strftime("%H:%M:%S")
	message = f"{BLUE}{BOLD}[*]{RESET}{BRIGHT_BLUE}({time}){BLUE}-{BOLD}[ {BRIGHT_BLUE}Info{BLUE} ]{RESET}{BLUE}---->{RESET} {text}"

	print(message)
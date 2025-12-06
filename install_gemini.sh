#!/usr/bin/env bash
# Minimal install: wget, nvm (Node LTS),  Gemini CLI.

set -e

echo "==> Ensure Node (install via nvm only if missing)"
if command -v node >/dev/null 2>&1; then
	echo "Node already present: $(node -v)"
else
	export NVM_DIR="$HOME/.nvm"
	if [ -s "$NVM_DIR/nvm.sh" ]; then
		echo "nvm already installed"
	else
		wget -q -O - https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
	fi
	# shellcheck disable=SC1090
	source "$NVM_DIR/nvm.sh"
	echo "Installing latest LTS Node via nvm"
	nvm install --lts
	nvm use --lts
fi

echo "==> Ensure Node version >=20"
nver_major=$(node -v | sed -E 's/^v([0-9]+).*/\1/')
if [ "$nver_major" -lt 20 ]; then
	echo "Upgrading Node to latest LTS (current: $(node -v))"
	export NVM_DIR="$HOME/.nvm"
	if [ -s "$NVM_DIR/nvm.sh" ]; then
		# shellcheck disable=SC1090
		. "$NVM_DIR/nvm.sh"
		nvm install --lts
		nvm use --lts
	else
		echo "nvm not available to upgrade Node. Install nvm manually to upgrade." >&2
	fi
fi

echo "==> Install Gemini CLI (@google/gemini-cli)"
npm install -g @google/gemini-cli

echo "==> Versions"
node -v || true
npm -v || true

command -v gemini >/dev/null && echo "gemini installed" || echo "gemini missing"

echo "Done. Open a new shell or source nvm to use and 'gemini'."


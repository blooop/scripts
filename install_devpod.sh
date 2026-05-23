#!/usr/bin/env bash
set -e

export PATH="$HOME/.pixi/bin:$PATH"

pixi global install --channel https://prefix.dev/blooop --channel conda-forge devpod

devpod provider add docker 2>/dev/null || true
devpod ide use vscode

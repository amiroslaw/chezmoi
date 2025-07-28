#!/usr/bin/env bash
set -o pipefail

sudo env ZYPP_CURL2=1 zypper ref
sudo env ZYPP_PCK_PRELOAD=1 zypper dup


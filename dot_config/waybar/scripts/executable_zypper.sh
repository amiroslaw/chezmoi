#!/bin/bash

# Check for available updates
zypper --quiet lu | awk '$1 ~ /^v/ {count++} END {if (count > 0) print " " count}'

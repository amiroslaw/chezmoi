#!/usr/bin/bash
# =====================================================
# -----------------------------------------------------
# Gather the current keybinds from hyprctl,
# and open a rofi menu to search/execute them.
#    Jason Bradberry (2025)
# -----------------------------------------------------
# =====================================================
# new hyprland version with lua api doesn't show dispatcher, so it won't be able to execute it

binds_file="$HOME/.local/share/hyprland/hyprbinds.json"

# Function to map modmask values to strings
map_modmask() {
  case "$1" in
  0) echo "(NONE)" ;;
  1) echo "S" ;;
  4) echo "C" ;;
  5) echo "C-S" ;;
  8) echo "A" ;;
  12) echo "C-A" ;;
  13*) echo "MEH(C-A-S)" ;;
  64) echo "M" ;;
  65) echo "M-S" ;;
  68) echo "M-C" ;;
  72) echo "M-A" ;;
  *) echo "Unknown: $1" ;;
  esac
}

update_requested=false
for arg in "$@"; do
  if [ "$arg" == "--update" ]; then
    update_requested=true
    break
  fi
done

if [ ! -f "$binds_file" ] || [ "$update_requested" = true ]; then
	# Get JSON output from hyprctl
	json_output=$(hyprctl binds -j)

	# Process JSON: Convert modmask values using a loop
	updated_json=$(echo "$json_output" | jq -c '.[]' | while read -r bind; do
	  modmask_value=$(echo "$bind" | jq -r '.modmask')
	  modmask_str=$(map_modmask "$modmask_value")
	  echo "$bind" | jq --arg modmask_str "$modmask_str" '.modmask = $modmask_str'
	done | jq -s '.')

	# Save to file
	echo "$updated_json" >"$binds_file"

	echo "File '$binds_file' has been created successfully."
fi

# Filter JSON entries based on criteria
filtered_entries=$(jq -r '.[] | select(.submap == "" and .dispatcher != "submap") | 
    "\(.modmask)-\(.key) \t \"\(.description)\""' "$binds_file")
    # "\(.modmask)-\(.key) \"\(.description)\": \(.dispatcher) \(.arg)"' "$binds_file")

counter=$(echo "$filtered_entries" | wc -l)
# Show options in rofi and get user selection
selected=$(echo "$filtered_entries" | rofi -dmenu -i -l 30 -case-smart -p "Hypr keybinds: $counter")

# Extract dispatcher and arg from the selected entry
# dispatcher=$(echo "$selected" | sed -E 's/.*: ([^ ]+) .*/\1/')
# arg=$(echo "$selected" | sed -E 's/.*: [^ ]+ (.*)/\1/')

# Debugging output
# echo "debug: dispatcher='$dispatcher', arg='$arg'"

# Execute the selected command
# if [ -n "$dispatcher" ] && [ -n "$arg" ]; then
#   hyprctl dispatch "$dispatcher" "$arg"
# else
#   echo "Invalid selection or missing arguments"
# fi

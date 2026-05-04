#!/usr/bin/env bash

# Fetch weather data from wttr.in in JSON format
# Auto-detect location by default.
weather=$(curl -s "https://wttr.in/?format=j1")

if [ -z "$weather" ] || [ $(echo "$weather" | jq 'has("current_condition")') == "false" ]; then
    echo '{"text": "N/A", "tooltip": "Weather unavailable"}'
    exit 1
fi

# Extract current temperature and condition
temp=$(echo "$weather" | jq -r '.current_condition[0].temp_C')
condition=$(echo "$weather" | jq -r '.current_condition[0].weatherDesc[0].value')
city=$(echo "$weather" | jq -r '.nearest_area[0].areaName[0].value')

# Map conditions to Nerd Font icons
case "$(echo "$condition" | tr '[:upper:]' '[:lower:]')" in
    *sunny* | *clear*) icon="󰖙" ;;
    *cloudy* | *overcast*) icon="󰖐" ;;
    *partly*cloudy*) icon="󰖕" ;;
    *rain* | *drizzle* | *shower*) icon="󰖗" ;;
    *thunder*) icon="󰖓" ;;
    *snow*) icon="󰼶" ;;
    *fog* | *mist*) icon="󰖑" ;;
    *) icon="󰖕" ;;
esac

# Create the tooltip (e.g., "London: Cloudy, 15°C")
tooltip="$city: $condition, ${temp}°C"

# Output JSON for Waybar
echo "{\"text\": \"$icon $temp°C\", \"tooltip\": \"$tooltip\"}"

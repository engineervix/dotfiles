#!/usr/bin/env bash
# =============================================================================
# Script: recorder.sh
# Description: Toggles screen/window recording using gpu-screen-recorder
# =============================================================================

# Define output directory (using XDG standard or fallback to ~/Videos/Recordings)
SAVE_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"
mkdir -p "$SAVE_DIR"
FILENAME="recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"

# Notification function using notify-send (matching screenshot approach)
notify() {
    notify-send -a "Screen Recorder" -i "video-display-symbolic" "$1" "$2" -t "$3"
}

if pgrep -f "^gpu-screen-recorder" > /dev/null; then
    # Stop recording gracefully with SIGINT (to finalize the video file)
    pkill -SIGINT -f "^gpu-screen-recorder"
    exit 0
else
    # Start recording using the Wayland portal
    # -w portal: triggers a choice between Monitor and Window
    # -f 60: 60 FPS
    # -a default_output: record system audio
    # -restore-portal-session yes: avoid re-authorizing every time
    notify "Recording Starting" "Choose a monitor or window to record" 2000
    
    # Run in foreground to allow Ctrl+C and proper termination handling
    # INTEL_DEBUG=norbc disables render buffer compression on this Intel GPU.
    # When compression is on, pipewire offers a buffer format that EGL
    # cannot import. Negotiation then times out, and gpu-screen-recorder
    # exits and saves no video file.
    # Reference: https://docs.mesa3d.org/envvars.html (see INTEL_DEBUG, norbc)
    INTEL_DEBUG=norbc gpu-screen-recorder -w portal -f 60 -a default_output -restore-portal-session yes -o "$SAVE_DIR/$FILENAME"
    
    # This part executes after gpu-screen-recorder exits
    if [ -f "$SAVE_DIR/$FILENAME" ]; then
        notify "Recording Stopped" "Video saved to $SAVE_DIR" 3000
    else
        notify "Recording Finished" "Process ended" 2000
    fi
fi

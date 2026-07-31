#!/usr/bin/env bash
# Custom preview for forgit's `glo` (git log browser). Wired in via
# FORGIT_LOG_FZF_OPTS in .zshrc, which overrides forgit's built-in
# `--preview` for this one command (its `--bind`s for enter/yank are
# untouched, since fzf only overrides the last value of repeated flags).
#
# forgit's stock preview just pipes `git show` through delta, so an image
# added/changed in a commit shows up as "Binary files ... differ" (or, for
# Git LFS-tracked images, a meaningless diff of the LFS pointer text). Kitty
# can render images directly in the terminal, so when the commit touches an
# image file, render a before/after comparison below the diff using kitty's
# icat instead.
#
# Rendering technique: kitty's icat --unicode-placeholder, not absolute
# --place coordinates. Per kovidgoyal (kitty's author) in
# https://github.com/junegunn/fzf/issues/3228, absolute placement races
# against fzf's own concurrent reads of the same tty and can hang (we hit
# exactly this: killed at exit 137, no output). Unicode-placeholder mode
# instead emits real placeholder text that flows, scrolls, and gets cleared
# like any other terminal text — which is also why it needs no manual
# cleanup on exit, unlike the absolute-placement version of this script.
# This is the same technique fzf's own bundled example
# (fzf/bin/fzf-preview.sh) uses, so `--place=WxH@0x0` below is deliberately
# always "@0x0" (pane-relative), never FZF_PREVIEW_TOP/LEFT.
set -uo pipefail

debug_log=/tmp/forgit-log-preview-debug.log
debug() { [[ -n ${FORGIT_LOG_PREVIEW_DEBUG:-} ]] && printf '%s\n' "$*" >>"$debug_log"; }

line=$1
debug "=== line=[$line] KITTY_WINDOW_ID=[${KITTY_WINDOW_ID:-}] FZF_PREVIEW_LINES=[${FZF_PREVIEW_LINES:-}] FZF_PREVIEW_COLUMNS=[${FZF_PREVIEW_COLUMNS:-}]"
sha=$(grep -Eo '[a-f0-9]+' <<<"$line" | head -1)
context=${FORGIT_PREVIEW_CONTEXT:-3}
debug "sha=[$sha]"

show_diff() {
    git show --color=always -U"$context" "$sha" "$@" | eval "${FORGIT_PREVIEW_PAGER:-cat}"
}

render_image=0
if [[ -n ${KITTY_WINDOW_ID:-} ]] && command -v kitten &>/dev/null; then
    render_image=1
else
    debug "no image rendering: KITTY_WINDOW_ID or kitten missing"
fi

images=()
if [[ $render_image == 1 ]]; then
    image_re='\.(png|jpe?g|gif|bmp|webp|tiff?|ico|avif|svg)$'
    mapfile -t images < <(git diff-tree --no-commit-id --name-only --diff-filter=d -r --root "$sha" | grep -Ei "$image_re")
    debug "images=(${images[*]:-})"
fi

if [[ ${#images[@]} -eq 0 ]]; then
    show_diff --
    exit 0
fi

# Don't let delta render a "diff" of the image files themselves — for a
# binary it's just noise ("Binary files ... differ"), and for a Git
# LFS-tracked image it's a meaningless diff of the pointer text (oid/size).
# Exclude them so only genuinely-diffable files (if any) take up the pane;
# the images render below instead.
exclude_pathspecs=(".")
for f in "${images[@]}"; do
    exclude_pathspecs+=(":(exclude)$f")
done
show_diff -- "${exclude_pathspecs[@]}"

: "${FZF_PREVIEW_COLUMNS:=80}" "${FZF_PREVIEW_LINES:=40}"
image_rows=${FORGIT_LOG_PREVIEW_IMAGE_ROWS:-20}

# Resolves $1=<sha> $2=<path> to a renderable raster file, printing its path
# to stdout on success (caller must rm it). Handles Git LFS pointers and
# rasterizes SVGs (via resvg, the same tool yazi uses for SVG previews).
resolve_image() {
    local at_sha=$1 path=$2 blob_tmp raster_tmp smudge_tmp smudge_err resvg_err
    blob_tmp=$(mktemp --suffix=".${path##*.}")
    if ! git show "${at_sha}:${path}" >"$blob_tmp" 2>/dev/null; then
        debug "  resolve_image ${at_sha}:${path}: git show failed"
        rm -f "$blob_tmp"
        return 1
    fi
    if head -c 60 "$blob_tmp" 2>/dev/null | grep -q '^version https://git-lfs\.github\.com/spec/v1'; then
        smudge_tmp=$(mktemp --suffix=".${path##*.}")
        if smudge_err=$(git lfs smudge -- "$path" <"$blob_tmp" 2>&1 >"$smudge_tmp"); then
            mv "$smudge_tmp" "$blob_tmp"
        else
            debug "  resolve_image ${at_sha}:${path}: lfs smudge failed: $smudge_err"
            rm -f "$blob_tmp" "$smudge_tmp"
            return 1
        fi
    fi
    if [[ ${path,,} == *.svg ]]; then
        if ! command -v resvg &>/dev/null; then
            debug "  resolve_image ${at_sha}:${path}: svg but no resvg binary"
            rm -f "$blob_tmp"
            return 1
        fi
        raster_tmp=$(mktemp --suffix=".png")
        if ! resvg_err=$(resvg "$blob_tmp" "$raster_tmp" 2>&1); then
            debug "  resolve_image ${at_sha}:${path}: resvg failed: $resvg_err"
            rm -f "$blob_tmp" "$raster_tmp"
            return 1
        fi
        rm -f "$blob_tmp"
        printf '%s' "$raster_tmp"
        return 0
    fi
    printf '%s' "$blob_tmp"
    return 0
}

# --transfer-mode must be explicit: the default "detect" negotiates with
# the terminal, and that round-trip is exactly the kind of read that races
# against fzf's concurrent tty access and hangs. Must be "stream"
# specifically, not "memory" — fzf's own CHANGELOG (0.43.0) and its bundled
# fzf-preview.sh both say memory is faster but only stream lets fzf
# properly redraw the image when the preview pane scrolls or resizes;
# memory mode is what caused images to go stale/wrong on scroll. The
# trailing sed pair mirrors fzf's own script too — icat's last line is a
# bare ANSI reset with no newline, which left uncorrected confuses fzf's
# scroll-offset rendering.
render_block() {
    local path=$1
    timeout --signal=TERM --kill-after=2 3 kitten icat --transfer-mode=stream --unicode-placeholder \
        --stdin=no --scale-up --place="${FZF_PREVIEW_COLUMNS}x${image_rows}@0x0" \
        "$path" 2>/dev/null | sed '$d' | sed $'$s/$/\e[m/'
    debug "  render_block $path exit=$?"
}

parent_sha=$(git rev-parse "${sha}^" 2>/dev/null) || parent_sha=""
debug "parent_sha=[$parent_sha]"

tmp_files=()
trap 'rm -f "${tmp_files[@]}"' EXIT

for f in "${images[@]}"; do
    old_render=""
    if [[ -n $parent_sha ]] && git cat-file -e "${parent_sha}:${f}" 2>/dev/null; then
        old_render=$(resolve_image "$parent_sha" "$f")
        [[ -n $old_render ]] && tmp_files+=("$old_render")
    fi
    new_render=$(resolve_image "$sha" "$f")
    [[ -n $new_render ]] && tmp_files+=("$new_render")
    debug "file=$f old_render=[$old_render] new_render=[$new_render]"

    printf '\n\033[1m%s\033[0m\n' "$f"
    if [[ -n $old_render ]]; then
        printf '\033[2mBefore:\033[0m\n'
        render_block "$old_render"
    else
        printf '\033[2m(new file)\033[0m\n'
    fi
    if [[ -n $new_render ]]; then
        printf '\033[2mAfter:\033[0m\n'
        render_block "$new_render"
    fi
done

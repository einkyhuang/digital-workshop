#!/usr/bin/env bash
# TikTok A号 · 竖屏短剧切片工具
# 素材目录：/workspace/media/tiktok/A号/（视频不进 git）
# 用法示例：
#   ./tiktok_cut.sh cut   INPUT.mp4 12.5 45 OUT.mp4
#   ./tiktok_cut.sh v916  INPUT.mp4 OUT.mp4          # 强制 9:16（裁切或加边）
#   ./tiktok_cut.sh hook  INPUT.mp4 OUT.mp4          # 取前 3 秒钩子预览
#   ./tiktok_cut.sh sub   INPUT.mp4 "字幕文本" OUT.mp4
#   ./tiktok_cut.sh all   INPUT.mp4 12.5 45 "字幕" OUT.mp4  # 切片+竖屏+字幕
set -euo pipefail

W=1080
H=1920
FPS=30
CRF=20
AUDIO_BR="192k"
FONT_FILE="${TIKTOK_FONT:-/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf}"
# 字幕样式：底部安全区，白字黑描边，字号约 48（相对 1080 宽）
SUB_STYLE="FontName=DejaVu Sans,FontSize=48,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,BorderStyle=1,Outline=3,Shadow=0,Alignment=2,MarginV=180"

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

need() { command -v "$1" >/dev/null || { echo "缺少命令: $1" >&2; exit 2; }; }
need ffmpeg
need ffprobe

ensure_font() {
  if [[ ! -f "$FONT_FILE" ]]; then
    echo "警告: 字体不存在 $FONT_FILE，字幕可能失败。可设 TIKTOK_FONT=/path/to.ttf" >&2
  fi
}

# 将任意比例转为 9:16：先缩放覆盖，再居中裁切；不足则加黑边
to_916() {
  local in="$1" out="$2"
  ffmpeg -y -i "$in" -vf "scale=${W}:${H}:force_original_aspect_ratio=increase,crop=${W}:${H},setsar=1,fps=${FPS}" \
    -c:v libx264 -preset medium -crf "$CRF" -c:a aac -b:a "$AUDIO_BR" -movflags +faststart "$out"
}

# 时间切片（秒，支持小数）
cut_seg() {
  local in="$1" start="$2" end="$3" out="$4"
  ffmpeg -y -ss "$start" -to "$end" -i "$in" -c copy -avoid_negative_ts make_zero "$out" 2>/dev/null \
    || ffmpeg -y -ss "$start" -to "$end" -i "$in" -c:v libx264 -crf "$CRF" -c:a aac -b:a "$AUDIO_BR" -movflags +faststart "$out"
}

# 前 3 秒钩子预览
hook3() {
  local in="$1" out="$2"
  ffmpeg -y -ss 0 -t 3 -i "$in" -c:v libx264 -crf "$CRF" -c:a aac -b:a "$AUDIO_BR" -movflags +faststart "$out"
}

# 烧录单行字幕（底部）
burn_sub() {
  ensure_font
  local in="$1" text="$2" out="$3"
  # 转义 drawtext 特殊字符
  local esc
  esc=$(printf '%s' "$text" | sed "s/\\\\/\\\\\\\\/g; s/:/\\\\:/g; s/'/\\\\'/g")
  ffmpeg -y -i "$in" -vf "drawtext=fontfile=${FONT_FILE}:text='${esc}':fontsize=48:fontcolor=white:borderw=3:bordercolor=black:x=(w-text_w)/2:y=h-180" \
    -c:v libx264 -crf "$CRF" -c:a copy -movflags +faststart "$out"
}

cmd="${1:-}"
case "$cmd" in
  cut)
    [[ $# -eq 5 ]] || usage
    cut_seg "$2" "$3" "$4" "$5"
    ;;
  v916)
    [[ $# -eq 3 ]] || usage
    to_916 "$2" "$3"
    ;;
  hook)
    [[ $# -eq 3 ]] || usage
    hook3 "$2" "$3"
    ;;
  sub)
    [[ $# -eq 4 ]] || usage
    burn_sub "$2" "$3" "$4"
    ;;
  all)
    # all INPUT start end "字幕" OUT
    [[ $# -eq 6 ]] || usage
    in="$2"; start="$3"; end="$4"; text="$5"; out="$6"
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT
    cut_seg "$in" "$start" "$end" "$tmpdir/cut.mp4"
    to_916 "$tmpdir/cut.mp4" "$tmpdir/v916.mp4"
    if [[ -n "$text" ]]; then
      burn_sub "$tmpdir/v916.mp4" "$text" "$out"
    else
      mv "$tmpdir/v916.mp4" "$out"
    fi
    echo "完成: $out"
    ;;
  *)
    usage
    ;;
esac

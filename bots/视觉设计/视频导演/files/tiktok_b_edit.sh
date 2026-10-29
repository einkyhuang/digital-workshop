#!/usr/bin/env bash
# TikTok B号剪辑流水线：切片 → 9:16 1080x1920 → 烧录英文字幕 → 叠配乐压低音量 → TikTok 导出参数
# 素材目录：/workspace/media/tiktok/B号/（视频不进 git）
# 用法见 deliverables/TikTok-B号-剪辑模板和标准-20261030.md
set -euo pipefail

MEDIA_ROOT="${MEDIA_ROOT:-/workspace/media/tiktok/B号}"
RAW_DIR="$MEDIA_ROOT/raw"
WORK_DIR="$MEDIA_ROOT/work"
OUT_DIR="$MEDIA_ROOT/out"
MUSIC_DIR="$MEDIA_ROOT/music"
SUBS_DIR="$MEDIA_ROOT/subs"

EPISODE=""
TITLE="untitled"
SRT=""
MUSIC=""
MUSIC_VOL="0.18"
DEMO=0
CUT_START=""
CUT_DUR=""
CLIPS=()

usage() {
  cat <<USAGE
Usage:
  $0 --episode ep01 --title Title_Slug --clips a.mp4 b.mp4 [--srt file.srt] [--music bed.wav] [--music-vol 0.18]
  $0 --demo
  $0 --cut input.mp4 --cut-start 0 --cut-dur 3 --out-clip /path/out.mp4

Env: MEDIA_ROOT (default $MEDIA_ROOT)
USAGE
}

OUT_CLIP=""
CUT_INPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --episode) EPISODE="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    --srt) SRT="$2"; shift 2 ;;
    --music) MUSIC="$2"; shift 2 ;;
    --music-vol) MUSIC_VOL="$2"; shift 2 ;;
    --clips)
      shift
      while [[ $# -gt 0 && "$1" != --* ]]; do CLIPS+=("$1"); shift; done
      ;;
    --demo) DEMO=1; shift ;;
    --cut) CUT_INPUT="$2"; shift 2 ;;
    --cut-start) CUT_START="$2"; shift 2 ;;
    --cut-dur) CUT_DUR="$2"; shift 2 ;;
    --out-clip) OUT_CLIP="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

mkdir -p "$RAW_DIR" "$WORK_DIR" "$OUT_DIR" "$MUSIC_DIR" "$SUBS_DIR"

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1" >&2; exit 1; }; }
need_cmd ffmpeg
need_cmd ffprobe

# --- 单段切片 ---
if [[ -n "$CUT_INPUT" ]]; then
  [[ -n "$OUT_CLIP" && -n "$CUT_START" && -n "$CUT_DUR" ]] || { echo "--cut needs --cut-start --cut-dur --out-clip" >&2; exit 1; }
  ffmpeg -y -ss "$CUT_START" -i "$CUT_INPUT" -t "$CUT_DUR" -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k "$OUT_CLIP"
  echo "Cut -> $OUT_CLIP"
  exit 0
fi

# --- Demo：生成测试素材并跑通 ---
if [[ "$DEMO" -eq 1 ]]; then
  EPISODE="ep01_demo"
  TITLE="Demo_Hook"
  SRT="$SUBS_DIR/ep01_demo.srt"
  MUSIC="$MUSIC_DIR/bed_loop.wav"
  CLIPS=("$RAW_DIR/demo_shot01.mp4" "$RAW_DIR/demo_shot02.mp4" "$RAW_DIR/demo_shot03.mp4")

  # 冷调竖屏测试镜头（无人物，仅验证流水线）
  ffmpeg -y -f lavfi -i "color=c=0x0a1628:s=1080x1920:d=3:r=30" \
    -f lavfi -i "sine=frequency=220:duration=3" \
    -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:text='HOOK 0-3s':fontsize=64:fontcolor=white:x=(w-text_w)/2:y=h*0.35" \
    -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest "${CLIPS[0]}"

  ffmpeg -y -f lavfi -i "color=c=0x1a2a3a:s=1080x1920:d=4:r=30" \
    -f lavfi -i "sine=frequency=330:duration=4" \
    -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:text='FACTORY BEAT':fontsize=56:fontcolor=white:x=(w-text_w)/2:y=h*0.4" \
    -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest "${CLIPS[1]}"

  ffmpeg -y -f lavfi -i "color=c=0x050810:s=1080x1920:d=3:r=30" \
    -f lavfi -i "sine=frequency=110:duration=3" \
    -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:text='CLIFFHANGER':fontsize=56:fontcolor=white:x=(w-text_w)/2:y=h*0.4" \
    -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest "${CLIPS[2]}"

  # 低频床垫配乐（正弦合成，仅测试）
  ffmpeg -y -f lavfi -i "sine=frequency=80:duration=20" -af "volume=0.4" "$MUSIC"

  cat > "$SRT" <<'SRT'
1
00:00:00,500 --> 00:00:02,800
That's not our fabric.

2
00:00:03,200 --> 00:00:06,500
Run it again.

3
00:00:07,000 --> 00:00:09,500
Someone in this mill knows.
SRT

  echo "Demo assets ready under $MEDIA_ROOT"
fi

[[ -n "$EPISODE" ]] || { echo "--episode required (or --demo)" >&2; usage; exit 1; }
[[ ${#CLIPS[@]} -gt 0 ]] || { echo "Need --clips or --demo" >&2; exit 1; }

CONCAT_LIST="$WORK_DIR/${EPISODE}_concat.txt"
SCALED_LIST=()
idx=0
for clip in "${CLIPS[@]}"; do
  [[ -f "$clip" ]] || { echo "Missing clip: $clip" >&2; exit 1; }
  scaled="$WORK_DIR/${EPISODE}_scaled_$(printf '%02d' "$idx").mp4"
  # 转 9:16 1080x1920：铺满后中心裁切；统一 30fps
  ffmpeg -y -i "$clip" \
    -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,fps=30,setsar=1" \
    -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p \
    -c:a aac -ar 48000 -ac 2 -b:a 192k \
    "$scaled"
  SCALED_LIST+=("$scaled")
  idx=$((idx + 1))
done

: > "$CONCAT_LIST"
for s in "${SCALED_LIST[@]}"; do
  # concat demuxer 需要单引号转义
  esc="${s//\'/\'\\\'\'}"
  echo "file '$esc'" >> "$CONCAT_LIST"
done

JOINED="$WORK_DIR/${EPISODE}_joined.mp4"
ffmpeg -y -f concat -safe 0 -i "$CONCAT_LIST" -c copy "$JOINED"

BURNED="$WORK_DIR/${EPISODE}_burned.mp4"
if [[ -n "$SRT" && -f "$SRT" ]]; then
  # 烧录英文字幕；路径转义供 subtitles 滤镜
  SRT_ESC=$(printf '%s' "$SRT" | sed "s/:/\\\\:/g; s/'/\\\\'/g")
  FONT="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
  ffmpeg -y -i "$JOINED" \
    -vf "subtitles=${SRT_ESC}:force_style='FontName=DejaVu Sans,FontSize=48,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,BorderStyle=3,Outline=1,Shadow=0,Alignment=2,MarginV=160'" \
    -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p \
    -c:a copy \
    "$BURNED"
else
  cp "$JOINED" "$BURNED"
  echo "WARN: no SRT; skipped subtitle burn-in" >&2
fi

OUT_FILE="$OUT_DIR/${EPISODE}_${TITLE}_tiktok.mp4"
if [[ -n "$MUSIC" && -f "$MUSIC" ]]; then
  # 叠配乐并压低；保留原片音轨，music 乘以 MUSIC_VOL
  ffmpeg -y -i "$BURNED" -i "$MUSIC" \
    -filter_complex "[1:a]volume=${MUSIC_VOL},aloop=loop=-1:size=2e+09[bg];[0:a][bg]amix=inputs=2:duration=first:dropout_transition=2[aout]" \
    -map 0:v -map "[aout]" \
    -c:v libx264 -profile:v high -level 4.1 -preset medium -crf 19 -pix_fmt yuv420p \
    -movflags +faststart \
    -c:a aac -ar 48000 -ac 2 -b:a 192k \
    -shortest \
    "$OUT_FILE"
else
  ffmpeg -y -i "$BURNED" \
    -c:v libx264 -profile:v high -level 4.1 -preset medium -crf 19 -pix_fmt yuv420p \
    -movflags +faststart \
    -c:a aac -ar 48000 -ac 2 -b:a 192k \
    "$OUT_FILE"
  echo "WARN: no music; exported picture + original audio only" >&2
fi

echo "OK -> $OUT_FILE"
ffprobe -v error -show_entries stream=codec_name,width,height,avg_frame_rate,duration -of default=noprint_wrappers=1 "$OUT_FILE"

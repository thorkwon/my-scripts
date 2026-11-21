#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
    printf '사용법: %s <영상 파일>\n' "$0" >&2
    exit 2
fi

for tool in ffprobe jq; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf '필요한 명령을 찾을 수 없습니다: %s\n' "$tool" >&2
        exit 1
    fi
done

media=$(ffprobe -v error -show_format -show_streams -of json -i "$1")
pixel_depths=$(ffprobe -v error -show_pixel_formats -of json |
    jq -c '.pixel_formats | map({
        key: .name,
        value: ([.components[]?.bit_depth] | max)
    }) | from_entries')

printf '%s\n' "$media" | jq -r --argjson depths "$pixel_depths" '
    def duration:
        (try tonumber catch null) as $total
        | if $total == null then null
          else ($total | round) as $s
          | [
              (if $s >= 3600 then "\($s / 3600 | floor)시간" else empty end),
              (if $s >= 60 then "\($s / 60 | floor | . % 60)분" else empty end),
              "\($s % 60)초"
          ] | join(" ")
          end;
    def fps:
        (try (split("/") | map(tonumber)) catch []) as $rate
        | if ($rate | length) == 2 and $rate[1] > 0 and $rate[0] > 0
          then "\($rate[0] / $rate[1] * 1000 | round / 1000) fps"
          else null
          end;
    def codec:
        . as $name | ({
            h264: "H.264", hevc: "HEVC", av1: "AV1", vp9: "VP9",
            aac: "AAC", ac3: "AC-3", eac3: "E-AC-3", dts: "DTS",
            truehd: "TrueHD", subrip: "SRT", hdmv_pgs_subtitle: "PGS",
            mov_text: "MP4 텍스트", ass: "ASS", ssa: "SSA"
        }[$name // ""] // $name // "미확인");
    def language:
        . as $code | ({
            kor: "한국어", ko: "한국어", eng: "영어", en: "영어",
            jpn: "일본어", ja: "일본어", zho: "중국어", chi: "중국어",
            zh: "중국어", und: "언어 미지정"
        }[$code // ""] // $code // "언어 미지정");
    def audio_layout:
        if .channel_layout == "stereo" then "스테레오"
        elif .channel_layout == "mono" then "모노"
        elif .channel_layout and .channel_layout != "unknown"
        then (.channel_layout | sub("\\(side\\)$"; ""))
        elif .channels then "\(.channels)채널"
        else null
        end;
    def hdr:
        if any(.side_data_list[]?; (.side_data_type // "" | test("dovi|dolby vision"; "i")))
        then "Dolby Vision"
        elif .color_transfer == "smpte2084" then "HDR (PQ)"
        elif .color_transfer == "arib-std-b67" then "HDR (HLG)"
        else null
        end;
    def line($label):
        $label + "  " + (map(select(. != null and . != "")) | join(" · "));

    (.format.filename | split("/") | last) as $file
    | ($file | split(".") | last | ascii_downcase) as $extension
    | ([($file | sub("\\.[^.]+$"; "")),
       (if (["mkv", "mp4", "webm", "mov", "avi", "ts", "m4v"] | index($extension)) != null
        then ($extension | ascii_upcase)
        else (.format.format_name | split(",") | first)
        end),
       (.format.duration | duration)] | join(" · ")),
    (.streams[] | select(.codec_type == "video" and .disposition.attached_pic != 1)
        | [.width as $w | .height as $h | if $w and $h then "\($w)×\($h)" else null end,
           (.codec_name | codec),
           ($depths[.pix_fmt // ""] | if . then "\(.)비트" else "비트 미확인" end),
           ((.avg_frame_rate | fps) // (.r_frame_rate | fps)),
           hdr] | line("영상")),
    (.streams[] | select(.codec_type == "audio")
        | [(.tags.language | language),
           ([if .codec_name == "dts" and (.profile // "" | startswith("DTS-HD"))
             then .profile else (.codec_name | codec) end,
             audio_layout] | map(select(. != null)) | join(" "))]
        | line("음성")),
    (.streams[] | select(.codec_type == "subtitle")
        | [(.tags.language | language), "\(.codec_name | codec) (내장)"] | line("자막"))
'

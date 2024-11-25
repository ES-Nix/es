

### openai-whisper, ffmpeg-full, yt-dlp

0)
```bash
nix \
shell \
github:NixOS/nixpkgs/nixpkgs-unstable#{openai-whisper,ffmpeg-full,yt-dlp}
```

1)
```bash
yt-dlp \
--download-sections "*126-132" \
-v https://www.youtube.com/embed/BODYe-Jy2AQ \
--force-ipv4 \
--output video.webm
```

2)
```bash
ffmpeg \
-i video.webm \
-c:a copy \
-c:v copy \
-c:s copy \
-preset veryslow \
video.mp4
```
Refs.:
- https://www.reddit.com/r/ffmpeg/comments/vvjrcc/need_advice_on_how_to_properly_convert_webm_to_mp4/

3)
```bash
whisper \
video.mp4 \
--model small \
--language Portuguese \
--output_format='all'
```


4)
```bash
ffmpeg \
-i video.mp4 \
-i video.srt \
-c:v copy \
-c:a copy \
-c:s mov_text \
capionedvideo.mp4
```
Refs.:
- https://lists.ffmpeg.org/pipermail/ffmpeg-user/2015-May/026403.html


Extra Refs.:
- https://williamhuster.com/automatically-subtitle-videos/
- https://www.reddit.com/r/ffmpeg/comments/114uyyw/how_to_convert_webm_to_mp4_as_well_as_do_the/
- https://superuser.com/questions/1556953/why-does-preset-veryfast-in-ffmpeg-generate-the-most-compressed-file-compared
- https://www.reddit.com/r/ffmpeg/comments/vvjrcc/need_advice_on_how_to_properly_convert_webm_to_mp4/
- https://trac.ffmpeg.org/wiki/Encode/H.264#Two-PassExample





```bash
yt-dlp \
--download-sections "*126-192" \
-v https://www.youtube.com/embed/lV8-1S28ycM \
--force-ipv4 \
--extractor-args 'youtube:player_client=ios' \
--output video.mp4


whisper \
video.mp4 \
--model small \
--language en \
--output_format='all'

ffmpeg \
-i video.mp4 \
-vf subtitles=video.srt \
output_srt.mp4
```



```bash
yt-dlp \
--download-sections "*321-413" \
-v https://www.youtube.com/embed/9l-U2NwbKOc \
--force-ipv4 \
--output video
```



TODO:
-sub_charenc ISO8859-1
https://superuser.com/questions/494841/how-can-i-fix-delayed-subtitles-in-videos#comment2485403_1242613

TODO:
ffmpeg -i video1.webm -fps_mode passthrough -f mp4 video1.mp4

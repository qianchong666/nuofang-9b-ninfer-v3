@echo off
setlocal
set CUDA_VISIBLE_DEVICES=1
cd /d %~dp0
echo Starting nuofang-9B (ninfer fork engine, 262144 ctx, int8 KV) on 127.0.0.1:19190
ninfer-serve.exe nuofang-9b-ninfer-v3-q6head.ninfer ^
 --model-id nuofang-9b --host 127.0.0.1 --port 19190 ^
 --max-context 262144 --kv-capacity 262144 --kv-dtype int8 --cors --no-thinking --default-max-tokens 6144 ^
 --temperature 1.0 --top-p 0.95 --top-k 20 --min-p 0.02 --presence-penalty 0.5 --frequency-penalty 0.3 ^
 --chat-template chat_template.jinja
pause

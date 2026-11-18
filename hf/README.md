---
language:
  - zh
  - en
library_name: ninfer
pipeline_tag: text-generation
license: apache-2.0
base_model:
  - nuofang/Qwen3.8-9B-Distill-SLERP-F451-Pro-Writer-Uncensored
tags:
  - ninfer
  - nfer-v3
  - nsfw
  - uncensored
  - novel
  - roleplay
  - chinese
  - qwen3.5
  - 9b
  - quantization
---

# nuofang-9B-SLERP-F451 · NInfer v3 artifact（Q6 词表头，sm_86）

> 项目主页（引擎构建产物 + 完整复现文档）：`https://github.com/<你的账号>/nuofang-9b-ninfer-v3`

本仓**只有转换后的 NInfer 容器**，不含新训练权重、不含引擎。权重来自下面的原作者仓库，我们只做格式转换并在真机上验证。

- **成人向（NSFW）**，18+，仅限当地法律允许的用途；不得用于未成年人相关内容或任何违法用途。
- 上游作者未参与本制品的转换，不对其输出负责；AS IS，无担保。

## 一、数据源头（权重链）

| 层级 | 仓库 | 作用 |
|---|---|---|
| **直接来源** | [`nuofang/Qwen3.8-9B-Distill-SLERP-F451-Pro-Writer-Uncensored`](https://huggingface.co/nuofang/Qwen3.8-9B-Distill-SLERP-F451-Pro-Writer-Uncensored) | 9B SLERP 合成本体（作者自述主打中文 NSFW / 角色扮演 / 小说）；本制品由它 1:1 转换而来 |
| 合并父模型 A | [`petruhonk/Qwen3.8-9B-Distill-uncensored-heretic`](https://huggingface.co/petruhonk/Qwen3.8-9B-Distill-uncensored-heretic) | Qwen3.8 全参蒸馏回 Qwen3.5-9B 架构 + heretic 去审查 |
| 合并父模型 B | [`DavidAU/Qwen3.5-9B-The-Bradbury-F451-Pro-Writer-Uncensored-Heretic`](https://huggingface.co/DavidAU/Qwen3.5-9B-The-Bradbury-F451-Pro-Writer-Uncensored-Heretic) | 写作专修（vivid prose / anti-slop） |
| 蒸馏来源 | [`empero-ai/Qwen3.8-9B-Distill`](https://huggingface.co/empero-ai/Qwen3.8-9B-Distill) | 教师轨迹蒸馏（orig repo） |
| **架构基座** | [`Qwen/Qwen3.5-9B`](https://huggingface.co/Qwen/Qwen3.5-9B) | 32 层 hybrid：8 层全注意力 + 24 层 GDN 线性注意力，hidden 4096，词表 248,320，位置容量 262,144 |

**转换不是再训练**：无新数据、无微调、无指令对齐、无拒绝率重测。容器内每个矩阵乘张量按其 ggml 分组精度重新编码
（`q4_g64_fp16` / `q5_g64_fp16` / `q6_g64_fp16` / `q8_g32_fp16`），norm 与 GDN 的 `A_log`/`dt_bias` 保持 bf16/fp32。

## 二、特性

| 项 | 值 |
|---|---|
| 架构 | Qwen3.5-9B hybrid（32 层；`layer_types` = 24×linear_attention + 8×full_attention，`full_attention_interval=4`） |
| 参数 | 9.19 B（`n_params` 9197093888） |
| 上下文 | 原生 **262,144**（`max_position_embeddings`，本机实测 253,783 token 无截断） |
| 组件 | `text` + `mtp`（单层 MTP 头）；**无视觉塔**，不能看图 |
| 文件 | 5.93 GB（5,935,874,304 B），403 objects |
| 内部格式 | `bf16 + fp32 + q4_g64_fp16 + q5_g64_fp16 + q6_g64_fp16 + q8_g32_fp16` |
| 精度分配 | 词表/输出头 **Q6**，gate/up **Q4**，其余投影 **Q5**，MTP 头 **Q8**，norm/RoPE **bf16/fp32** |
| 转换 | 官方 `tools/convert`，recipe **`qwen3_6_27b`**，`--components text,mtp`，CPU 约 130 s |
| 语言 | 中文（主要）、英文（基座能力） |
| 用途 | 中文长篇/网文续写、角色扮演、成人向文学创作 |

### 为什么词表头必须是 Q6

目标引擎 fork（9B 形状内核的那条线）的 q8 形状表里没有 `n248320_k4096`；用 Q8 词表造的件启动即
`q8 linear: unsupported shape`。改用 Q6 词表/输出头即可，代价很小（词表 2.0 B 参数，Q6 与 Q8 差 ~0.5 GB）。

## 三、实测（单卡 RTX 3090 24 GB，int8 KV，`--no-thinking`，不开 MTP）

| 上下文 | prefill | decode | VRAM |
|---|---:|---:|---:|
| 903 | 1.75k tok/s | **132.4 tok/s** | — |
| 29,033 | 3.39k tok/s | **122.4 tok/s** | — |
| 253,783（满窗） | 2.23k tok/s（TTFT 1m54s） | **79.3 tok/s** | **10.1 GB** |

同卡同权重对照：llama.cpp b12470 + Q8_0 GGUF = 76.8 / 64.9 / 25.2 tok/s。
MTP：`--spec mtp --draft-tokens 3` 接受率 28.7%，decode 120.4 —— **比不开慢，不建议开**。

采样：`temperature 0.85 / top_p 0.9 / top_k 20`，中文长篇续写提示。

## 四、用法（Windows / RTX 3090）

引擎不在本仓：到项目主页的 Releases 取 `ninfer-serve-sm86-win-x64.zip`（sm_86 exe + CRT），
再补 CUDA 13.3 的 `cublasLt64_13.dll` / `cublas64_13.dll` / `cudart64_13.dll` 与 FFmpeg 的
`avcodec-63` / `avformat-63` / `avutil-61` / `swscale-10` / `swresample-7`。

```bat
set CUDA_VISIBLE_DEVICES=0
ninfer-serve.exe nuofang-9b-ninfer-v3-q6head.ninfer ^
  --model-id nuofang-9b --host 127.0.0.1 --port 19190 ^
  --max-context 262144 --kv-capacity 262144 --kv-dtype int8 ^
  --cors --no-thinking --default-max-tokens 6144 ^
  --chat-template chat_template.jinja
```

`/v1/models` 应回 `status.value: "loaded"`、`context_window: 262144`。上下文不够时先降 `--kv-capacity`
（int8 KV 约 16 KiB/token，8 层全注意力）。

## 五、限制

- 只在 **sm_86（3090）** 实测；Ada/Blackwell 未验证。
- 引擎来自社区 fork（0★，非上游官方支持）；换 quant 档可能触发 `unsupported shape`。
- 9B 档中文网文质量不及 27B 档（如 `dongfangshuo/Dongfangshuo-Qwen3.8-27B-NSFW-Novel`），
  本制品的优势是**单卡 256K + 132 tok/s**。
- 未做拒绝率/安全对齐评估；这是 NSFW 用途的破甲模型，请自行判断合规性。

## 六、校验

```
51c15da99cfe997c6c9e0628372d50c0324521a7348c4339978dd052c2ccbed7  nuofang-9b-ninfer-v3-q6head.ninfer
```

# nuofang-9B-NInfer-v3 · 中文 NSFW 写作模型跑进 NInfer（单卡 3090，132 tok/s，满窗 256K）

把 9B 档的中文 NSFW / 小说 / 角色扮演模型
[`nuofang/Qwen3.8-9B-Distill-SLERP-F451-Pro-Writer-Uncensored`](https://huggingface.co/nuofang/Qwen3.8-9B-Distill-SLERP-F451-Pro-Writer-Uncensored)
转成 **NInfer v3 容器**，在 **RTX 3090（sm_86）** 上跑通并跑满原生 **262,144** 上下文。

- 🧠 模型文件（5.93 GB，HF）：[`tomas123123/nuofang-9b-ninfer-v3-q6head`](https://huggingface.co/tomas123123/nuofang-9b-ninfer-v3-q6head)
- ⚙️ 引擎：本仓 [`Releases`](../../releases) 里的 11 个分卷 `ninfer-serve-sm86-win-x64-engine.7z.001…011`（合计 704 MB，sm_86 exe + CRT；下载后用 7-Zip 打开 `.001` 自动串接解压）
- 📊 实测：**132.4 tok/s @ 903 上下文**、122.4 @ 29k、**79.3 @ 254k**；llama.cpp 同件只有 76.8 / 64.9 / 25.2

> ⚠️ 成人向（NSFW）内容，18+，仅限当地法律允许的用途。

## 为什么需要这个项目

上游 NInfer（[Neroued/ninfer](https://github.com/Neroued/ninfer) 及其 27B / 35B-A3B 各条线）**不支持 9B 几何**。
`src/ops/weight_input.cpp` 的形状白名单只认两种：

| 档位 | attention q/k | GDN A/B |
|---|---|---|
| 27B-dense | `{6144,5120}` / `{1024,5120}` | `{48,5120}` |
| 35B-A3B-MoE | `{4096,2048}` / `{512,2048}` | `{32,2048}` |

9B 是 hidden 4096 / 16 Q 头 / 4 KV 头 / GDN **32** 值头 → `{32,4096}`，两档都不在，启动即
`unsupported logical projection geometry` 或 `unsupported A/B geometry`。

社区 fork [`wemxueming/ninfer-for-index-translate-9b-4060`](https://github.com/wemxueming/ninfer-for-index-translate-9b-4060)
补了 9B 的线性和注意力形状内核，本仓把**编译、转换、启动、实测**整条链固化下来，并公开了 sm_86 构建产物。

## 实测数据（RTX 3090 24 GB，int8 KV，`--no-thinking`，无 MTP）

| 上下文 | prefill | decode | 备注 |
|---|---:|---:|---|
| 903 | 1.75k tok/s | **132.4 tok/s** | TTFT 517 ms（冷） |
| 29,033 | 3.39k tok/s | **122.4 tok/s** | |
| 253,783 | 2.23k tok/s | **79.3 tok/s** | 满窗 262,144，无截断，VRAM **10.1 GB** |
| 903 + `--spec mtp --draft-tokens 3` | 1.38k tok/s | 120.4 tok/s | MTP 接受率 236/821 = 28.7%，仍比不开慢 |

对照（同卡、同权重、llama.cpp b12470 + Q8_0 GGUF，`-fa on`、q8_0 KV）：

| 上下文 | 本方案 | llama.cpp |
|---|---:|---:|
| ~900 / 1.2k | **132.4** | 76.8 |
| ~23–29k | **122.4** | 64.9 |
| ~254k | **79.3** | 25.2 |

同卡同件的旧改树（只有白名单、没有形状内核）只有 28.8 / 29.0 —— 可见差距来自形状内核，不是白名单。

## 模型地址（Hugging Face）

```
https://huggingface.co/tomas123123/nuofang-9b-ninfer-v3-q6head
```

HF 上只放**转换后的 NInfer 制品**（`nuofang-9b-ninfer-v3-q6head.ninfer`，5.93 GB）+ `conversion.json` + 模型卡；
引擎与全部文档在本仓 / Release。

文件校验：

```
51c15da99cfe997c6c9e0628372d50c0324521a7348c4339978dd052c2ccbed7  nuofang-9b-ninfer-v3-q6head.ninfer   (5,935,874,304 B)
```

制品内部格式：`bf16 + fp32 + q4_g64_fp16 + q5_g64_fp16 + q6_g64_fp16 + q8_g32_fp16`
（词表/输出头 **Q6**、gate/up **Q4**、其余 **Q5**、MTP 头 Q8），组件 = `text` + `mtp`，无视觉塔。

## 快速开始（Windows / RTX 3090）

```bat
:: 1) 引擎：下载 Release 里全部 11 个分卷（...-engine.7z.001…011），用 7-Zip 打开 .001 解压（自动合并）
:: 2) 补第三方 DLL（本仓不打包）：
::    CUDA 13.3 - cublasLt64_13.dll, cublas64_13.dll, cudart64_13.dll
::    FFmpeg   - avcodec-63, avformat-63, avutil-61, swscale-10, swresample-7
:: 3) 模型：从 HF 下 nuofang-9b-ninfer-v3-q6head.ninfer 和 chat_template.jinja
set CUDA_VISIBLE_DEVICES=0
ninfer-serve.exe nuofang-9b-ninfer-v3-q6head.ninfer ^
  --model-id nuofang-9b --host 127.0.0.1 --port 19190 ^
  --max-context 262144 --kv-capacity 262144 --kv-dtype int8 ^
  --cors --no-thinking --default-max-tokens 6144 ^
  --chat-template chat_template.jinja
```

验收三件：日志 `engine ready | qwen38-9b-nuofang-q6head`、`/v1/models` 的 `status.value == "loaded"`、
真实请求有内容且日志给出 `decode xxx tok/s`。
现成启动器见 [`examples/run-sm86-262k.bat`](examples/run-sm86-262k.bat)。

## 目录

```
docs/BUILD-INFO.md    制品转换 + 引擎编译的完整复现（含三个坑）
docs/NOTICE.md       权重链、许可归属、未打包的第三方二进制
scripts/reuse-objs.py 编译加速：复用另一棵树的同字节 .obj（1148 步 → 53 步）
scripts/build-sm86.bat 一键配置 + 编译（VS18 + CUDA 13.3 + Ninja + vcpkg）
examples/             启动器示例
hf/                   上传到 HF 的模型卡原文
```

## 三个坑（都实测过）

| 坑 | 现象 | 处置 |
|---|---|---|
| 形状白名单 | `unsupported logical projection geometry` / `unsupported A/B geometry` | 上游引擎不支持 9B；用本仓对应的 fork 构建 |
| q8 词表头 | `q8 linear: unsupported shape` | 用 **Q6 头**的 recipe（`qwen3_6_27b`）重造制品 |
| 编译器 | `error C2326`（`attn_input_proj/*_unified.cu` 模板 lambda） | **VS18 BuildTools（MSVC 14.51）**；VS2022 14.44 编不过 |

## 许可与致谢

权重归原作者的链条：`nuofang` → `petruhonk` + `DavidAU` → `empero-ai` → `Qwen/Qwen3.5-9B`。
引擎与容器格式：`Neroued/ninfer`（Apache-2.0）→ `1314521gjy/ninfer-fusion-kvmem` → `wemxueming/ninfer-for-index-translate-9b-4060`。
详情见 [`docs/NOTICE.md`](docs/NOTICE.md)。本仓按 Apache-2.0 发布，AS IS，无担保。

## English

A reproducible pipeline that runs the 9B Chinese NSFW/novel merge
`nuofang/Qwen3.8-9B-Distill-SLERP-F451-Pro-Writer-Uncensored` on NInfer v3:

- upstream NInfer has no 9B geometry (whitelists cover only 27B-dense and 35B-A3B-MoE);
- the community fork `wemxueming/ninfer-for-index-translate-9b-4060` adds the 9B shape kernels — this repo
  pins the build (VS18 + CUDA 13.3 + Ninja + vcpkg), the conversion recipe (`qwen3_6_27b`, Q6 vocab head),
  and the measured numbers;
- **132.4 tok/s @ 903 ctx, 122.4 @ 29k, 79.3 @ 254k** on a single RTX 3090, full 262,144 window in 10.1 GB VRAM,
  vs llama.cpp's 76.8 / 64.9 / 25.2 on the same card and weights.

Artifact lives on Hugging Face (5.93 GB); the sm_86 engine binary is attached to Releases.

## 7 采样参数：让每次写出来都不一样

模型自带的 non-thinking 默认是 `temperature 0.70 / top_p 0.80 / presence_penalty 1.5`，
中文创作容易套模板——同题六次，三次开头都是「沈砚踩碎积雪，靴底发出…」。

实测对比（同题各 6 次；相似度 = 字符级 `SequenceMatcher` 两两平均，4-gram = 字面 4-gram Jaccard）：

| 采样 | 两两相似度 | 4-gram 重合 | 平均长度 |
|---|---:|---:|---:|
| 旧默认 `0.70 / 0.80 / p1.5` | 0.241 | 0.037 | 161 |
| **推荐 `1.00 / 0.95 / k20 / minp0.02 / p0.5 / f0.3`** | **0.204** | **0.011** | 160 |
| 更野 `1.15`（同样惩罚） | 0.161 | 0.012 | 166 |

起服时把默认值改掉（客户端不传采样参数时才生效）：

```
--temperature 1.0 --top-p 0.95 --top-k 20 --min-p 0.02 --presence-penalty 0.5 --frequency-penalty 0.3
```

- 想要更发散：`--temperature 1.15`；要更稳：`0.9`
- `--seed` 默认每请求随机，这本身就是去雷同的一环；固定 seed 会让输出可复现，想要多样性就别固定
- 客户端（如 Qoder / 各类前端）自己发 `temperature`/`top_p` 时**会覆盖**服务端默认
- 本引擎的硬限制：`top_k` 只能 **0–20**（发 40 会 `400 top_k must be in [0,20]`）；`n>1`、`logprobs` 也不支持


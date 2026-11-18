# BUILD-INFO — 怎么把这个制品和这台引擎造出来

全部命令都是本机（Windows 11 + RTX 3090 sm_86）实测跑通的，2026-11-18。

## 0. 结论先看：两个必要条件

1. **引擎**必须用社区 fork `wemxueming/ninfer-for-index-translate-9b-4060`（基于 `1314521gjy/ninfer-fusion-kvmem` 快照 `9a5a920`）编 **sm_86**。
   上游 NInfer（Neroued / Don-Chad / ashalliants / kvmem）的形状白名单里没有 9B 几何，用上游件启动会直接 FATAL。
2. **制品**必须让词表 / 输出头落在 **Q6**：该 fork 的 q8 形状表没有 `n248320_k4096`，用官方 `qwen3_8_27b`（Q8 头）造的件启动报 `q8 linear: unsupported shape`。

## 1. 造制品（纯 CPU，约 2 分钟）

```bat
:: 需要一个只有 config/tokenizer + 4 个 bf16 分片的模型目录
:: HF: nuofang/Qwen3.8-9B-Distill-SLERP-F451-Pro-Writer-Uncensored
hf download nuofang/Qwen3.8-9B-Distill-SLERP-F451-Pro-Writer-Uncensored ^
  config.json tokenizer.json tokenizer_config.json chat_template.jinja generation_config.json ^
  model.safetensors.index.json ^
  model-00001-of-00004.safetensors model-00002-of-00004.safetensors ^
  model-00003-of-00004.safetensors model-00004-of-00004.safetensors ^
  --local-dir G:\aimodels\nuofang-9b-bf16
```

> 坑：`model.safetensors.index.json` 必须存在且文件名完全一致，否则转换器按单文件找张量，报
> `missing source tensor 'model.language_model.layers.0.linear_attn.in_proj_qkv.weight'`。

转换（官方转换器，源码树 `tools/convert`；venv 里只需要 `torch numpy gguf`，CPU 版即可）：

```bat
python -m tools.convert ^
  --model  G:\aimodels\nuofang-9b-bf16 ^
  --recipe qwen3_6_27b ^
  --components text,mtp ^
  --name qwen38-9b-nuofang-q6head ^
  --device cpu ^
  --out G:\aimodels\nuofang-9b-wemx-q6head.ninfer
```

- `qwen3_6_27b` = 官方 `_dense_groupwise(model, recipe, Q6)`：**词表/输出头 Q6**、gate/up Q4、其余 Q5。
- 输出：403 objects、5.93 GB、约 130 秒。容器头是 `NINFER\0` + 版本字节 `03`（v3）。
- 想换档位就换 recipe（`qwen3_8_27b` = Q8 头，本 fork 不支持；`qwen3_8_27b_q6` = Q6 gate/up）。

## 2. 编引擎（Windows，约 1 小时，主要是模板内核慢）

```bat
git clone --depth 1 https://github.com/wemxueming/ninfer-for-index-translate-9b-4060 G:\build\wemx-9b
```

配置（必须 **VS18 BuildTools / MSVC 14.51**；VS2022 14.44 会在 `attn_input_proj/*_unified.cu` 报 `error C2326`）：

```bat
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
set PATH=G:\cuda-13.3\bin;G:\cuda-13.3\bin\x64;%PATH%
set CUDACXX=G:\cuda-13.3\bin\nvcc.exe
set VCPKG_ROOT=G:\build\vcpkg

cmake -S G:\build\wemx-9b\src\src-tree\fusion-engine-src -B G:\build\wemx-86 -G Ninja ^
 -DCMAKE_MAKE_PROGRAM=G:/miniconda3/Scripts/ninja.exe ^
 -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_ARCHITECTURES=86 ^
 -DCMAKE_CUDA_COMPILER=G:/cuda-13.3/bin/nvcc.exe ^
 -DCMAKE_CUDA_COMPILER_TOOLKIT_ROOT=G:/cuda-13.3 ^
 -DCMAKE_PREFIX_PATH=G:/build/vcpkg/installed/x64-windows ^
 -DVCPKG_TARGET_TRIPLET=x64-windows ^
 -DNINFER_BUILD_APPS=ON -DBUILD_TESTING=OFF -DNINFER_BUILD_BENCHMARKS=OFF
```

编译：

```bat
ninja -C G:\build\wemx-86 -j 20 ninfer-serve
```

### 省一大截时间：复用另一棵树的 .obj

两棵树大部分源文件字节相同，可以先编一遍 v0.11 的树（`G:\build\ninfer-86`），再把**同字节源文件**的
`.obj` 按 `compile_commands.json` 的相对路径拷到新 build 目录：待编步数 **1148 → 53**（复用 146 个）。

### 装 DLL

`cmake` 只 stage 了一部分：把 `G:\build\ninfer-86\apps\api-ms-win-crt-*.dll` 拷到新 apps 目录，否则
`error while loading shared libraries: api-ms-win-crt-locale-l1-1-0.dll`。
`cublasLt64_13.dll` / `cublas64_13.dll` / `cudart64_13.dll` 来自 CUDA 13.3 安装；ffmpeg 的
`avcodec-63` / `avformat-63` / `avutil-61` / `swscale-10` / `swresample-7` 来自 vcpkg（纯文本用途可省，但 exe 启动即加载）。

## 3. 起服与验收

```bat
set CUDA_VISIBLE_DEVICES=0
ninfer-serve.exe nuofang-9b-ninfer-v3-q6head.ninfer ^
  --model-id nuofang-9b --host 127.0.0.1 --port 19190 ^
  --max-context 262144 --kv-capacity 262144 --kv-dtype int8 ^
  --cors --no-thinking --default-max-tokens 6144 --chat-template chat_template.jinja
```

验收三件：`engine ready | qwen38-9b-nuofang-q6head`、`/v1/models` 的 `status.value == loaded`、
真实请求返回内容 + 日志里的 `decode xxx tok/s`。

## 4. 三个坑（都实测过）

| 坑 | 现象 | 处置 |
|---|---|---|
| 形状白名单 | `text/layers/0: input projection: unsupported logical projection geometry` / `GDN control: unsupported A/B geometry` | 上游引擎不支持 9B；换本 fork |
| q8 头 | `q8 linear: unsupported shape` | 用 Q6 头 recipe 重造 |
| 编译器 | `error C2326`（模板 lambda） | VS18 BuildTools（MSVC 14.51），不要 2022 的 14.44 |

## 5. 实测数字（RTX 3090 sm_86, int8 KV, --no-thinking, 无 MTP）

| 上下文 | prefill | decode | 备注 |
|---|---:|---:|---|
| 903 | 1.75k tok/s | 132.4 tok/s | TTFT 517 ms（冷） |
| 29,033 | 3.39k tok/s | 122.4 tok/s | |
| 253,783 | 2.23k tok/s | 79.3 tok/s | 满窗 262,144，无截断，VRAM 10.1 GB |
| 903 + `--spec mtp --draft-tokens 3` | 1.38k tok/s | 120.4 tok/s | MTP 接受率 236/821 = 28.7%，仍比不开慢 |

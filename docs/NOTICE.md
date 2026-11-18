# NOTICE — 来源、许可与致谢

本仓不含新训练的权重。它是一份 **容器格式转换产物**（NInfer v3 `.ninfer`）与配套的**编译/转换说明**，
所有模型权重归下列原作者。

## 权重链

| 环节 | 仓库 | 作用 |
|---|---|---|
| 最终权重（本制品的直接来源） | [`nuofang/Qwen3.8-9B-Distill-SLERP-F451-Pro-Writer-Uncensored`](https://huggingface.co/nuofang/Qwen3.8-9B-Distill-SLERP-F451-Pro-Writer-Uncensored) | SLERP 合并（作者自述主打中文 NSFW / 角色扮演 / 小说） |
| 合并父模型 A | [`petruhonk/Qwen3.8-9B-Distill-uncensored-heretic`](https://huggingface.co/petruhonk/Qwen3.8-9B-Distill-uncensored-heretic) | Qwen3.8 全参蒸馏回 Qwen3.5-9B 架构 + heretic 去审查 |
| 合并父模型 B | [`DavidAU/Qwen3.5-9B-The-Bradbury-F451-Pro-Writer-Uncensored-Heretic`](https://huggingface.co/DavidAU/Qwen3.5-9B-The-Bradbury-F451-Pro-Writer-Uncensored-Heretic) | 写作专修（vivid prose / anti-slop） |
| 蒸馏来源 | [`empero-ai/Qwen3.8-9B-Distill`](https://huggingface.co/empero-ai/Qwen3.8-9B-Distill) | 教师轨迹蒸馏 |
| 架构基座 | [`Qwen/Qwen3.5-9B`](https://huggingface.co/Qwen/Qwen3.5-9B) | 32 层 hybrid（8 层全注意力 + 24 层 GDN），266K 词表，262,144 位置 |

## 引擎与工具链

| 组件 | 来源 | 许可 |
|---|---|---|
| NInfer 原始引擎 | [`Neroued/ninfer`](https://github.com/Neroued/ninfer) | Apache-2.0 |
| 本制品所需几何支持的 fork | [`wemxueming/ninfer-for-index-translate-9b-4060`](https://github.com/wemxueming/ninfer-for-index-translate-9b-4060)（基于 `1314521gjy/ninfer-fusion-kvmem` 快照 `9a5a920`） | Apache-2.0 |
| 9B 几何移植的公开记录 | [`lixiaobai21/ninfer-9b-ada-toolkit`](https://github.com/lixiaobai21/ninfer-9b-ada-toolkit)（文档与运维脚本，非引擎本体） | 见其仓 |
| 转换器 | 上述源码树的 `tools/convert`（官方工具，未改动） | Apache-2.0 |

`engine/` 下的 `ninfer-serve.exe` 是用上述 Apache-2.0 源码在 **Windows / sm_86 / CUDA 13.3 / MSVC 14.51** 上
原样编译的产物，未修改源码逻辑（构建参数见 `BUILD-INFO.md`）。按 Apache-2.0 第 4 条，附上上游 LICENSE 文本。

## 未打包的二进制（请自行准备）

- `cublasLt64_13.dll` / `cublas64_13.dll` / `cudart64_13.dll` —— NVIDIA CUDA Toolkit 运行时，按 [CUDA EULA](https://docs.nvidia.com/cuda/eula/index.html) 随 Toolkit 分发；
- `avcodec-63.dll` / `avformat-63.dll` / `avutil-61.dll` / `swscale-10.dll` / `swresample-7.dll` —— FFmpeg（vcpkg 构建），各自 LGPL/GPL 条款；
- `api-ms-win-crt-*.dll` —— Microsoft Universal CRT 转发 DLL。

这些第三方二进制**不随本仓分发**，请从自己的 CUDA / vcpkg 安装里拷贝。

## 使用限制

- 成人向内容（NSFW），**18+**，仅限当地法律允许的用途；不得用于生成未成年人相关内容或任何违法用途。
- 上游作者与 NInfer 各作者**未参与**本制品的转换与编译，不对其行为与输出负责；本仓按 "AS IS" 提供，无任何担保。
- 若原作者要求下架，请告知，本仓将立即移除。

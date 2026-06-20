# video-frame-cluster

对视频帧进行质心联动层次聚类（centroid-linkage, Euclidean distance），输出每簇 medoid 帧为 JPEG。

基于 [rkt-pythonize](https://github.com/Antigen-1/rkt-pythonize)。

## 架构

```
用户   ./cluster.sh [options] <video> [k] [out_dir] [frames] [size]
 │
 ├─ 参数校验 / help
 ├─ Python 自动检测 (venv → $PYTHON → python3 → python)
 ├─ 编译缓存 (.cluster.cache.json, -r 强制重编)
 │
 ▼
┌─────────────────────────────────────────────────────────┐
│                      Racket Shell                       │
│  1. 定位已安装 rkt-pythonize:                            │
│     (collection-path "rkt-pythonize")                   │
│  2. Scheme → JSON:                                      │
│     racket -l- rkt-pythonize -o out.json -- cluster.rkt │
│  3. 执行 JSON (绕过 OS exec 128KB 参数限制):              │
│     PYTHONPATH=<core/> python3 run_json.py out.json     │
└─────────────────────────────────────────────────────────┘
                         │
          ┌──────────────┴──────────────┐
          ▼                              ▼
┌───────────────────┐        ┌──────────────────────────┐
│   cluster.rkt     │        │    cluster_helper.py     │
│   (Scheme 层)     │  FFI   │      (Python 层)         │
│                   │◄──────►│                          │
│  • 读取环境变量配置 │        │  get_config_from_env()   │
│  • let/cc 续延     │        │  extract_and_init() ·抽帧│
│    错误早期退出     │        │  vec_distance_sq() ·欧氏 │
│  • 质心联动层次聚类 │        │  avg_centroids() ·合并   │
│    主循环 (纯算法)  │        │  find_and_save_medoids() │
│                   │        │                          │
└───────────────────┘        └──────────────────────────┘
```

## 依赖

**Racket**: `raco pkg install rkt-pythonize`（自动拉取 `base` + `nanopass`）

**Python** (venv):
```bash
pip install opencv-python-headless numpy
```

## 使用

```bash
./cluster.sh -h                        # 帮助
./cluster.sh my_video.mp4              # 默认 5 类 50 帧
./cluster.sh my_video.mp4 10 out/      # 10 类
./cluster.sh -r my_video.mp4 10 out/ 100 32  # 强制重编 100帧 32×32
```

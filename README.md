# video-frame-cluster

对视频帧进行质心联动层次聚类（centroid-linkage, Euclidean distance），
输出每个簇最靠近质心的帧（medoid）为 JPEG 图片。

基于 [rkt-pythonize](https://github.com/Antigen-1/rkt-pythonize) (Scheme→Python 编译器)。

## 项目结构

```
├── cluster.rkt          Scheme 主程序（聚类算法）
├── cluster_helper.py    Python 辅助（OpenCV I/O、距离/质心计算、图片输出）
├── cluster.sh           Shell 入口（参数解析、Python 检测、编译缓存）
├── run_json.py          编译产物执行器
└── .gitignore
```

## 依赖

### Racket

需要先安装 Racket（≥9.1），然后安装 rkt-pythonize 包：

```bash
raco pkg install rkt-pythonize
```

rkt-pythonize 自身依赖 `base` 和 `nanopass`（`raco pkg install` 会自动拉取）。

### Python

建议创建虚拟环境：

```bash
python3 -m venv venv
source venv/bin/activate
pip install opencv-python-headless numpy
```

| 包 | 版本 (已验证) | 用途 |
|----|-------------|------|
| opencv-python-headless | 4.13 | 视频帧提取、图像缩放与写入 |
| numpy | 2.4 | OpenCV 依赖 |
| Python | 3.10–3.14 | 运行时求值器 core.py |

`scipy` 为上述包的间接依赖，本项目未直接使用。

## 使用

```bash
# 查看帮助
./cluster.sh -h

# 默认参数（5 类，50 帧，resize 16×16）
./cluster.sh my_video.mp4

# 自定义
./cluster.sh my_video.mp4 10 my_output     # 10 类
./cluster.sh my_video.mp4 10 out/ 100 32   # 100 帧，32×32 resize

# 强制重新编译（忽略缓存）
./cluster.sh -r my_video.mp4 5 out/
```

`cluster.sh` 自动检测 Python（优先 venv，其次 `$PYTHON`，最后 `which python3`/`python`）。

## 原理

1. **帧提取** — OpenCV 读视频，等间隔抽帧，resize 到 N×N 灰度图，展平为特征向量
2. **层次聚类** — Scheme 层实现，centroid-linkage 策略：
   - 初始化每个帧为独立簇，质心 = 帧特征向量
   - 循环：找欧氏距离最近的簇对 → 合并 → 新质心 = 加权平均（`(|A|·A + |B|·B) / (|A|+|B|)`）
   - 直到剩余 K 个簇
3. **Medoid 选取** — 每个簇内选取与质心欧氏距离最近的帧
4. **输出** — 选取帧 resize 为 256×256 写入 JPEG

## 错误处理

使用 Scheme `let/cc` 续延实现早期退出：

- 视频路径未设置或为空 → stderr + 退出
- 视频文件不存在 → stderr + 退出
- Python 层异常（如文件打不开）→ Python traceback 到 stderr

## 缓存

编译产物缓存为 `.cluster.cache.json`，`cluster.rkt` 未修改时跳过编译直接执行，约节省 1.5s。

## 许可

Apache-2.0 OR MIT（与 rkt-pythonize 一致）

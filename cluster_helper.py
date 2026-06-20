import cv2
import os

_store = None
_features = None


def get_config_from_env():
    video = os.environ.get("CLUSTER_VIDEO")
    k = int(os.environ.get("CLUSTER_N", "5"))
    out = os.environ.get("CLUSTER_OUTPUT", "cluster_output")
    max_n = int(os.environ.get("CLUSTER_MAX_FRAMES", "50"))
    sz = int(os.environ.get("CLUSTER_SIZE", "16"))
    return (video, k, out, max_n, sz)


def extract_and_init(video, max_frames, size):
    global _store, _features
    cap = cv2.VideoCapture(video)
    if not cap.isOpened():
        raise SystemExit("Cannot open video: " + video)
    total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    step = max(1, total // max_frames)
    frames = []
    feats = []
    cnt = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        if cnt % step == 0 and len(frames) < max_frames:
            resized = cv2.resize(frame, (size, size))
            gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)
            feats.append(gray.flatten().astype("float32").tolist())
            frames.append(resized)
        cnt += 1
    cap.release()
    _store = frames
    _features = feats
    n = len(feats)
    clusters = [[i] for i in range(n)]
    centroids = [list(f) for f in feats]
    sizes = [1] * n
    active = [True] * n
    print("Extracted frames: {}".format(n))
    return (clusters, centroids, sizes, active, n)


def vec_distance_sq(a, b):
    s = 0.0
    for i in range(len(a)):
        d = a[i] - b[i]
        s += d * d
    return s


def avg_centroids(c1, n1, c2, n2):
    total = float(n1 + n2)
    return [(c1[i] * n1 + c2[i] * n2) / total for i in range(len(c1))]


def find_and_save_medoids(active, centroids, clusters, n, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    cid = 0
    for i in range(n):
        if active[i]:
            indices = clusters[i]
            cent = centroids[i]
            best_idx = indices[0]
            best_dist = vec_distance_sq(cent, _store[best_idx].flatten().tolist())
            for idx in indices[1:]:
                d = vec_distance_sq(cent, _store[idx].flatten().tolist())
                if d < best_dist:
                    best_dist = d
                    best_idx = idx
            frame = _store[best_idx]
            larger = cv2.resize(frame, (256, 256))
            path = os.path.join(output_dir, "cluster_{}.jpg".format(cid))
            cv2.imwrite(path, larger)
            print(path)
            cid += 1
    return cid

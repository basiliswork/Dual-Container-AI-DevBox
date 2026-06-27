# Dual Container Homelab Setup 🚀

A high-performance, decoupled local development environment that bridges an isolated LLM inference engine with an optimized NVIDIA NGC TensorFlow workspace. This architecture enables real-time, hardware-accelerated AI pair programming (Aider) and Jupyter workflows on local GPU hardware while completely avoiding system dependency fragmentation.

---

## 🏗️ Architectural Topology

When building modern ML workspaces, cramming heavy developer tooling directly into heavily customized framework images (like NVIDIA NGC containers) frequently causes low-level library memory conflicts, resulting in runtime execution errors (`Segmentation Fault`). 

This project solves that limitation by pivoting from a fragile monolith to a **decoupled, two-container microservices architecture** communicating over a low-latency network bridge:

```text
              ┌────────────────────────────────────────┐
              │               Host Machine             │
              └───────────────────┬────────────────────┘
                                  │ (Shares GPU via --gpus all)
        ┌─────────────────────────┴─────────────────────────┐
        ▼                                                   ▼
┌───────────────────────────────┐                   ┌───────────────────────────────┐
│     TensorFlow Workspace      │                   │     Ollama Inference Layer    │
│  (Aider Chat / Jupyter Lab)   │ ── localhost ───> │     (Qwen 2.5 Coder Server)   │
│   Image: Custom TF Sandbox    │    (Port 11434)   │      Image: ollama/ollama     │
└───────────────────────────────┘                   └───────────────────────────────┘

```

### Key Engineering Features:

* **Separation of Concerns:** Deep learning runtime frameworks remain untouched and fully optimized, while the hardware-accelerated LLM pipeline runs within its own secure environment.
* **Hardware Passthrough:** Both containers share the native host kernel's CUDA driver layers simultaneously via `--gpus all` mappings and shared memory expansion flags.
* **Volume Persistence:** LLM model weights (4.7 GB+) are mapped directly onto the host SSD volume, avoiding massive initialization downloads whenever the infrastructure resets.

---

## 🛠️ Infrastructure Configuration

The repository layout is organized cleanly to enforce operational best practices:

```text
├── README.md               # Architecture documentation & guide
├── launch.sh               # One-click microservice initialization script
└── config/
    └── .aiderignore        # High-weight binary file indexing bypass rules

```

### 1. Repository-Map Optimization (`config/.aiderignore`)

To prevent large context windows from locking up or throwing context-exhaustion errors during codebase indexing, large assets and non-code binary structures are selectively hidden from the LLM scanning engine:

```text
# Bypassing dense binary assets to prevent repository mapping lag
**/Professor_PDFs/**
*.pdf
*.csv
*.h5
*.pkl

```

### 2. Multi-Container Orchestration Handler (`launch.sh`)

The initialization script sequentially verifies the infrastructure state, maps physical hardware ports, sets memory limit boundaries, and boots both environments:

```bash
#!/bin/bash

echo "🚀 Booting background AI inference engine..."
docker run -d --gpus all \
  -v /home/erebus/my_tf_projects/.ollama:/root/.ollama \
  -p 11434:11434 \
  --name ollama-service \
  ollama/ollama 2>/dev/null || docker start ollama-service

echo "⏱️ Allowing GPU VRAM memory mapping to settle..."
sleep 5

echo "🐳 Launching custom TensorFlow workspace environment..."
docker run --gpus all -it --rm --ipc=host --network=host \
  --ulimit memlock=-1 --ulimit stack=67108864 \
  -p 5000:5000 -p 8888:8888 \
  -v /home/erebus/my_tf_projects:/workspace/my_project_container \
  -w /workspace/my_project_container \
  -e OLLAMA_API_BASE="[http://127.0.0.1:11434](http://127.0.0.1:11434)" \
  --entrypoint /bin/sh my_custom_tf_env:latest \
  -c "jupyter lab --ip=0.0.0.0 --port=8888 --allow-root --no-browser --NotebookApp.token='' & exec /bin/bash"

```

---

## 🚀 Quick Deployment Guide

Ensure your host system has the `nvidia-container-toolkit` correctly mapped, then deploy the ecosystem with a single automation wrapper:

### Step 1: Run the Automation script

```bash
./launch.sh

```

### Step 2: Initialize Your On-Device AI Developer Chat

Once inside your running TensorFlow container bash prompt, move directly to your development repository root directory and initialize your local AI collaborator:

```bash
cd "New Thesis"
aider --model ollama/qwen2.5-coder:7b --read "New Thesis/CONVENTIONS.md" --no-show-model-warnings

```

Aider will instantly detect the environment injection string, route its payload queries out of the primary workspace container, hit the isolated inference container over `localhost`, and execute your local queries completely offline via hardware-accelerated processing.

---

## 🎓 Key Competencies Proven

This system layout explicitly demonstrates practical engineering skills across several technical domains:

* **DevOps & Infrastructure Isolation:** Moving away from fragile monolith architectures to robust, modular microservices.
* **Linux Container Networking:** Understanding container-to-container communication parameters, binding ports to localhost interfaces, and utilizing host bridge sharing (`--network=host`).
* **Linux Resource Optimization:** Tuning standard kernel limits (`--ulimit memlock=-1`) to prevent system memory leaks when running high-throughput deep learning and transformer-based tasks concurrently.

```

```

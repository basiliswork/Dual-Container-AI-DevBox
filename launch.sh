#!/bin/bash

echo "🚀 Starting local AI inference service..."
docker run -d --gpus all \
  -v /home/erebus/my_tf_projects/.ollama:/root/.ollama \
  -p 11434:11434 \
  --name ollama-service \
  ollama/ollama 2>/dev/null || docker start ollama-service

echo "⏱️ Waiting for GPU VRAM layers to initialize..."
sleep 5

echo "🐳 Launching custom TensorFlow workspace environment..."
docker run --gpus all -it --rm --ipc=host --network=host \
  --ulimit memlock=-1 --ulimit stack=67108864 \
  -p 5000:5000 -p 8888:8888 \
  -v /home/erebus/my_tf_projects:/workspace/my_project_container \
  -w /workspace/my_project_container \
  -e OLLAMA_API_BASE="http://127.0.0.1:11434" \
  --entrypoint /bin/sh my_custom_tf_env:latest \
  -c "jupyter lab --ip=0.0.0.0 --port=8888 --allow-root --no-browser --NotebookApp.token='' & exec /bin/bash"

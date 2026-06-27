#!/bin/bash

echo "🚀 Booting background AI inference engine..."
docker run -d --gpus all \
  -v /home/erebus/my_tf_projects/.ollama:/root/.ollama \
  -p 11434:11434 \
  --name ollama-service \
  ollama/ollama 2>/dev/null || docker start ollama-service

echo "⏱️ Waiting for Ollama API to be fully responsive..."
# This loops until Ollama responds with an HTTP 200 status code
until $(curl --output /dev/null --silent --head --fail http://127.0.0.1:11434); do
    printf '.'
    sleep 1
done
echo "✅ Ollama is online!"

echo "🐳 Launching custom TensorFlow workspace environment..."
docker run --gpus all -it --rm --ipc=host --network=host \
  --ulimit memlock=-1 --ulimit stack=67108864 \
  -p 5000:5000 -p 8888:8888 \
  -v /home/erebus/my_tf_projects:/workspace/my_project_container \
  -w /workspace/my_project_container \
  -e OLLAMA_API_BASE="http://127.0.0.1:11434" \
  --entrypoint /bin/sh my_custom_tf_env:latest \
  -c "jupyter lab --ip=0.0.0.0 --port=8888 --allow-root --no-browser --NotebookApp.token='' & exec /bin/bash"

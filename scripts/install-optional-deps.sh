#!/usr/bin/env bash
# Install large optional dependencies not baked into the Docker image.
# Run manually inside the container when needed. Safe to re-run.
set -euo pipefail

DOME_HOME="${DOME_HOME:-$HOME}"

# --- ML: torch + torchvision (required by dome_vision) ---
# ~1GB download
install_torch() {
  echo "Installing torch and torchvision (CPU-only, arm64)..."
  pip3 install --break-system-packages torch torchvision --index-url https://download.pytorch.org/whl/cpu
  echo "torch/torchvision done."
}

# --- TTS: piper binary + voice model (required by dome_voice speech output) ---
# Binary: ~50MB. Model: ~60MB (en_US-amy-medium).
# Set PIPER_BIN and PIPER_MODEL_PATH env vars before launching dome_voice.
install_piper() {
  local install_dir="${DOME_HOME}/.local/bin"
  local model_dir="${DOME_HOME}/.local/share/piper"
  mkdir -p "${install_dir}" "${model_dir}"

  if command -v piper >/dev/null 2>&1 || [[ -x "${install_dir}/piper" ]]; then
    echo "piper already installed, skipping binary."
  else
    echo "Downloading piper binary (arm64)..."
    local version="2023.11.14-2"
    local url="https://github.com/rhasspy/piper/releases/download/${version}/piper_linux_aarch64.tar.gz"
    curl -fsSL "${url}" | tar -xz -C "${install_dir}" --strip-components=1
    echo "piper binary installed to ${install_dir}/piper"
  fi

  local model_path="${model_dir}/en_US-amy-medium.onnx"
  if [[ -f "${model_path}" ]]; then
    echo "Voice model already present, skipping."
  else
    echo "Downloading en_US-amy-medium voice model..."
    local base="https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium"
    curl -fsSL "${base}/en_US-amy-medium.onnx" -o "${model_path}"
    curl -fsSL "${base}/en_US-amy-medium.onnx.json" -o "${model_path}.json"
    echo "Voice model installed to ${model_path}"
  fi

  echo ""
  echo "Add to your environment before launching dome_voice:"
  echo "  export PIPER_BIN=${install_dir}/piper"
  echo "  export PIPER_MODEL_PATH=${model_path}"
}

# Run both by default; pass 'torch' or 'piper' to install one only.
case "${1:-all}" in
  torch) install_torch ;;
  piper) install_piper ;;
  all)   install_torch; install_piper ;;
  *) echo "Usage: $0 [torch|piper|all]"; exit 1 ;;
esac

echo "Done."

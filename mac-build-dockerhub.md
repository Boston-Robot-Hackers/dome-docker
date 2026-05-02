# Build On Mac, Pull On Raspberry Pi

This is the preferred path when the Docker image is expensive to build on the
Raspberry Pi. Build the `linux/arm64` image on a Mac, push it to Docker Hub,
then pull and run it on the Pi.

The image is split into two layers:

- `DOME_BASE_IMAGE`: generic ROS Kilted base image with shared apt/ROS
  dependencies. This can be public and reused by anyone.
- `DOME_IMAGE`: robot-specific overlay image with configured source repos built
  into the workspace.

## 1. Configure The Image Name

On the Mac:

```sh
cd ~/mydev/dome-docker
cp dome-config.example.sh dome-config.sh
nano dome-config.sh
```

Set `DOME_IMAGE` to your Docker Hub repository:

```sh
export DOME_BASE_IMAGE="docker.io/YOUR_DOCKERHUB_USERNAME/dome-base:kilted"
export DOME_IMAGE="docker.io/YOUR_DOCKERHUB_USERNAME/dome-docker:dome-kilted"
```

If your Docker build clones private repositories, make sure your Mac SSH agent
has a GitHub key loaded:

```sh
ssh -T git@github.com
ssh-add -l
```

## 2. Build And Push The Generic Base

```sh
docker login
source ./dome-config.sh

./mac-build-base.sh
```

Push the base again only when `Dockerfile.base` or the common package list
changes.

## 3. Build And Push The Overlay

```sh
source ./dome-config.sh

./mac-build-overlay.sh
```

Equivalent manual command:

```sh
DOCKER_BUILDKIT=1 docker buildx build \
  --platform linux/arm64 \
  --ssh default=$SSH_AUTH_SOCK \
  --push \
  --build-arg "DOME_BASE_IMAGE=$DOME_BASE_IMAGE" \
  -t "$DOME_IMAGE" .
```

The image must be readable by the Pi. For a private Docker Hub repository, log
in on the Pi before pulling.

## 4. Pull And Run On The Pi

On the Pi:

```sh
cd ~/dome-docker
cp dome-config.example.sh dome-config.sh
nano dome-config.sh
source ./dome-config.sh
```

Use the same `DOME_IMAGE` value that you pushed from the Mac:

```sh
export DOME_BASE_IMAGE="docker.io/YOUR_DOCKERHUB_USERNAME/dome-base:kilted"
export DOME_IMAGE="docker.io/YOUR_DOCKERHUB_USERNAME/dome-docker:dome-kilted"
```

If the Docker Hub repository is private:

```sh
docker login
```

Pull and run:

```sh
docker compose pull dome
docker compose run --rm --no-build dome
```

This avoids a local Docker build on the Pi. The Pi still needs host setup:

```sh
sudo --preserve-env=DOME_HOST_USER,DOME_HOST_PASSWORD ./host-setup.sh
sudo reboot
```

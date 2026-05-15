# Build On Mac, Pull On Raspberry Pi

**This is the preferred workflow.** Build the `linux/arm64` image on a Mac
(fast), push to Docker Hub, pull and run on the Pi (seconds). Avoid building
on the Pi during active development.

The image is split into two layers:

- `DOME_BASE_IMAGE`: ROS base image with apt/ROS packages from
  `manifest/packages.txt`. Rebuild only when packages change. Can be public.
- `DOME_IMAGE`: overlay image with robot repos cloned and built. Rebuild for
  every code/repo change.

## 1. Configure

On the Mac:

```sh
cd ~/mydev/dome-docker
cp dome-config.example.sh dome-config.sh
nano dome-config.sh
```

Set `DOME_IMAGE` to your Docker Hub repository:

```sh
export DOME_BASE_IMAGE="docker.io/YOUR_DOCKERHUB_USERNAME/dome-base"
export DOME_IMAGE="docker.io/YOUR_DOCKERHUB_USERNAME/dome-docker"
```

Image tags are derived from `manifest/config.txt` automatically. Make sure your
Mac SSH agent has a GitHub key loaded (needed for private repo clones):

```sh
ssh -T git@github.com
ssh-add -l
```

If no key is loaded:

```sh
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

## 2. Build And Push The Base

Do this once, then only when `manifest/packages.txt` changes:

```sh
docker login
source ./dome-config.sh
./mac-build-base.sh
```

## 3. Build And Push The Overlay

Do this for every code or repo change:

```sh
source ./dome-config.sh
./mac-build-overlay.sh
```

## 4. Pull And Run On The Pi

On the Pi, set the same `DOME_IMAGE` value in `dome-config.sh`, then:

```sh
source ./dome-config.sh
docker compose pull dome
docker compose run --rm --no-build dome
```

If the Docker Hub repository is private, log in first:

```sh
docker login
```

The Pi still needs host setup run once before pulling:

```sh
sudo --preserve-env=DOME_USER,DOME_PASSWORD ./host-setup.sh
sudo reboot
```

## Turnaround Cycle

```
edit manifest/repos.txt or robot code
→ ./mac-build-overlay.sh          # on Mac
→ docker compose pull dome         # on Pi
→ docker compose run --rm --no-build dome
```

Only run `./mac-build-base.sh` again if `manifest/packages.txt` changes.

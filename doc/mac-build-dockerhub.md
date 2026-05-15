# Build On Mac, Pull On Raspberry Pi

**This is the preferred workflow.** Build the `linux/arm64` image on a Mac
(fast), push to Docker Hub, pull and run on the Pi (seconds). Avoid building
on the Pi during active development.

The image is split into two layers:

- `DOME_BASE_IMAGE`: ROS base image with apt/ROS packages from
  `manifest/packages.txt`. Rebuild only when packages change. Can be public.
- `DOME_IMAGE`: overlay image with robot repos cloned and built. Rebuild for
  every code/repo change.

## Prerequisites

- **Docker Desktop** installed and running on the Mac. Download from [docs.docker.com/desktop/mac/install](https://docs.docker.com/desktop/mac/install/). After install, open it and wait for the whale icon to appear in the menu bar.
- **Docker Hub account** (free) at [hub.docker.com](https://hub.docker.com). Your username appears top-right after login (e.g. `pitosalas`).

## 1. Configure

Edit `manifest/user.txt` — no shell scripting needed:

```sh
nano manifest/user.txt
```

Set your values:

```
DOCKERHUB_USERNAME=pitosalas
DOME_USER=pitosalas
```

`DOME_USER` is the Linux username created on the Pi host and inside the Docker image.

For the password, set it as an environment variable before building (keeps it out of committed files):

```sh
export DOME_PASSWORD=yourpassword
```

> **Note:** The password is baked into the Docker image and may appear in build logs. Do not commit real passwords to a public repo.

Then on the Mac:

```sh
cd ~/mydev/dome-docker
source ./dome-config.sh
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

Make sure Docker Desktop is running (`open -a Docker`) — you'll get a "cannot connect to Docker daemon" error if it's not.

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

**Pi must be set up first.** If you haven't done this yet, follow `microsd-card-build.md` steps 1–7 (flash Ubuntu, SSH in, clone repo, run host setup, reboot). Step 7 installs Docker on the Pi. Then come back here.

On the Pi, create `manifest/user.txt` — it is gitignored and won't exist after cloning, so create it with the same values as on the Mac:

```sh
nano manifest/user.txt
```

Add these lines:

```
DOCKERHUB_USERNAME=pitosalas
DOME_USER=pitosalas
```

Then:

```sh
source ./dome-config.sh
```

If the Docker Hub repository is private, log in first:

```sh
docker login
```

Then pull and run:

```sh
docker compose pull dome
docker compose run --rm --no-build dome
```

## Turnaround Cycle

```
edit manifest/repos.txt or robot code
→ ./mac-build-overlay.sh          # on Mac
→ docker compose pull dome         # on Pi
→ docker compose run --rm --no-build dome
```

Only run `./mac-build-base.sh` again if `manifest/packages.txt` changes.

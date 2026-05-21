set dotenv-load
# set dotenv-required

app := "numaflow"
tag := "latest"
user := "informeti"
host := "ghcr.io"
image-base := "ghcr.io/" + user + "/" + app
image := "ghcr.io/" + user + "/" + app + ":" + tag

build:
	podman build -t "{{image}}" .

login:
	echo -n "$GITHUB_TOKEN" | podman login --username {{user}} --password-stdin {{host}}

push:
	podman push {{image}}
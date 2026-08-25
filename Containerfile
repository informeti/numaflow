ARG UPSTREAM_IMAGE=quay.io/numaproj/numaflow:latest


FROM node:20-alpine AS build-ui

WORKDIR /src/ui
COPY ui/package.json ui/yarn.lock ./
RUN yarn install --frozen-lockfile
COPY ui/ .
RUN NODE_OPTIONS="--max-old-space-size=2048" JOBS=max yarn build


FROM golang:1.25-alpine AS build-go

WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
ARG TARGETARCH
ARG VERSION=latest
ARG BUILD_DATE=1970-01-01T00:00:00Z
ARG GIT_COMMIT
ARG GIT_TAG
ARG GIT_TREE_STATE=clean
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} go build \
	-ldflags "-X github.com/numaproj/numaflow.version=${VERSION} \
	-X github.com/numaproj/numaflow.buildDate=${BUILD_DATE} \
	-X github.com/numaproj/numaflow.gitCommit=${GIT_COMMIT} \
	-X github.com/numaproj/numaflow.gitTag=${GIT_TAG} \
	-X github.com/numaproj/numaflow.gitTreeState=${GIT_TREE_STATE}" \
	-o /bin/numaflow ./cmd


FROM ${UPSTREAM_IMAGE} AS pull-rust


FROM alpine:3.23 AS runtime

RUN apk add --no-cache ca-certificates tzdata
COPY --from=build-go /bin/numaflow /bin/numaflow
COPY --from=pull-rust /bin/numaflow-rs /bin/numaflow-rs
COPY --from=pull-rust /bin/entrypoint /bin/entrypoint
COPY --from=build-ui /src/ui/build /ui/build

ENTRYPOINT ["/bin/entrypoint"]

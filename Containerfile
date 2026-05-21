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
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /bin/numaflow ./cmd


FROM quay.io/numaproj/numaflow:latest AS pull-rust


FROM alpine:3.23 AS runtime

RUN apk add --no-cache ca-certificates tzdata
COPY --from=build-go /bin/numaflow /bin/numaflow
COPY --from=pull-rust /bin/numaflow-rs /bin/numaflow-rs
COPY --from=pull-rust /bin/entrypoint /bin/entrypoint
COPY --from=build-ui /src/ui/build /ui/build

ENTRYPOINT ["/bin/entrypoint"]
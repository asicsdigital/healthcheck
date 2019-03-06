# https://docs.docker.com/develop/develop-images/multistage-build/
FROM golang:1.10
WORKDIR /go/src/github.com/asicsdigital/healthcheck
COPY . .
RUN go get -d -v ./...
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .
RUN CGO_ENABLED=0 GOOS=linux go get -v github.com/asicsdigital/dudewheresmy

# Download and verify the integrity of the download first
FROM sethvargo/hashicorp-installer:0.1.3 AS installer
ARG CONSUL_VERSION='1.4.0'
ARG VAULT_VERSION='1.0.2'
RUN /install-hashicorp-tool "vault" "$VAULT_VERSION"

FROM hashicorp/envconsul:alpine
RUN apk --no-cache add ca-certificates bind-tools
WORKDIR /root/
COPY --from=0 /go/src/github.com/asicsdigital/healthcheck/app .
RUN mkdir -p static
COPY --from=0 /go/src/github.com/asicsdigital/healthcheck/static ./static
COPY --from=0 /go/bin/dudewheresmy .
COPY --from=installer /software/vault /usr/local/bin/vault

ENV PORT=8080
ENV CONSUL_PREFIX=healthcheck
ENV CONSUL_HTTP_ADDR=""
ENV CONSUL_HTTP_AUTH=""
ENV EXTRA_ARGS=""
ENV HONEYCOMB_API_KEY=""
ENV HONEYCOMB_DATASET="healthcheck"
ENV VAULT_ADDR=""
ENV VAULT_TOKEN=""
ENV VAULT_PATH="secret/healthcheck"

EXPOSE $PORT
COPY ./scripts/envconsul_wrapper.sh wrapper.sh
CMD ["./wrapper.sh"]

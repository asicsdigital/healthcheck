# https://docs.docker.com/develop/develop-images/multistage-build/
FROM golang:1.10
WORKDIR /go/src/github.com/asicsdigital/healthcheck
COPY . .
RUN go get -d -v ./...
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .
RUN CGO_ENABLED=0 GOOS=linux go get -v github.com/asicsdigital/dudewheresmy

FROM hashicorp/envconsul:alpine
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=0 /go/src/github.com/asicsdigital/healthcheck/app .
RUN mkdir -p static
COPY --from=0 /go/src/github.com/asicsdigital/healthcheck/static ./static
COPY --from=0 /go/bin/dudewheresmy .

ENV PORT=8080
ENV CONSUL_PREFIX=healthcheck
ENV CONSUL_HTTP_ADDR=""
ENV CONSUL_HTTP_AUTH=""
ENV EXTRA_ARGS=""
ENV HONEYCOMB_API_KEY=""
ENV HONEYCOMB_DATASET="healthcheck"

EXPOSE $PORT
COPY ./scripts/envconsul_wrapper.sh wrapper.sh
CMD ["./wrapper.sh"]

# Healthcheck Reference Implementation

A dedicated healthcheck endpoint is a crucial component of making any web service operable.  This repo contains a reference implementation of ASICS Digital's standard healthcheck endpoint; the intended audience consists of application developers (who can refer to this implementation when building their own healthchecks) and infrastructure engineers (who can refer to this implementation when building tools that consume healthcheck results).

A healthcheck endpoint has the following qualities:

* It is accessed via a static URI path which is not used for any other application functionality.  
  **Good**: `https://app.example.com/health-check`  
  **Bad**: `https://app.example.com/login`  
* It responds to a HTTP GET request.  
  **Good**: `GET https://app.example.com/health-check`  
  **Bad**: `POST https://app.example.com/status?action=healthcheck`  
* It does not require any authentication information.  
  **Good**: `curl https://app.example.com/health-check`  
  **Bad**: `curl -H 'Authorization: ablablablabla' https://app.example.com/health-check`  
  **Worse**: `curl -u 'sooper:seekrit' https://app.example.com/health-check`  
  **OMG STOPPP**: `curl -H 'X-MyFancyPantsToken: ablablablabla' https://app.example.com/health-check`
* It returns HTTP response code 200 to indicate a healthy service; any other response code indicates an unhealthy service.  
  **Good**: `GET https://app.example.com/health-check` -> `HTTP/1.1 200 OK`  
  **Sideeye**: `GET https://app.example.com/health-check` -> `HTTP/1.1 401 Not Authorized`  
  **NOOOOOOOO**: `GET https://app.example.com/health-check` -> `HTTP/1.1 200 OK` (in the body: `Status: Unhealthy`)
* It returns a body consisting solely of JSON-encoded text (with Content-Type `application/json`) that validates against the JSONschema included in this repository.  
  **Good**: `GET https://app.example.com/health-check` -> `{"application":"my_app","status":200,"metrics":"{}"}`  
  **Unacceptable**: `GET https://app.example.com/health-check` -> `<?xml version="1.0" encoding="UTF-8"?><healthcheck><oh>noes</oh></healthcheck>`  
  **SRSLY WTF**: `GET https://app.example.com/health-check` -> `<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"><html><head><title>oh noes</title></head><body><p>OOPSY WOOPSY</p></body></html>`

## The purpose of a healthcheck

FIXME

## Using this reference implementation

There are several ways to start up this reference implementation for testing or experimentation.  The application reads some runtime configuration values from its environment; these values control the information returned by the healthcheck endpoint.

### Our publically-hosted endpoint

```sh
$ curl https://healthcheck.staging.asics.digital/healthcheck | jq .
```

To change the values, access the us-east-1 staging Consul cluster at https://asics-services.us-east-1.staging.asics.digital and modify the entries under `healthcheck/` in the key/value store.  Changes will be reflected in the endpoint immediately.

### Local Docker

In one shell:

```sh
$ docker pull asicsdigital/healthcheck:latest
$ docker run --rm -it \
  -p 8080:8080 \
  -e CONSUL_HTTP_ADDR="https://asics-services.us-east-1.staging.asics.digital" \
  -e CONSUL_HTTP_AUTH="consul:GET_THIS_FROM_1PASSWORD" \
  asicsdigital/healthcheck:latest
```

In another shell:

```sh
curl http://localhost:8080/healthcheck | jq .
```

You can also pass in a VAULT_TOKEN and a VAULT_ADDR to this example to read secrets from Vault.

( Someone will have had to have run `vault write secret/healthcheck HONEYCOMB_API_KEY=<KEY` at some point, check your vault )

```sh
docker run --rm -it \
  -p 8080:8080 \
  -e CONSUL_HTTP_ADDR="https://asics-services.us-east-1.staging.asics.digital" \
  -e CONSUL_HTTP_AUTH="consul:GET_THIS_FROM_1PASSWORD" \
  -e VAULT_ADDR="https://vault.us-east-1.staging.asics.digital" \
  -e VAULT_TOKEN='<A VAULT TOKEN>' \
  asicsdigital/healthcheck:latest
```

### Build from source

If you want to entirely avoid the dependency on Consul, build the application from source.  You'll need a Golang development environment installed locally.

In one shell:

```sh
$ go get github.com/asicsdigital/healthcheck
$ cd ~/go/src/github.com/asicsdigital/healthcheck
$ go build
$ HEALTHCHECK_APP=my_app HEALTHCHECK_STATUS=500 HEALTHCHECK_METRICS='{"everything":"terrible"}' ./healthcheck
```

In another shell:

```sh
curl http://localhost:8080/healthcheck | jq .
```

## The promised JSONschema

After following the above instructions:

```sh
curl http://localhost:8080/schema.json
```

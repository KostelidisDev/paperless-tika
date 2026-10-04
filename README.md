# paperless-tika

An [Apache Tika](https://tika.apache.org/) server image for [Paperless-ngx](https://docs.paperless-ngx.com/), with Greek OCR support.

It is based on `apache/tika:4.1.0-full`, with two changes:

- Adds the Tesseract Greek language data (`tesseract-ocr-ell`).
- Sets Tika's OCR language to `ell+eng` (Greek and English), so text in images embedded in Office documents and emails is recognised in both languages.

Images are published for `linux/amd64` and `linux/arm64`.

## Usage with Paperless-ngx

Add the Tika service to your `docker-compose.yml`, next to Gotenberg, and point Paperless at both:

```yaml
services:
  webserver:
    image: ghcr.io/paperless-ngx/paperless-ngx:latest
    # ...
    depends_on:
      - tika
      - gotenberg
    environment:
      PAPERLESS_TIKA_ENABLED: 1
      PAPERLESS_TIKA_ENDPOINT: http://tika:9998
      PAPERLESS_TIKA_GOTENBERG_ENDPOINT: http://gotenberg:3000

  tika:
    image: ghcr.io/kostelidisdev/paperless-tika:latest
    restart: unless-stopped

  gotenberg:
    image: docker.io/gotenberg/gotenberg:8
    restart: unless-stopped
    command:
      - "gotenberg"
      - "--chromium-disable-javascript=true"
      - "--chromium-allow-list=file:///tmp/.*"
```

This only covers Tika. For Greek OCR of scanned PDFs and images that Paperless handles itself, also set `PAPERLESS_OCR_LANGUAGE: ell+eng` (and `PAPERLESS_OCR_LANGUAGES: ell` if your Paperless image doesn't already include it).

## Image tags

| Tag | Example | Moves? | Built when |
| --- | --- | --- | --- |
| `latest`, `main` | `latest` | Yes | Every push to `main` |
| `X.Y.Z` | `1.2.3` | No | A `vX.Y.Z` git tag is pushed |
| `X.Y` | `1.2` | Yes | A `vX.Y.Z` git tag is pushed |
| `sha-<short sha>` | `sha-1a2b3c4` | No | Every push to `main` or a tag |
| `YYYYMMDD` | `20261004` | No | Weekly scheduled rebuild (Sundays, 00:00 UTC) |

The weekly rebuild picks up security updates from the base image and Debian packages. For production, pin an immutable tag (`X.Y.Z`, `sha-…` or a dated tag) rather than `latest`.

## Configuration

The server is configured by [`tika-config.json`](tika-config.json), copied into the image at `/tika-config.json`. To use a different OCR language, change `language` there (any language whose Tesseract data is installed, joined with `+`) and add the matching `tesseract-ocr-<lang>` package in the [`Dockerfile`](Dockerfile).

You can also override the config at runtime without rebuilding:

```yaml
  tika:
    image: ghcr.io/kostelidisdev/paperless-tika:latest
    volumes:
      - ./tika-config.json:/tika-config.json:ro
```

## Building locally

```sh
docker build -t paperless-tika .
docker run --rm -p 9998:9998 paperless-tika
```

Check that it works:

```sh
curl -T some-document.docx http://localhost:9998/tika --header "Accept: text/plain"
```

## CI

[`.github/workflows/docker-publish.yml`](.github/workflows/docker-publish.yml) builds each architecture on a native runner, then merges them into a single multi-arch image on `ghcr.io`. Pull requests are built but not pushed.

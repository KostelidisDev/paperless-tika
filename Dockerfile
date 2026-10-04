# syntax=docker/dockerfile:1

FROM apache/tika:4.1.0-full

USER root
# Greek OCR data for images embedded in Office/email documents.
# Cache mounts keep apt's downloads out of the image and speed up rebuilds.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
 && apt-get update \
 && apt-get install --yes --no-install-recommends tesseract-ocr-ell

COPY tika-config.json /tika-config.json

# Back to the image's own unprivileged user.
USER 35002:35002
CMD ["--config", "/tika-config.json"]
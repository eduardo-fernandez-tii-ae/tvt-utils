# README #

## Docker image build instruction

Docker image must be built from the Dockerfile script path:

```
cd toolchain && docker build -t <docker-registry-path>/<image-name>:<image-tag> .
```

where:

1. `<docker-registry-path>`: the path to the Docker registry.
2. `<image-name>`: the name of the new Docker image.
3. `<image-tag>`: the tag of the new Docker image.

## Example

```
cd toolchain && docker build -t repo.private.crypto.tii.ae/docker-public/binsec/toolchain:v1.0.0 .
```
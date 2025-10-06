FROM alpine:3.22.1 as base
RUN apk add git automake autoconf gcc make bash gpg gpg-agent curl patch musl-dev

FROM base
ARG version
RUN if ! echo "$version" | grep -Eq '^[0-9]{2}$'; then \
        echo 'ERROR: $version must be exactly two digits (e.g., 01, 10, 99)' >&2; \
        exit 1; \
    fi

WORKDIR /work
COPY . .
RUN if [ ! -f "./version-${version}.sh" ]; then \
      echo "ERROR: Missing file ./version-${version}.sh in build context, is the version supported?" >&2; \
      exit 1; \
    fi

RUN sed -i s/ftp.gnu.org/mirror.ossplanet.net/g build.sh
RUN sed -i 's|--enable-silent-rules|--enable-static-link --enable-strict-posix-default --enable-readline --enable-history --enable-job-control --enable-multibyte --enable-bang-history --enable-coprocesses|g' build.sh
RUN ./build.sh "$version" "$(uname -m)"
# major=$(echo "$version" | cut -c1)
# minor=$(echo "$version" | cut -c2)

RUN mkdir -p /output
RUN cp ./releases/bash-$(echo "$version" | cut -c1).$(echo "$version" | cut -c2)-static /output/bash

RUN if ! ldd /output/bash 2>&1 | grep -q "not a dynamic executable"; then \
      echo "Error: /output/bash is dynamically linked" >&2; \
      exit 1; \
    fi


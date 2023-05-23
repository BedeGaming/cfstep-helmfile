ARG HELM_VERSION

FROM codefresh/cfstep-helm:${HELM_VERSION}

ARG HELM_VERSION
ARG HELMFILE_VERSION
ARG HELM_DIFF_VERSION
ARG HELM_SECRETS_VERSION
ARG PYTHON_VERSION

# Install required Alpine packages
RUN apk add --update \
    linux-headers \
    git \
    gcc \
    build-base \
    libc-dev \
    musl-dev \
    libffi-dev \
    openssl-dev \
    zlib-dev

# Download and extract Python 3.8.10 source
RUN wget https://www.python.org/ftp/python/3.8.10/Python-3.8.10.tgz \
    && tar -xvf Python-3.8.10.tgz \
    && rm Python-3.8.10.tgz

# Build and install Python 3.8.10
RUN cd Python-3.8.10 \
    && ./configure --enable-optimizations \
    && make -j$(nproc) \
    && make altinstall

# Cleanup
RUN rm -rf Python-3.8.10

# Install python libraries
RUN python3.8 -m pip install --upgrade pip \
    && python3.8 -m pip install ruamel.yaml \
    && python3.8 -m pip install azure-cli

# Install helmfile plugin deps
RUN helm plugin uninstall diff
RUN helm plugin install https://github.com/databus23/helm-diff --version ${HELM_DIFF_VERSION}
RUN helm plugin install https://github.com/futuresimple/helm-secrets --version ${HELM_SECRETS_VERSION}
# I have no idea why but that is need otherwise
# diff and secrets plugin don't work
RUN rm -rf /root/.helm/helm/plugins/https-github.com-databus23-helm-diff /root/.helm/helm/plugins/https-github.com-futuresimple-helm-secrets

# Install helmfile
ADD https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_amd64.tar.gz /tmp/helmfile.tar.gz
RUN tar xzf /tmp/helmfile.tar.gz -C /tmp && \
    mv /tmp/helmfile /bin/helmfile && \
    rm -rf /tmp/helmfile.tar.gz

# Set permissions for helmfile binary
RUN chmod 0755 /bin/helmfile

LABEL helm="${HELM_VERSION}"
LABEL helmfile="${HELMFILE_VERSION}"
LABEL helmdiff="${HELM_DIFF_VERSION}"

COPY lib/helmfile.py /helmfile.py

ENTRYPOINT ["python3", "/helmfile.py"]

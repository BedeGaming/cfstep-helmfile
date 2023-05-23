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
    python3-dev \
    libffi-dev && \
    rm -rf /var/cache/apk/*

# Install Python 3.8.10
RUN apk add --no-cache python3=3.8.10-r0 python3-dev=3.8.10-r0 py3-pip=20.3.4-r1

# Install helmfile plugin deps
RUN helm plugin uninstall diff
RUN helm plugin install https://github.com/databus23/helm-diff --version ${HELM_DIFF_VERSION}
RUN helm plugin install https://github.com/futuresimple/helm-secrets --version ${HELM_SECRETS_VERSION}
# I have no idea why but that is need otherwise
# diff and secrets plugin don't work
RUN rm -rf /root/.helm/helm/plugins/https-github.com-databus23-helm-diff /root/.helm/helm/plugins/https-github.com-futuresimple-helm-secrets

# Install Python libraries
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install ruamel.yaml
RUN python3 -m pip install azure-cli

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

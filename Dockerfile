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
    python3 \
    libffi-dev && \
    rm -rf /var/cache/apk/*

# Install helmfile plugin deps
RUN helm plugin uninstall diff
RUN helm plugin install https://github.com/databus23/helm-diff --version ${HELM_DIFF_VERSION}
RUN helm plugin install https://github.com/futuresimple/helm-secrets --version ${HELM_SECRETS_VERSION}
# I have no idea why but that is need otherwise
# diff and secrets plugin don't work
RUN rm -rf /root/.helm/helm/plugins/https-github.com-databus23-helm-diff /root/.helm/helm/plugins/https-github.com-futuresimple-helm-secrets

# Install python library
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install ruamel.yaml==0.17.21
RUN python3 -m pip install azure-cli

# Install curl && msal
RUN apk --no-cache add curl jq base64
RUN pip install msal requests --no-cache-dir

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
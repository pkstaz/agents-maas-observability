FROM registry.access.redhat.com/ubi9/nodejs-22:latest

ENV HOME=/tmp
ENV PATH=/opt/app/bin:$PATH

WORKDIR /opt/app

USER root
RUN dnf install -y curl tar gzip && dnf clean all
USER 1001

RUN npm install opencode-ai@latest --no-audit --no-fund \
    && mkdir -p /opt/app/bin \
    && curl -Ls https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz \
       | tar -xz -C /opt/app/bin oc kubectl \
    && ./node_modules/.bin/opencode --version \
    && /opt/app/bin/oc version --client

EXPOSE 4096

CMD ["/opt/app/node_modules/.bin/opencode", "serve", "--hostname", "0.0.0.0", "--port", "4096", "--cors", "https://app.opencode.ai"]

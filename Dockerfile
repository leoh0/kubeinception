FROM alpine:3.11

WORKDIR /kube

RUN apk --update --no-cache add docker

RUN wget https://github.com/kubernetes-sigs/kind/releases/download/v0.6.1/kind-linux-amd64 && \
    install kind-linux-amd64 /bin/kind

RUN wget https://storage.googleapis.com/kubernetes-release/release/v1.16.2/bin/linux/amd64/kubectl && \
    install kubectl /bin/kubectl

COPY run.sh .
COPY create-kind.yaml .

CMD [ "/kube/run.sh" ]

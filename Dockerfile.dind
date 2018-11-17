FROM golang:1.10 AS builder

LABEL maintainer "Yusuke KUOKA <ykuoka@gmail.com>"

RUN go get -u github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login

RUN ls /go/bin/docker-credential-ecr-login

FROM docker:1.12.6-dind AS runner

LABEL maintainer "Yusuke KUOKA <ykuoka@gmail.com>"

COPY --from=builder /go/bin/docker-credential-ecr-login /usr/bin/docker-credential/ecr/login

ADD dot.docker.config.json /root/.docker/config.json

ENTRYPOINT ["dockerd-entrypoint.sh"]

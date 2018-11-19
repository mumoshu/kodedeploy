# TODO Try to use one of supported linux distro
# Ref https://docs.aws.amazon.com/codedeploy/latest/userguide/codedeploy-agent.html#codedeploy-agent-supported-operating-systems
#FROM ruby:2.4
FROM ubuntu:16.04 AS builder

LABEL maintainer "Yusuke KUOKA <ykuoka@gmail.com>"

ENV VERSION=0.1.0

RUN \
  apt-get update -y && \
  apt-get install -y \
  ruby-dev ruby-bundler patch \
  git wget make gcc

RUN \
   wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64 && \
   chmod +x /usr/local/bin/dumb-init

ADD codedeploy-agent.rb.patch /codedeploy-agent.rb.patch

# Built from the git repo because the offical gem has no release since 2016.
# See https://rubygems.org/gems/aws-codedeploy-agent/versions/0.1.0 for confirmation
RUN \
  git clone https://github.com/aws/aws-codedeploy-agent.git && \
  gem install bundler && \
  cd aws-codedeploy-agent && \
  bundle install && \
  rake clean && \
  rake && \
  patch -u /aws-codedeploy-agent/lib/codedeploy-agent.rb -i /codedeploy-agent.rb.patch && \
  gem build codedeploy_agent-1.1.0.gemspec

RUN apt-get install -y curl

RUN \
  curl -L https://download.docker.com/linux/static/stable/x86_64/docker-18.06.1-ce.tgz | tar zxv && \
  find docker

FROM golang:1.11 AS cloudwatch-logger

RUN go get -u github.com/zendesk/cloudwatch-logger

RUN bash -c 'cloudwatch-logger; code=$?; if [ $code -ne 1 ]; then echo unexpected code: $code 1>&2; exit 1; fi'

FROM ubuntu:16.04 AS runner

LABEL maintainer "Yusuke KUOKA <ykuoka@gmail.com>"

ENV VERSION=0.1.0

COPY --from=builder /aws-codedeploy-agent/aws_codedeploy_agent-0.1.gem /
COPY --from=builder /aws-codedeploy-agent/conf/codedeployagent.yml /opt/codedeploy-agent/conf/codedeployagent.yml
COPY --from=builder /usr/local/bin/dumb-init /usr/bin/dumb-init
COPY --from=builder /docker/docker /usr/bin/docker

RUN \
  apt-get update -y && \
  apt-get install -y \
  ruby

ENV GEMS_DIR /var/lib/gems/2.3.0/gems

#  cp /aws-codedeploy-agent/conf/codedeployagent.yml /opt/codedeploy-agent/conf/ && \

RUN \
  ( gem install aws_codedeploy_agent-0.1.gem; \
  find / | grep codedeploy && \
  ruby $GEMS_DIR/aws_codedeploy_agent-0.1/lib/codedeploy-agent.rb --help ) && \
  mkdir -p /opt/codedeploy-agent/conf/ && \
  echo "the default config (/opt/codedeploy-agent/conf/codedeployagent.yml) contains: " && \
  cat /opt/codedeploy-agent/conf/codedeployagent.yml && \
  mkdir -p /etc/codedeploy-agent/conf/

COPY --from=builder /aws-codedeploy-agent/certs/host-agent-deployment-signer-ca-chain.pem $GEMS_DIR/aws_codedeploy_agent-0.1/certs/host-agent-deployment-signer-ca-chain.pem

COPY --from=cloudwatch-logger /go/bin/cloudwatch-logger /usr/bin/cloudwatch-logger

# Instead of running:
#   aws deploy install --override-config --config-file ONPREM_CONFIG
# The onprem config file can be installed to:
#   /etc/codedeploy-agent/conf/codedeploy.onpremises.yml
# According to the aws-cli source:
#   https://github.com/aws/aws-cli/blob/4ff0cbacbac69a21d4dd701921fe0759cf7852ed/awscli/customizations/codedeploy/systems.py

#RUN gem install aws-codedeploy-agent --version ${VERSION} --no-format-exec

COPY bin/entrypoint.sh /entrypoint.sh

WORKDIR /tmp

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD [ "/entrypoint.sh" ]

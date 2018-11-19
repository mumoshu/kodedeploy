FROM amazonlinux:2

LABEL maintainer "Yusuke KUOKA <ykuoka@gmail.com>"

RUN yum update -y && yum install -y wget && yum clean all

RUN \
   wget --progress=dot:giga -O /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64 && \
   chmod +x /usr/bin/dumb-init

RUN \
  wget --progress=dot:giga -O amazon-cloudwatch-agent.rpm https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm && \
  rpm -U ./amazon-cloudwatch-agent.rpm && \
  rpm -qlp ./amazon-cloudwatch-agent.rpm && \
  rm amazon-cloudwatch-agent.rpm

ENV PATH $PATH:/opt/aws/amazon-cloudwatch-agent/bin

RUN bash -c 'amazon-cloudwatch-agent --help; code=$?; if [ $code -ne 2 ]; then echo unexpected code: $code; exit 1; fi'

COPY bin/entrypoint-cloud-watch-agent.sh /entrypoint.sh

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD [ "/entrypoint.sh" ]

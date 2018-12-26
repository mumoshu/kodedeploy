#!/usr/bin/env bash

set -vxe

input=/etc/aws/amazon-cloudwatch-agent/config.json

conf=/opt/aws/amazon-cloudwatch-agent/etc
toml="${conf}/config.toml"
common="${conf}/common-config.toml"

cat $input
cat $common

# or "ec2"
CLOUDWATCH_AGENT_MODE=${CLOUDWATCH_AGENT_MODE:-onPrem}

echo 'Running config-traslator with the mode '"$CLOUDWATCH_AGENT_MODE"'. Set the CLOUDWATCH_AGENT_MODE to either "ec2" or "onPrem" to override.'

config-translator --mode "${CLOUDWATCH_AGENT_MODE}" --input "${input}" --output "${toml}" --config "${common}"

amazon-cloudwatch-agent -config "${toml}"

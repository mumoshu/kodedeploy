#!/usr/bin/env bash

set -e

ruby /var/lib/gems/2.3.0/gems/aws_codedeploy_agent-0.1/lib/codedeploy-agent.rb start --foreground

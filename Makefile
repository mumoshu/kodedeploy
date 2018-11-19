build:
	docker build . -t mumoshu/aws-codedeploy-agent:canary

push:
	docker push mumoshu/aws-codedeploy-agent:canary

run:
	docker run --rm -it -v $(shell pwd)/etc-codedeploy-agent-conf:/etc/codedeploy-agent/conf  mumoshu/aws-codedeploy-agent:canary

deploy:
	hack/deploy

.PHONY: build/dind
build/dind:
	docker build -f Dockerfile.dind -t mumoshu/aws-codedeploy-agent:dind-canary .

.PHONY: push/dind
push/dind:
	docker push mumoshu/aws-codedeploy-agent:dind-canary

.PHONY: build/cloudwatch-agent
build/cloudwatch-agent:
	docker build -f Dockerfile.cloudwatch-agent -t mumoshu/aws-codedeploy-agent:cloudwatch-agent-canary .

.PHONY: push/cloudwatch-agent
push/cloudwatch-agent:
	docker push mumoshu/aws-codedeploy-agent:cloudwatch-agent-canary

build:
	docker build . -t mumoshu/aws-codedeploy-agent:canary

push:
	docker push mumoshu/aws-codedeploy-agent:canary

run:
	docker run --rm -it -v $(shell pwd)/etc-codedeploy-agent-conf:/etc/codedeploy-agent/conf  mumoshu/aws-codedeploy-agent:canary

deploy:
	hack/deploy

# KodeDeploy

Continuous deployment of your application on Kubernetes. It is continuous that all the Kubernetes applications will be automatically redeployed, whenever you create new Kubernetes clusters.

## Goal

As an infrastructure engineer and/or a ClusterOps person, whenever you (re)create new clusters and namespaces, all you need to do is install an AWS CodeDeploy agent per a Kubernetes namespace.

CodeDeploy takes care of the rest, fetfching the desired state of the namespace, automatically deploying everything, for you.

This is especially helpful in the two use-cases below:

- Delegate continuous (re)deployment of apps to your product teams
- Easy Kubernetes cluster migration

### Delegate continuous (re)deployment of apps to your product teams

You don't need to remember which namespace contains which Kubernetes resources!

Aa a ClusterOps person, whenever a new project starts, you just create a dedicated Kubernetes namespace, installing a CodeDeploy agent. Finally give IAM role accesses for all the developers in the project team, and you're done.

Any developers in the project team, as long as they're allowed by AWS IAM policies, can deploy your Kubernetes applications with CodeDeploy from anywhere.

### Easy Kubernetes cluster migration

KodeDeploy allows you to easily to a kind of canary deployments of Kubernetes clusters. Run multiple flavors of Kubernetes clusters for smooth migration without headache of (re)deploying apps.

Usually doing things like this requires you to repeat `kubectl` or `helm` or something similar per Kubernetes cluster when you have multiple of them.

With KodeDeploy, all you need is installing CodeDeploy agents. Each agent knows which revision of your apps should be installed in a namespace, so that it can deploy it for you.

One standard use-case of KodeDeploy is easing Kubernetes version upgrades in your production environment. Vary the version number of Kubernetes across clusters, like `v1.10.7` or `v.1.11.3`, connecting to the same Target Group, tweaking sizes Auto Scaling Groups of your Kubernetes nodes across clustesr to for load-balancing across clusters.

## How it works

If you're familiar with AWS, I'd say that it works much like Launch Configuration, for Kubernetes clusters.

Your launch configuration might have been automatically creating identical EC2 instances for you according to `userdata`. KodeDeploy, on the other hand, redeploys every k8s app needed for your k8s cluster.

With KodeDeploy, all you need to do for recreating your Kubernetes cluster becomes just two steps. The first step is provisioning a "raw" cluster with a tool like eksctl, kops, or kube-aws. The second and the final step is deploying `KodeDeploy`, providing `Environment Name` like `production` and `Namespace` like `my-accounting-product` or `my-analytics-platform`, onto your cluster. KodeDeploy remembers which k8s apps is needed for the cluster in e.g. the `my-analytics-platform` namespace within the `production` environment, so that it can deploy everything for you.

KodeDeploy, as you might have guessed from its name, exploits AWS CodeDeploy for Kubernetes.

## Getting Started

### Installing agents

```console
aws deploy register \
  --instance-name ${instance_name} \
  --tags Key=kodedeployenv,Value=production Key=kodedeploycluster,Value=examplecom Key=kodedeployns,Value=my-analytics-platform \
  --region us-west-2
```

The `instance_name` should be `${env}-${cluster}-${ns}` whereas each component is:

- `kodedeployenv`: the name of the environment your cluster is in e.g. `production`, `staging`, `preview`
- `kodedeploycluster`: the name of the cluster like `examplecom`, `internalonly`
- `kodedeployns`: the namespace like `my-accounting-product`, `my-analytics-platform`

The `aws deploy register` command produces `codedeploy.onpremises.yml` that looks like:

```
---
region: ap-northeast-1
iam_user_arn: arn:aws:iam::YOUR_AWS_ACCOUNT:user/AWS/CodeDeploy/YOUR_INSTANCE_NAME
aws_access_key_id: YOUR_AUTO_GENERATED_KEY_ID
aws_secret_access_key: YOUR_AUTO_GENERATED_SECRET_KEY
```

Place this into `somedir/codedeploy.onpremises.yml` and run:

```console
kubectl --namespace ${kodedeployns} \
  create secret generic --from-file=somedir etc-codedeploy-agent-conf
```

Create a `anotherdir/codedeployagent.yml` that looks like:

```yaml
---
:log_aws_wire: false
:log_dir: '/var/log/aws/codedeploy-agent/'
:pid_dir: '/opt/codedeploy-agent/state/.pid/'
:program_name: codedeploy-agent
:root_dir: '/opt/codedeploy-agent/deployment-root'
:verbose: false
:wait_between_runs: 1
:proxy_uri:
:max_revisions: 5
```

and run:

```console
kubectl --namespace ${kodedeployns} \
  create configmap --from-file=anotherdir opt-codedeploy-agent-conf
```

finally install the codedeploy agent onto your ns by running:

```console
kubectl --namespace ${kodedeployns} \
  create -f deploy.yaml
```

And repeat these steps for each `kodedeployns` within your cluster in the environment.

### Author `appspec.yml`

`appspec.yml` is a kind of your deployment script that is run by CodeDeploy agents.

Being locked-in to Kubernetes for this specific use-case, we have less things to do here compared to traditinoal `appspec.yml` files.

Suppose you have all the files required to deploy your app onto Kubernetes under `./myapp`, always start with a `appspec.yml` like the below:

```yaml
version: 0.0
os: linux
files:
  - source: deploy
    destination: /deploy
hooks:
  AfterInstall:
  - location: codedeploy/after-install.sh
    timeout: 180
```

Whereas the `after-install.sh` looks like:

```yaml
#!/usr/bin/env bash

set -vx

wd="/opt/codedeploy-agent/deployment-root/${DEPLOYMENT_GROUP_ID}/${DEPLOYMENT_ID}/deployment-archive"
image="quay.io/roboll/helmfile:v0.40.1"
cmd="helmfile apply"

docker run -v "${wd}:${wd}" --rm "${image}" -w "${wd}" bash -c "${cmd}"
```

Edit the above `appspec.yml` to use whatever `image` and `cmd` you like, so that any tool that speaks to Kubernetes can be integrated with AWS CodeDeploy.

In case you'd want to understand how this works, `DEPLOYMENT_GROUP_ID` is a variable provided by CodeDeploy, containing the ID of the deployment group in which the current deployment is.

### Deploying revisions

Run the following command to create a revision from your local source, and then deploy it:

```console
aws deploy push \
  --application-name ${app} \
  --description "${myrev}" \
  --ignore-hidden-files \
  --s3-location s3://${bucket}/${key} \
  --source ${source}
```

```console
aws deploy create-deployment \
  --application-name ${app} \
  --deployment-config-name CodeDeployDefault.OneAtATime \
  --deployment-group-name ${group} \
  --s3-location bucket=${bucket},key=${key},bundleType=${bundletype}
```

I'd suggest the following naming conventions for the variables:

`app`: the name of one microservice within your namespace. Note that each namespace could contain one more more microservices.

`env`: the name of the environnment which the agent is intended to manage e.g. `production`, `staging`, `test`, `preview`.

`ns`: the name of the Kubernetes namespace which the agent is intended to manage, recommended to be either your team's name or product name.

`group`: `${env}-${ns}`

Now Wait for a few seconds to see the agent deploys your Kubernetes resources.

The codedeploy agent in your namespace detects the newly created AWS CodeDeploy `revision`, runs commands provided in the AWS CodeDeploy `appspec.yml` included in the source.

Now that the latest `revision` is memorized by AWS CodeDeploy, every newly installed agent automatically fetches the latest revision for installing.

See `example/push` to see how you could automate the most of these steps and conventions for you.

## Integrations

### Helmfile

Have one desired-state file for your whole namespace, that is applied automatically

- Write your desired state file called `helmfile.yaml` per namespace using [roboll/helmfile](https://github.com/roboll/helmfile)
- Modify your AWS CodeDeploy `appspec.yml` to call the `helmfile apply` command

### GitHub

See the progresses of your deplyoments in GitHub pull requests.

- Create a GitHub Webhook endopoint, with [aws-lambda-go-api-proxy](https://github.com/awslabs/aws-lambda-go-api-proxy), that reacts to `GitHub Deployment` events by creating corresponding CodeDeploy deployments.

- Use [remind101/deploy](https://github.com/remind101/deploy) to trigger `GitHub Deployment`s

### Slack

Trigger deployments via Slack.

- Use [remind101/slashdeploy](https://github.com/remind101/slashdeploy) so that you can say `/deploy` in your Slack channel to trigger `GitHub Deployment`s, which then triggers CodeDeploy deployments via the lambda function created in the above `GitHub` section

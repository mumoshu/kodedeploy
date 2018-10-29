# KodeDeploy

Continuous deployment of your application on Kubernetes. It is continuous that your every application will be automatically redeployed whenever you create new Kubernetes clusters.

## Goal

You don't need to remember anymore about which namespace contains which Kubernetes resources!

Whenever you (re)create new clusters and namespaces, all you need to do is install AWS CodeDeploy agents as a single-pod Kubernetes deployment, per a Kubernetes namespace.

CodeDeploy takes care of the rest.

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

`group`: `${env}-${nv}`

Now Wait for a few seconds to see the agent deploys your Kubernetes resources.

The codedeploy agent in your namespace detects the newly created AWS CodeDeploy `revision`, runs commands provided in the AWS CodeDeploy `appspec.yml` included in the source.

Now that the latest `revision` is memorized by AWS CodeDeploy, every newly installed agent automatically fetches the latest revision for installing.

See `example/push` to see how you could automate the most of these steps and conventions for you.

## Integrations

### GitHub

See the progresses of your deplyoments in GitHub pull requests.

- Create a GitHub Webhook endopoint, with [aws-lambda-go-api-proxy](https://github.com/awslabs/aws-lambda-go-api-proxy), that reacts to `GitHub Deployment` events by creating corresponding CodeDeploy deployments.

- Use [remind101/deploy](https://github.com/remind101/deploy) to trigger `GitHub Deployment`s

### Slack

Trigger deployments via Slack.

- Use [remind101/slashdeploy](https://github.com/remind101/slashdeploy) so that you can say `/deploy` in your Slack channel to trigger `GitHub Deployment`s, which then triggers CodeDeploy deployments via the lambda function created in the above `GitHub` section

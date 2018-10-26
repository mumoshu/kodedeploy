# KodeDeploy

Continuous deployment of your application on Kubernetes. It is continuous that your every application will be automatically redeployed whenever you create new Kubernetes clusters.

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
example/push
```

The codedeploy agent in your namespace detects the newly created revision, runs commands provided in the `appspec.yml` included in the source.

Now that the latest revision is memorized by AWS CodeDeploy, every newly installed agent automatically fetches the latest revision for installing.

You don't need to remember which namespace contains what anymore! All you need to do is install agents whenever you (re)create new clusters and namespaces. CodeDeploy takes care of the rest.

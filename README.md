# KodeDeploy

Continuous deployment of your application on Kubernetes. It is continuous that your every application will be automatically redeployed whenever you create new Kubernetes clusters.

If you're familiar with AWS, I'd say that it works much like Launch Configuration, for Kubernetes clusters.

Your launch configuration might have been automatically creating identical EC2 instances for you according to `userdata`. KodeDeploy, on the other hand, redeploys every k8s app needed for your k8s cluster.

With KodeDeploy, all you need to do for recreating your Kubernetes cluster becomes just two steps. The first step is provisioning a "raw" cluster with a tool like eksctl, kops, or kube-aws. The second and the final step is deploying `KodeDeploy`, providing `Environment Name` like `production` and `Namespace` like `my-accounting-product` or `my-analytics-platform`, onto your cluster. KodeDeploy remembers which k8s apps is needed for the cluster in e.g. the `my-analytics-platform` namespace within the `production` environment, so that it can deploy everything for you.

KodeDeploy, as you might have guessed from its name, exploits AWS CodeDeploy for Kubernetes.

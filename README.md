
# EKS + Rancher: Manage Kubernetes Clusters in the Cloud and Locally

This guide walks you through provisioning an **Amazon EKS cluster using Terraform**, installing **Rancher** on that cluster, and optionally managing other clusters like **k3d** using the Rancher UI.

---

## Overview

| Tool         | Platform       | Purpose                                                             |
|--------------|----------------|---------------------------------------------------------------------|
| Terraform    | CLI / GitHub   | Infrastructure as Code for provisioning EKS                         |
| AWS EKS      | Cloud (AWS)    | Managed Kubernetes Cluster                                          |
| Rancher      | Kubernetes     | Centralized Kubernetes Cluster Management (web UI)                  |
| k3d          | Local (Docker) | Lightweight Kubernetes clusters in Docker, ideal for local testing |

---

## Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform installed
- Docker Desktop installed (for k3d)
- `kubectl` and `helm` installed
- An IAM user or role with sufficient permissions to manage EKS resources

---

## Directory Structure

```
.
├── cluster-setup/
│   └── eks-cluster/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
```

---

## Step 1: Provision the EKS Cluster via Terraform

Navigate to the EKS Terraform project:

```bash
cd cluster-setup/eks-cluster
```

Initialize and apply:

```bash
terraform init
terraform apply
```

This will provision the VPC, subnets, IAM roles, EKS cluster, and node groups.

After success, update your `kubeconfig`:

```bash
aws eks update-kubeconfig --region us-east-1 --name <your-cluster-name>
```

Verify:

```bash
kubectl get nodes
```

---

## Step 2: Install Rancher on EKS

Install cert-manager:

```bash
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/latest/download/cert-manager.crds.yaml

helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager   --namespace cert-manager --create-namespace --wait
```

Install Rancher using Helm:

```bash
helm repo add rancher https://releases.rancher.com/server-charts/stable
helm repo update

export RANCHER_HOSTNAME=<your-domain>.nip.io
export EMAIL=your-email@example.com

helm install rancher rancher/rancher   --namespace cattle-system   --create-namespace   --set hostname=$RANCHER_HOSTNAME   --set ingress.tls.source=letsEncrypt   --set letsEncrypt.email=$EMAIL   --wait
```

Install Load Balancer Controller via Helm

```
helm repo add eks https://aws.github.io/eks-charts
helm repo update

kubectl create namespace kube-system

helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  --set clusterName=<your-cluster-name> \
  --set serviceAccount.create=false \
  --set region=<your-region> \
  --set vpcId=<your-vpc-id> \
  --set serviceAccount.name=aws-load-balancer-controller \
  -n kube-system
```

Get Rancher Public Address on EKS

- Check Rancher Service Type:
```
kubectl get svc rancher -n cattle-system
```
- Copy the EXTERNAL-IP or DNS Name
```
EXTERNAL-IP = a1b2c3d4.us-east-1.elb.amazonaws.com
```
- You can then access Rancher at:
```
https://a1b2c3d4.us-east-1.elb.amazonaws.com
```

Optional
- If you used a hostname like:
```
--set hostname=rancher.<your-domain>.nip.io
```
- Then, go to:
```
https://rancher.<your-domain>.nip.io
```
- Or, if using the IP:
```
https://<external-ip>.nip.io
```


---

## Step 3: Run Rancher Locally on `k3d`

Create a lightweight cluster:

```bash
k3d cluster create rancher-cluster   --servers 1 --agents 1   --port "80:80@loadbalancer" --port "443:443@loadbalancer"
```

Install Rancher using the same Helm commands above (adjust the hostname to `rancher.127.0.0.1.nip.io`).

Access locally:

```bash
https://rancher.127.0.0.1.nip.io
```

---

## Step 4: Import Clusters into Rancher

From Rancher UI:

1. Go to Cluster Management → Import Existing
2. Choose Generic and copy the `kubectl apply -f ...` command
3. Run the command on the relevant cluster (`eks`, `k3d`, etc.)

Example:

```bash
kubectl config use-context <k3d-cluster-name>
kubectl apply -f https://<rancher-url>/v3/import/<token>.yaml
```

---

## Cleanup

### Delete EKS Infrastructure

```bash
cd cluster-setup/eks-cluster
terraform destroy
```

### Delete k3d Cluster

```bash
k3d cluster delete rancher-cluster
```

### Remove Local Rancher Docker

```bash
docker rm -f rancher
```

---

## References

- https://rancher.com/docs/
- https://github.com/terraform-aws-modules/terraform-aws-eks
- https://k3d.io

---

## <div align="center">About the Author</div>

<div align="center">
  <img src="assets/emmanuel-naweji.jpg" alt="Emmanuel Naweji" width="120" height="120" style="border-radius: 50%;" />
</div>

**Emmanuel Naweji** is a seasoned Cloud and DevOps Engineer with years of experience helping companies architect and deploy secure, scalable infrastructure. He is the founder of initiatives that train and mentor individuals seeking careers in IT and has helped hundreds transition into Cloud, DevOps, and Infrastructure roles.

- Book a free consultation: [https://here4you.setmore.com](https://here4you.setmore.com)
- Connect on LinkedIn: [https://www.linkedin.com/in/ready2assist/](https://www.linkedin.com/in/ready2assist/)

> Let's connect and discuss how I can help you build reliable, automated infrastructure the right way.

#!/bin/bash
# ==========================================
# Script: Rancher on EKS (Terraform + Helm)
# Author: Emmanuel Naweji (T2S)
# ==========================================

set -e

### USER INPUT ###
CLUSTER_NAME="t2s-rancher-cluster"
REGION="us-east-1"
EMAIL="info@transformed2succeed.com"
HOSTNAME="rancher"

### Step 1: Create IRSA for AWS Load Balancer Controller using Terraform ###
cat <<EOF > irsa-alb.tf
provider "aws" {
  region = "$REGION"
}

module "eks_irsa_alb" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AWSLoadBalancerControllerRole-${CLUSTER_NAME}"
  provider_url                  = data.aws_eks_cluster.cluster.identity[0].oidc.issuer
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]

  role_policy_arns = [
    aws_iam_policy.lb_controller.arn
  ]
}

data "aws_eks_cluster" "cluster" {
  name = "$CLUSTER_NAME"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "$CLUSTER_NAME"
}

resource "aws_iam_policy" "lb_controller" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("aws-lb-controller-policy.json")
}
EOF

### Step 2: Download official policy JSON for ALB controller
curl -o aws-lb-controller-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

### Step 3: Apply Terraform IRSA config
terraform init && terraform apply -auto-approve

### Step 4: Create Kubernetes Service Account manually (to bind to IRSA role)
ROLE_ARN=$(terraform output -raw eks_irsa_alb_iam_role_arn)

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: ${ROLE_ARN}
EOF

### Step 5: Install AWS Load Balancer Controller with Helm ###
helm repo add eks https://aws.github.io/eks-charts
helm repo update

VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION \
  --query "cluster.resourcesVpcConfig.vpcId" --output text)

helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set region=$REGION \
  --set vpcId=$VPC_ID \
  --set serviceAccount.name=aws-load-balancer-controller \
  --wait

### Step 6: Install cert-manager ###
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/latest/download/cert-manager.crds.yaml

helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --wait

### Step 7: Install Rancher ###
helm repo add rancher https://releases.rancher.com/server-charts/stable
helm repo update

# Get Load Balancer DNS from Rancher service
LOAD_BALANCER_DNS=$(kubectl get svc -n kube-system | grep aws-load-balancer | awk '{print $4}')
RANCHER_HOSTNAME="$HOSTNAME.$LOAD_BALANCER_DNS.nip.io"

helm install rancher rancher/rancher \
  --namespace cattle-system \
  --create-namespace \
  --set hostname=$RANCHER_HOSTNAME \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=$EMAIL \
  --wait

### Step 8: Output Rancher URL ###
echo "✅ Rancher is now available at: https://$RANCHER_HOSTNAME"
kubectl get svc -n cattle-system

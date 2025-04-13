# Rancher-Based Deployment of emmanuel-services

This project shows how to set up Rancher on a K3s cluster and deploy the `emmanuel-services` Helm app using GitHub Actions for GitOps.

## Structure

- `manifests/namespace.yaml`: Namespace manifest for isolating the app.
- `rancher-setup/install-rancher.sh`: Script to install Rancher on a local K3s cluster.
- `.github/workflows/deploy.yml`: GitHub Actions pipeline to auto-deploy Helm chart.

## How to Use

1. Run `install-rancher.sh` to install Rancher.
2. Set up your GitHub repo and add your `KUBECONFIG` as a secret.
3. Push your Helm chart into `helm/emmanuel-services/`.
4. On push to `main`, GitHub Actions will deploy your app to the cluster.

--- 

## <div align="center">About the Author</div>

<div align="center">
  <img src="assets/emmanuel-naweji.jpg" alt="Emmanuel Naweji" width="120" height="120" style="border-radius: 50%;" />
</div>

**Emmanuel Naweji** is a seasoned Cloud and DevOps Engineer with years of experience helping companies architect and deploy secure, scalable infrastructure. He is the founder of initiatives that train and mentor individuals seeking careers in IT and has helped hundreds transition into Cloud, DevOps, and Infrastructure roles.

- Book a free consultation: [https://here4you.setmore.com](https://here4you.setmore.com)
- Connect on LinkedIn: [https://www.linkedin.com/in/ready2assist/](https://www.linkedin.com/in/ready2assist/)

Let's connect and discuss how I can help you build reliable, automated infrastructure the right way.


——

MIT License © 2025 Emmanuel Naweji

You are free to use, copy, modify, merge, publish, distribute, sublicense, or sell copies of this software and its associated documentation files (the “Software”), provided that the copyright and permission notice appears in all copies or substantial portions of the Software.

This Software is provided “as is,” without any warranty — express or implied — including but not limited to merchantability, fitness for a particular purpose, or non-infringement. In no event will the authors be liable for any claim, damages, or other liability arising from the use of the Software.

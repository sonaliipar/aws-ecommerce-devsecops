# AWS E-Commerce DevSecOps

A portfolio-ready reference implementation for building, scanning, packaging, and deploying a Java Spring Boot e-commerce API to Amazon EKS.

## Architecture
Developer → GitHub → Jenkins (Maven tests → SonarQube → Veracode policy scan → Docker build → Trivy scan → ECR) → Helm → EKS → ALB/Ingress → Spring Boot → RDS PostgreSQL. Prometheus/Grafana and CloudWatch provide observability.

## Repository layout
- `app/` — Spring Boot sample REST API
- `Jenkinsfile` — CI/CD stages with security gates
- `docker/` — non-root container image
- `helm/ecommerce/` — Helm chart
- `k8s/` — example Kubernetes resources
- `terraform/` — VPC, EKS, ECR, RDS, IAM and supporting AWS resources
- `ansible/` — Jenkins host bootstrap example
- `monitoring/` — Prometheus scrape config and alert examples

## Prerequisites
AWS account with permissions to create VPC/EKS/ECR/RDS/IAM resources, Terraform >= 1.6, AWS CLI v2, kubectl, Helm >= 3, Docker, Java 17, Maven, Jenkins, SonarQube and (optionally) Veracode credentials.

> Cost and security: EKS, NAT gateways, ALB and RDS can incur ongoing charges. This is a learning/reference project, not a turnkey production deployment. Review Terraform, set budgets, use a sandbox account, and destroy resources when finished. Never commit credentials or terraform state.

## Local app
```bash
cd app
mvn test
mvn spring-boot:run
curl http://localhost:8080/actuator/health
curl http://localhost:8080/api/products
```

## Infrastructure (review before applying)
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Set a globally unique S3 bucket name and review all variables.
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```
The Terraform config creates billable resources. It deliberately does not configure a public database. Keep RDS private. Add remote state with encryption, versioning, locking, and restricted access before team use.

## CI/CD setup
1. Create a GitHub repository and push this project.
2. Configure Jenkins credentials: `aws-credentials` (or use an EC2/EKS role), `sonar-token`, and optionally `veracode-api-id` / `veracode-api-key`.
3. Configure Jenkins tools for JDK 17 and Maven; install Pipeline, Git, Docker Pipeline, and SonarQube Scanner plugins.
4. Configure a SonarQube server named `sonarqube` in Jenkins.
5. Create a Jenkins Pipeline job from SCM and point it to `Jenkinsfile`.
6. Set job parameters/environment variables: `AWS_REGION`, `AWS_ACCOUNT_ID`, `ECR_REPOSITORY`, `EKS_CLUSTER_NAME`, `HELM_RELEASE`, `HELM_NAMESPACE`. Configure the Veracode stage only when credentials and an applicable policy are available.
7. Ensure the Jenkins agent has Docker, AWS CLI, kubectl and Helm installed, plus network access to AWS and scanners.

The pipeline fails on failed tests, SonarQube quality gate, or Trivy HIGH/CRITICAL findings. Veracode upload/policy checks require valid account configuration and are shown as an optional gated integration.

## Deployment
```bash
aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER_NAME"
helm upgrade --install ecommerce ./helm/ecommerce \
  --namespace ecommerce --create-namespace \
  --set image.repository="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY" \
  --set image.tag="$BUILD_NUMBER"
```
Configure the AWS Load Balancer Controller and an ACM certificate before enabling the ingress. Set database and application secrets via AWS Secrets Manager / External Secrets Operator; do not put secret values in Helm values.

## Resume note
Only claim services as deployed after you have applied the infrastructure, run the pipeline, verified the EKS rollout, and captured evidence. You can describe this repository as a reference implementation until then.

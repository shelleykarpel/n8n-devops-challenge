# Resilient & Cost-Optimized n8n Infrastructure

This project demonstrates a production-grade, self-healing deployment of **n8n** on AWS, managed entirely via **Terraform**.

---

## Architecture Overview

The infrastructure is designed for **high availability** and **persistence**, ensuring that the application can recover automatically from instance failures without data loss.

## System Diagram

```mermaid
flowchart TB

%% =========================
%% LAYERS
%% =========================

subgraph L0["Client"]
  U([User])
end

subgraph L1["Edge / Networking"]
  ALB[[Application Load Balancer]]
end

subgraph L2["Compute (Auto Scaling)"]
  subgraph ASG["Auto Scaling Group"]
    EC2[(n8n Instance - Spot)]
  end
end

subgraph L3["Data & Secrets"]
  RDS[(RDS PostgreSQL)]
  SM[[AWS Secrets Manager]]
end

subgraph L4["CI/CD"]
  GH[[GitHub Actions]]
  TF[[Terraform Plan & Validate]]
end

AWS[(AWS Account / Cloud)]

%% =========================
%% FLOWS
%% =========================

U -->|HTTP 80| ALB
ALB -->|App Port 5678| EC2

EC2 -->|Workflows + Executions| RDS
EC2 -->|DB creds + Encryption keys| SM

GH --> TF --> AWS

%% =========================
%% STYLES
%% =========================

classDef client fill:#E3F2FD,stroke:#1E88E5,stroke-width:2px,color:#0D47A1;
classDef edge fill:#F3E5F5,stroke:#8E24AA,stroke-width:2px,color:#4A148C;
classDef compute fill:#E8F5E9,stroke:#2E7D32,stroke-width:2px,color:#1B5E20;
classDef data fill:#FFF8E1,stroke:#FF8F00,stroke-width:2px,color:#E65100;
classDef cicd fill:#FCE4EC,stroke:#C2185B,stroke-width:2px,color:#880E4F;
classDef aws fill:#EEEEEE,stroke:#424242,stroke-width:2px,color:#212121;

class U client;
class ALB edge;
class EC2 compute;
class RDS,SM data;
class GH,TF cicd;
class AWS aws;

%% Make critical path stand out
linkStyle 0 stroke:#1E88E5,stroke-width:3px;
linkStyle 1 stroke:#8E24AA,stroke-width:3px;
linkStyle 2 stroke:#FF8F00,stroke-width:3px;
linkStyle 3 stroke:#FF8F00,stroke-width:3px;
linkStyle 4 stroke:#C2185B,stroke-width:3px;
linkStyle 5 stroke:#C2185B,stroke-width:3px;
```






## Key DevOps Principles Applied
### 1. Self-Healing & Resilience
The compute layer is managed by an Auto Scaling Group (ASG). If the instance fails, becomes unhealthy, or is terminated (even by AWS as a Spot interruption), a new instance is automatically provisioned and joined to the Load Balancer within minutes.

### 2. Zero-Local State (Persistence)
To ensure no data loss during instance termination:

Database: All workflows, executions, and user data are stored in an External AWS RDS (PostgreSQL).

Secrets: Database credentials and encryption keys are fetched at runtime from AWS Secrets Manager, ensuring the instance remains "disposable" and stateless.

### 3. Security-First Approach
Security Group Chaining: Implemented a strict "least privilege" network flow. The RDS only accepts traffic from the EC2 security group, and the EC2 only accepts traffic from the ALB.

IP Whitelisting: The Application Load Balancer is restricted to specific administrative IP ranges to prevent unauthorized access.

### 4. Cost Optimization
EC2 Spot Instances: Utilizes Spot market capacity to reduce compute costs by up to 90% compared to On-Demand instances.

Automated Cleanup: Terraform is used to ensure all resources can be destroyed (terraform destroy) cleanly when not in use.

## Tech Stack
Infrastructure as Code: Terraform

Cloud Provider: AWS (VPC, ALB, ASG, RDS, Secrets Manager)

Containerization: Docker

CI/CD: GitHub Actions (Automated terraform plan & validate)

Application: n8n (Workflow Automation)

## How to Test Resilience (The "Chaos" Test)
One of the core requirements was proving the system can recover from a "hard termination":

Access: Open the n8n dashboard via the ALB DNS URL.

State Creation: Create a user account and save a simple test workflow.

Termination: Go to the AWS EC2 Console and Terminate the running instance.

Recovery: Wait ~3 minutes for the ASG to detect the failure and launch a new Spot instance.

Verification: Refresh the URL. You will be able to log in with your original credentials, and your workflow will be intact.

## CI/CD Pipeline
The project includes a GitHub Actions workflow that:

Performs a terraform validate to ensure code quality.

Runs a terraform plan on every Push or Pull Request, providing visibility into infrastructure changes before they are applied.

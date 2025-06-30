# 📚 LMS Deployment on Alibaba Cloud ECS Using Terraform

## 🧾 What is an LMS?

A **Learning Management System (LMS)** is a platform for delivering, tracking, and managing educational content. This project provisions the backend infrastructure and deploys an LMS application (such as Moodle or a custom app) on Alibaba Cloud ECS, using a managed MySQL RDS instance.

---

## 🔧 What is Terraform?

Terraform is an open-source Infrastructure as Code (IaC) tool that enables the automated provisioning and management of cloud infrastructure using declarative `.tf` files.

---

## 🏗️ What Does This Project Deploy?

This project sets up the following components on Alibaba Cloud:

- ✅ VPC and VSwitch networking
- ✅ Security Group allowing SSH, HTTP, and MySQL
- ✅ MySQL RDS instance with a custom database and admin user
- ✅ ECS instance (Ubuntu) with a public IP
- ✅ LMS application deployed via the `setup.sh` script

---

## 🚀 Setup & Deployment

### 1. Clone the Repository

git clone https://github.com/your-org/Alibaba-LMS-Deployment.git
cd Alibaba-LMS-Deployment
---
---
## 2. Configure Terraform Variables

Edit `terraform.tfvars` and set your required variables:

project_name     = "demo-lms"
stage            = "stag"
vpc_cidr_block   = "192.168.0.0/16"
vswitch_cidr     = "192.168.1.0/24"
instance_type    = "ecs.g6.large"

common_tags = {
  environment = "stag"
  team        = "lms"
}


Ensure your Alibaba Cloud credentials are configured via environment variables or CLI config.

---

### 3. Initialize Terraform

terraform init

---

### 4. Plan the Infrastructure

terraform plan

---

### 5. Apply and Deploy LMS Automatically

terraform apply

Terraform will:

- Create VPC, VSwitch, and Security Groups  
- Provision an RDS MySQL instance with a database and admin user  
- Launch an ECS instance  
- Upload and run the `setup.sh` script to install and configure the LMS  

---

## ✅ Output

After deployment, Terraform will show:

- ECS Public IP  
- RDS Endpoint  
- RDS Username  
- RDS Password (sensitive)  
- SSH Username: root  
- LMS URL: http://<ecs-public-ip>

---

## 📌 LMS Installation Script (`setup.sh`)

The `setup.sh` script does the following:

- Installs necessary packages: Nginx, PHP, MySQL client, etc.  
- Downloads and configures LMS application (e.g., Moodle)  
- Connects to the RDS instance  
- Sets permissions and starts required services  

This script is executed automatically on the ECS instance by Terraform using a remote-exec provisioner.

---

## 🔐 Security Recommendations

- Replace default credentials with secure secrets or use a secret manager  
- Limit access to RDS and ECS using specific CIDR blocks  
- Set up HTTPS and configure a custom domain name (optional)  
- Regularly update the server and LMS software  
- Configure backups and monitoring for RDS  

---

## 🧩 Customization

You can customize:

- The LMS app and behavior inside `setup.sh`  
- ECS instance type or disk sizes  
- Database name, charset, and privileges  
- Resource tags for better lifecycle and cost tracking  

---

## 📄 License

MIT License (or specify your preferred license here)

#!/bin/bash

# Deploy script for Journaly Backend to ECS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-dev}
AWS_REGION=${AWS_REGION:-ap-northeast-1}

echo -e "${GREEN}Starting backend deployment for ${ENVIRONMENT} environment${NC}"

# Check if required tools are installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}AWS Account ID: ${AWS_ACCOUNT_ID}${NC}"

# Get ECR repository URL from Terraform output
echo -e "${YELLOW}Getting ECR repository URL from Terraform...${NC}"
cd ../terraform
ECR_REPO=$(terraform output -raw backend_ecr_repository_url 2>/dev/null || echo "")
ECS_CLUSTER=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
ECS_SERVICE=$(terraform output -raw ecs_service_name 2>/dev/null || echo "")
cd ../journaly-backend

if [ -z "$ECR_REPO" ]; then
    echo -e "${RED}Error: Could not get ECR repository URL from Terraform${NC}"
    exit 1
fi

echo -e "${GREEN}ECR Repository: ${ECR_REPO}${NC}"
echo -e "${GREEN}ECS Cluster: ${ECS_CLUSTER}${NC}"
echo -e "${GREEN}ECS Service: ${ECS_SERVICE}${NC}"

# Login to ECR
echo -e "${YELLOW}Logging in to ECR...${NC}"
aws ecr get-login-password --region "${AWS_REGION}" | \
    docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Build Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
docker build -t journaly-backend:latest .

# Tag image
echo -e "${YELLOW}Tagging Docker image...${NC}"
docker tag journaly-backend:latest "${ECR_REPO}:latest"
docker tag journaly-backend:latest "${ECR_REPO}:$(date +%Y%m%d-%H%M%S)"

# Push image to ECR
echo -e "${YELLOW}Pushing image to ECR...${NC}"
docker push "${ECR_REPO}:latest"
docker push "${ECR_REPO}:$(date +%Y%m%d-%H%M%S)"

echo -e "${GREEN}Docker image pushed successfully${NC}"

# Update ECS service
echo -e "${YELLOW}Updating ECS service...${NC}"
aws ecs update-service \
    --cluster "${ECS_CLUSTER}" \
    --service "${ECS_SERVICE}" \
    --force-new-deployment \
    --region "${AWS_REGION}" \
    > /dev/null

echo -e "${GREEN}ECS service update initiated${NC}"

# Wait for service to stabilize (optional)
echo -e "${YELLOW}Waiting for service to stabilize (this may take a few minutes)...${NC}"
aws ecs wait services-stable \
    --cluster "${ECS_CLUSTER}" \
    --services "${ECS_SERVICE}" \
    --region "${AWS_REGION}"

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}==================================================${NC}"

# Get ALB URL
cd ../terraform
ALB_URL=$(terraform output -raw alb_dns_name 2>/dev/null || echo "")
cd ../journaly-backend

if [ -n "$ALB_URL" ]; then
    echo -e "${GREEN}Backend API URL: http://${ALB_URL}${NC}"
    echo -e "${YELLOW}Test the health endpoint: curl http://${ALB_URL}/health${NC}"
fi

echo -e "${YELLOW}View logs: aws logs tail /ecs/journaly-${ENVIRONMENT}/backend --follow${NC}"

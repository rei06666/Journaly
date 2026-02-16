#!/bin/bash

# Deploy script for Journaly Frontend to S3 + CloudFront

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-dev}
AWS_REGION=${AWS_REGION:-ap-northeast-1}
S3_BUCKET="journaly-${ENVIRONMENT}-frontend"

echo -e "${GREEN}Starting frontend deployment for ${ENVIRONMENT} environment${NC}"

# Check if required tools are installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}Error: npm is not installed${NC}"
    exit 1
fi

# Get backend API URL from Terraform output
echo -e "${YELLOW}Getting backend API URL from Terraform...${NC}"
cd ../terraform
BACKEND_API_URL=$(terraform output -raw backend_api_url 2>/dev/null || echo "")
CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")
cd ../journaly-frontend

if [ -z "$BACKEND_API_URL" ]; then
    echo -e "${RED}Warning: Could not get backend API URL from Terraform. Using default.${NC}"
    NEXT_PUBLIC_API_URL="http://localhost:3001"
else
    NEXT_PUBLIC_API_URL="${BACKEND_API_URL}"
fi

echo -e "${GREEN}API URL: ${NEXT_PUBLIC_API_URL}${NC}"

# Set environment variable for build
export NEXT_PUBLIC_API_URL

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
npm ci

# Build the application
echo -e "${YELLOW}Building Next.js application...${NC}"
npm run build

# Check if out directory exists
if [ ! -d "out" ]; then
    echo -e "${RED}Error: Build output directory 'out' not found${NC}"
    exit 1
fi

# Sync to S3
echo -e "${YELLOW}Uploading to S3 bucket: ${S3_BUCKET}${NC}"
aws s3 sync out/ "s3://${S3_BUCKET}" \
    --delete \
    --region "${AWS_REGION}" \
    --cache-control "public, max-age=31536000, immutable" \
    --exclude "*.html" \
    --exclude "*.json"

# Upload HTML files with different cache settings
aws s3 sync out/ "s3://${S3_BUCKET}" \
    --region "${AWS_REGION}" \
    --cache-control "public, max-age=0, must-revalidate" \
    --exclude "*" \
    --include "*.html" \
    --include "*.json"

echo -e "${GREEN}Files uploaded to S3 successfully${NC}"

# Invalidate CloudFront cache
if [ -n "$CLOUDFRONT_ID" ]; then
    echo -e "${YELLOW}Invalidating CloudFront cache...${NC}"
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id "${CLOUDFRONT_ID}" \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text)
    
    echo -e "${GREEN}CloudFront invalidation created: ${INVALIDATION_ID}${NC}"
    echo -e "${YELLOW}Waiting for invalidation to complete (this may take a few minutes)...${NC}"
    
    aws cloudfront wait invalidation-completed \
        --distribution-id "${CLOUDFRONT_ID}" \
        --id "${INVALIDATION_ID}"
    
    echo -e "${GREEN}CloudFront cache invalidated successfully${NC}"
else
    echo -e "${YELLOW}Warning: CloudFront distribution ID not found. Skipping cache invalidation.${NC}"
fi

# Get CloudFront URL
cd ../terraform
CLOUDFRONT_URL=$(terraform output -raw cloudfront_domain_name 2>/dev/null || echo "")
cd ../journaly-frontend

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}==================================================${NC}"

if [ -n "$CLOUDFRONT_URL" ]; then
    echo -e "${GREEN}Frontend URL: https://${CLOUDFRONT_URL}${NC}"
fi

echo -e "${YELLOW}Note: Changes may take a few minutes to propagate globally${NC}"

#!/bin/bash

AWS_REGION=eu-west-1
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

DOCKER_IMAGE_TAG="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/boundary-worker:latest"
docker build --platform linux/x86_64 -t "${DOCKER_IMAGE_TAG}" .

docker push "${DOCKER_IMAGE_TAG}"
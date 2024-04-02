#!/bin/bash

aws ecr batch-delete-image \
    --repository-name boundary-worker \
    --image-ids imageTag=latest
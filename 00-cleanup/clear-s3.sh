#!/bin/bash

BUCKET="hug-boundary-session-recording"
aws s3 rm s3://$BUCKET/ --recursive
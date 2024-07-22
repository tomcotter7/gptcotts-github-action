#!/bin/bash


if [ -z "$AWS_S3_BUCKET" ]; then
  echo "AWS_S3_BUCKET is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "AWS_ACCESS_KEY_ID is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "AWS_SECRET_ACCESS_KEY is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_REGION" ]; then
  AWS_REGION="eu-north-1"
fi

aws configure set aws_access_key_id "${AWS_ACCESS_KEY_ID}" --profile s3-sync-action
aws configure set aws_secret_access_key "${AWS_SECRET_ACCESS_KEY}" --profile s3-sync-action
aws configure set region "${AWS_REGION}" --profile s3-sync-action

aws configure list --profile s3-sync-action

s3_url="s3://${AWS_S3_BUCKET}/${AWS_DIR}"

echo "Syncing to ${s3_url}"

aws s3 sync . ${s3_url} \
    --profile s3-sync-action \
    --exclude ".git/*" \
    --exclude ".github/*" \
    --delete

aws configure set aws_access_key_id null --profile s3-sync-action
aws configure set aws_secret_access_key null --profile s3-sync-action
aws configure set region null --profile s3-sync-action

echo "Sync complete"


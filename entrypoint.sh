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

echo "Sync to s3 complete"

echo "Syncing to pinecone"

PINECONE_API_KEY="6278a3cd-b5b9-4f7c-9aa9-018d9077f3f1"
PINECONE_INDEX="notes"
PINECONE_NAMESPACE="tcotts-notes"
COHERE_API_KEY="E6Co5OUVwzw0l0UfHYZoZ2JBUvbPkc1qseEdN0Rr"

if [ -z "$PINECONE_API_KEY" ]; then
  echo "PINECONE_API_KEY is not set. Quitting."
  exit 1
fi

if [ -z "$PINECONE_INDEX" ]; then
  echo "PINECONE_INDEX is not set. Quitting."
  exit 1
fi

if [ -z "$PINECONE_NAMESPACE" ]; then
  echo "PINECONE_NAMESPACE is not set. Quitting."
  exit 1
fi

if [ -z "$COHERE_API_KEY" ]; then
  echo "COHERE_API_KEY is not set. Quitting."
  exit 1
fi

git config --global --add safe.directory /github/workspace
files=$(git diff-tree --no-commit-id --name-only -r HEAD)


python3 /pinecone_sync.py \
  --api_key $PINECONE_API_KEY \
  --cohere_api_key $COHERE_API_KEY \
  --index $PINECONE_INDEX \
  --namespace $PINECONE_NAMESPACE \
  --changed_files $files


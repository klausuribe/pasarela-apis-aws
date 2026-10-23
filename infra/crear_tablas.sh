#!/bin/bash
set -e
REGION=us-east-1
for T in productos clientes; do
  aws dynamodb create-table --table-name $T \
    --attribute-definitions AttributeName=id,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST --region $REGION \
    --query 'TableDescription.TableStatus' --output text
done
aws dynamodb wait table-exists --table-name productos --region $REGION
aws dynamodb wait table-exists --table-name clientes --region $REGION
echo "Tablas listas"

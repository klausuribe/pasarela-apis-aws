#!/bin/bash
# Elimina TODOS los recursos del proyecto. Ejecutar solo al final,
# despues de tener capturas y video.
cd "$(dirname "$0")/.."
REGION=us-east-1
export AWS_DEFAULT_REGION=$REGION
[ -f .env ] && source .env

echo "== Eliminando API Gateway"
if [ -n "$API_ID" ]; then aws apigateway delete-rest-api --rest-api-id $API_ID || true; fi

echo "== Eliminando plan de uso y clave de API"
if [ -n "$PLAN_ID" ]; then
  [ -n "$KEY_ID" ] && aws apigateway delete-usage-plan-key --usage-plan-id $PLAN_ID --key-id $KEY_ID || true
  aws apigateway delete-usage-plan --usage-plan-id $PLAN_ID || true
fi
[ -n "$KEY_ID" ] && aws apigateway delete-api-key --api-key $KEY_ID || true

echo "== Eliminando Lambda"
aws lambda delete-function --function-name pasarela-api-fn || true

echo "== Eliminando grupo de logs"
aws logs delete-log-group --log-group-name /aws/lambda/pasarela-api-fn || true

echo "== Eliminando tablas DynamoDB"
aws dynamodb delete-table --table-name productos || true
aws dynamodb delete-table --table-name clientes || true

rm -f .env function.zip
echo ""
echo "Verificacion (cada lista debe estar vacia):"
aws apigateway get-rest-apis --query 'items[].name'
aws lambda list-functions --query 'Functions[].FunctionName'
aws dynamodb list-tables
date

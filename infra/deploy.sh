#!/bin/bash
set -e
export AWS_DEFAULT_REGION=us-east-1
REGION=us-east-1
FN=pasarela-api-fn
API_NAME=pasarela-api-urzacom
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
ROLE=arn:aws:iam::$ACCOUNT:role/LabRole
cd "$(dirname "$0")/.."

echo "== 1/5 Empaquetando Lambda"
(cd src && zip -q ../function.zip lambda_function.py)

echo "== 2/5 Creando Lambda con LabRole"
if aws lambda get-function --function-name $FN >/dev/null 2>&1; then
  aws lambda update-function-code --function-name $FN --zip-file fileb://function.zip >/dev/null
else
  aws lambda create-function --function-name $FN --runtime python3.12 \
    --handler lambda_function.handler --role $ROLE \
    --zip-file fileb://function.zip --timeout 10 --memory-size 128 >/dev/null
fi
aws lambda wait function-active-v2 --function-name $FN
FN_ARN=$(aws lambda get-function --function-name $FN --query Configuration.FunctionArn --output text)

echo "== 3/5 Creando API Gateway"
API_ID=$(aws apigateway create-rest-api --name $API_NAME \
  --endpoint-configuration types=REGIONAL --query id --output text)
ROOT=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[0].id' --output text)
URI=arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$FN_ARN/invocations

for R in productos clientes; do
  RID=$(aws apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT --path-part $R --query id --output text)
  IID=$(aws apigateway create-resource --rest-api-id $API_ID --parent-id $RID --path-part '{id}' --query id --output text)
  aws apigateway put-method --rest-api-id $API_ID --resource-id $IID --http-method GET \
    --authorization-type NONE --api-key-required >/dev/null
  aws apigateway put-integration --rest-api-id $API_ID --resource-id $IID --http-method GET \
    --type AWS_PROXY --integration-http-method POST --uri $URI >/dev/null
done

aws lambda add-permission --function-name $FN --statement-id apigw-$API_ID \
  --action lambda:InvokeFunction --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT:$API_ID/*/GET/*" >/dev/null

aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod >/dev/null

echo "== 4/5 Clave de API y plan de uso (1 solicitud/seg, rafaga 2)"
KEY_ID=$(aws apigateway create-api-key --name clave-pasarela --enabled --query id --output text)
PLAN_ID=$(aws apigateway create-usage-plan --name plan-basico \
  --throttle burstLimit=2,rateLimit=1 --quota limit=1000,period=DAY \
  --api-stages apiId=$API_ID,stage=prod --query id --output text)
aws apigateway create-usage-plan-key --usage-plan-id $PLAN_ID --key-id $KEY_ID --key-type API_KEY >/dev/null
API_KEY=$(aws apigateway get-api-key --api-key $KEY_ID --include-value --query value --output text)

echo "== 5/5 Exportando OpenAPI"
aws apigateway get-export --rest-api-id $API_ID --stage-name prod --export-type oas30 \
  --accepts application/json docs/openapi.json >/dev/null

cat > .env <<ENVEOF
API_ID=$API_ID
API_URL=https://$API_ID.execute-api.$REGION.amazonaws.com/prod
API_KEY=$API_KEY
KEY_ID=$KEY_ID
PLAN_ID=$PLAN_ID
ENVEOF

echo ""
echo "LISTO"
echo "URL: https://$API_ID.execute-api.$REGION.amazonaws.com/prod"

#!/bin/bash
cd "$(dirname "$0")/.."
source .env
echo "Fecha: $(date)  Region: us-east-1"
echo "URL: $API_URL"
t() { # nombre, ruta, usar_clave
  sleep 2  # pausa para no exceder el limite de 1 solicitud/seg del plan de uso
  if [ "$3" = "si" ]; then H="x-api-key: $API_KEY"; else H="x-no-key: 1"; fi
  echo; echo "--- $1  (GET $2)"
  curl -s -w "\nHTTP %{http_code}\n" -H "$H" "$API_URL$2"
}
t "1. Valida: producto existente" /productos/P001 si
t "2. Valida: cliente existente" /clientes/C003 si
t "3. Error: id con formato invalido (400)" /productos/XYZ si
t "4. Error: id inexistente (404)" /productos/P999 si
t "5. Error: sin clave de API (403)" /productos/P001 no
sleep 3; echo; echo "--- 6. Limite de solicitudes: 15 llamadas rapidas"
for i in $(seq 1 15); do
  curl -s -o /dev/null -w "%{http_code} " -H "x-api-key: $API_KEY" "$API_URL/productos/P001"
done; echo

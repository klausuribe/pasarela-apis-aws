import json
import re
import boto3
from decimal import Decimal

db = boto3.resource("dynamodb")

RECURSOS = {
    "productos": {"tabla": "productos", "patron": r"^P\d{3}$", "ejemplo": "P001"},
    "clientes": {"tabla": "clientes", "patron": r"^C\d{3}$", "ejemplo": "C001"},
}


def _num(o):
    if isinstance(o, Decimal):
        return int(o) if o == o.to_integral_value() else float(o)
    return str(o)


def respuesta(codigo, cuerpo):
    return {
        "statusCode": codigo,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(cuerpo, default=_num, ensure_ascii=False),
    }


def error(codigo, tipo, mensaje):
    return respuesta(codigo, {"error": {"codigo": codigo, "tipo": tipo, "mensaje": mensaje}})


def handler(event, context):
    recurso = (event.get("resource") or "").split("/")[1:2]
    recurso = recurso[0] if recurso else ""
    cfg = RECURSOS.get(recurso)
    if not cfg:
        return error(404, "RECURSO_NO_ENCONTRADO", "Ruta no soportada")

    item_id = (event.get("pathParameters") or {}).get("id", "")
    if not re.match(cfg["patron"], item_id):
        return error(400, "ID_INVALIDO",
                     f"El id '{item_id}' no es valido. Formato esperado, por ejemplo: {cfg['ejemplo']}")

    try:
        res = db.Table(cfg["tabla"]).get_item(Key={"id": item_id})
    except Exception as e:
        print("ERROR_DYNAMODB", str(e))
        return error(500, "ERROR_INTERNO", "No se pudo consultar la base de datos")

    item = res.get("Item")
    if not item:
        return error(404, "NO_ENCONTRADO", f"No existe {recurso[:-1]} con id {item_id}")

    print(json.dumps({"evento": "consulta_ok", "recurso": recurso, "id": item_id}))
    return respuesta(200, item)

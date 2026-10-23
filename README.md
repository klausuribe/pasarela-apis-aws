# Pasarela de APIs para una empresa (Reto 16)

Proyecto Final · Computación en la Nube · Universidad Católica Boliviana
Autor: Klaus Uribe Zabala · Región AWS: us-east-1 (N. Virginia)

## Descripción

Distintas aplicaciones de una distribuidora de lubricantes necesitan consultar productos y clientes con reglas consistentes. Esta pasarela publica y protege dos endpoints de consulta con validación de entradas, errores coherentes, clave de API, límite de solicitudes, documentación OpenAPI y logs de acceso.

| Endpoint | Descripción |
|---|---|
| `GET /productos/{id}` | Consulta un producto (ej. `P001`) |
| `GET /clientes/{id}` | Consulta un cliente (ej. `C001`) |

Todas las rutas exigen la cabecera `x-api-key`.

## Arquitectura

```
Cliente --(x-api-key)--> API Gateway --> Lambda (LabRole) --> DynamoDB
                          |  plan de uso                        (productos, clientes)
                          |  1 req/s, ráfaga 2, 1000/día
                          +--> CloudWatch Logs <-- Lambda
```

Diagrama: [`docs/arquitectura.png`](docs/arquitectura.png). Especificación OpenAPI exportada: `docs/openapi.json`.

| Servicio | Por qué se eligió | Alternativa descartada |
|---|---|---|
| API Gateway | Claves de API, planes de uso y límites nativos | API en EC2 con FastAPI (más operación manual) |
| Lambda | Sin servidores, pago por uso, usa LabRole | EC2 (hay que administrar el servidor) |
| DynamoDB | Consulta por clave, bajo demanda, sin administración | RDS (innecesario para búsquedas por id) |
| CloudWatch | Logs y métricas integrados con Lambda y API Gateway | Logging propio (más trabajo y menos confiable) |

## Requisitos

- Cuenta de AWS Academy Learner Lab con el laboratorio iniciado (región us-east-1).
- AWS CloudShell (ya trae AWS CLI, Python 3 y zip).
- Rol `LabRole` (el laboratorio no permite crear roles).

## Despliegue

Desde CloudShell, en la carpeta del repositorio:

```bash
git clone https://github.com/klausuribe/pasarela-apis-aws.git

# 1. Tablas de DynamoDB y datos sintéticos
bash infra/crear_tablas.sh
python3 infra/seed.py

# 2. Lambda, API Gateway, clave de API, plan de uso y OpenAPI
bash infra/deploy.sh
```

`deploy.sh` genera un archivo `.env` local con la URL y la clave de API. Ese archivo está en `.gitignore`: **nunca se sube al repositorio**.

## Prueba de aceptación

```bash
bash infra/pruebas.sh | tee evidencias/pruebas.txt
```

| # | Caso | Resultado esperado |
|---|---|---|
| 1 | Producto existente (`P001`) | 200 con JSON |
| 2 | Cliente existente (`C003`) | 200 con JSON |
| 3 | Id con formato inválido (`XYZ`) | 400 `ID_INVALIDO` |
| 4 | Id inexistente (`P999`) | 404 `NO_ENCONTRADO` |
| 5 | Sin clave de API | 403 `Forbidden` |
| 6 | 15 llamadas rápidas | Primeras 200, luego 429 (límite) |

Formato uniforme de error:

```json
{"error": {"codigo": 400, "tipo": "ID_INVALIDO", "mensaje": "..."}}
```

## Estructura

```
src/lambda_function.py   Código de la función
infra/                   Scripts de despliegue, pruebas y limpieza
docs/                    Diagrama de arquitectura y OpenAPI
evidencias/              Capturas y logs de la prueba
```

## Datos de prueba

Datos sintéticos (5 productos y 5 clientes, precios en bolivianos) generados por `infra/seed.py`.

## Limpieza

```bash
bash infra/cleanup.sh
```

Elimina API Gateway, clave y plan de uso, la Lambda y las tablas de DynamoDB.

## Seguridad

- Sin credenciales ni claves en el repositorio (`.env` ignorado).
- La Lambda usa `LabRole`; la política de recursos solo permite invocarla desde esta API (método GET).
- Acceso protegido por clave de API y plan de uso con límite de solicitudes.

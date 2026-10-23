import boto3
from decimal import Decimal

db = boto3.resource("dynamodb", region_name="us-east-1")

productos = [
    {"id": "P001", "nombre": "Aceite 20W50 1L", "categoria": "lubricantes", "precio_bs": Decimal("45"), "stock": 120},
    {"id": "P002", "nombre": "Aceite 15W40 Diesel 4L", "categoria": "lubricantes", "precio_bs": Decimal("210"), "stock": 60},
    {"id": "P003", "nombre": "Filtro de aceite universal", "categoria": "filtros", "precio_bs": Decimal("35"), "stock": 200},
    {"id": "P004", "nombre": "Grasa multiproposito 1kg", "categoria": "grasas", "precio_bs": Decimal("80"), "stock": 40},
    {"id": "P005", "nombre": "Liquido de frenos DOT4", "categoria": "fluidos", "precio_bs": Decimal("30"), "stock": 90},
]
clientes = [
    {"id": "C001", "nombre": "Transportes Oriente SRL", "ciudad": "Santa Cruz", "tipo": "mayorista"},
    {"id": "C002", "nombre": "Taller Mecanico El Pilar", "ciudad": "Santa Cruz", "tipo": "minorista"},
    {"id": "C003", "nombre": "Agroindustrial Norte", "ciudad": "Montero", "tipo": "mayorista"},
    {"id": "C004", "nombre": "Flota Express", "ciudad": "Cochabamba", "tipo": "mayorista"},
    {"id": "C005", "nombre": "Lubricentro San Martin", "ciudad": "Santa Cruz", "tipo": "minorista"},
]

for tabla, items in (("productos", productos), ("clientes", clientes)):
    t = db.Table(tabla)
    for item in items:
        t.put_item(Item=item)
    print(tabla, "cargados:", len(items))

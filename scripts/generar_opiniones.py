"""Genera los CSV de prueba: data/opiniones.csv (200 opiniones variadas) y
data/opiniones_crisis.csv (40 opiniones mayormente negativas, para disparar la alerta en la demo).

Uso: python scripts/generar_opiniones.py
"""
import csv
import random
from datetime import date, timedelta
from pathlib import Path

POSITIVAS = [
    "Me encanta el sabor de {p}, me da energía para toda la mañana",
    "{p} es el mejor jugo energético que probé, súper natural",
    "Compré {p} para entrenar y rindo muchísimo mejor",
    "Excelente {p}, no tiene ese gusto artificial de otras marcas",
    "La nueva lata de {p} es hermosa y el sabor increíble",
    "Recomiendo {p} a todos, ideal para la facultad",
    "{p} me salvó la semana de parciales, muy bueno",
    "Gran atención al cliente de ZenithZest, me cambiaron un pack sin problema",
    "Por fin un energético sin tanta azúcar, {p} es genial",
    "El {p} bien frío es una delicia, ya es mi favorito",
]
NEGATIVAS = [
    "{p} es demasiado dulce, no lo vuelvo a comprar",
    "Me cayó pésimo {p}, me dio dolor de cabeza",
    "Carísimo para lo que es, {p} no vale la pena",
    "La lata de {p} llegó abollada y nadie me respondió el reclamo",
    "El sabor de {p} cambió y ahora es horrible",
    "{p} tiene gusto a jarabe, muy decepcionante",
    "Nunca hay stock de {p} en el supermercado, qué mala distribución",
    "Pésima experiencia con la tienda online de ZenithZest, el pedido nunca llegó",
]
NEUTRAS = [
    "Probé {p} ayer en la oficina",
    "Vi que {p} ahora viene en botella de vidrio",
    "¿Alguien sabe si {p} tiene cafeína?",
    "{p} está en promoción esta semana en el súper",
    "Compré {p} y otro energético para comparar",
    "ZenithZest sacó un sabor nuevo de {p}",
]
PRODUCTOS = ["ZenithZest Mango", "ZenithZest Citrus", "ZenithZest Berry", "ZenithZest Zero", "ZenithZest Ginger"]
CANALES = ["instagram", "x", "tienda online", "encuesta", "reseña google"]


def opiniones(n, pesos, semilla):
    azar = random.Random(semilla)
    inicio = date(2026, 10, 1)
    filas = []
    for i in range(1, n + 1):
        plantillas = azar.choices([POSITIVAS, NEGATIVAS, NEUTRAS], weights=pesos)[0]
        texto = azar.choice(plantillas).format(p=azar.choice(PRODUCTOS))
        fecha = inicio + timedelta(days=azar.randrange(45))
        filas.append({"id": i, "fecha": fecha.isoformat(), "canal": azar.choice(CANALES), "opinion": texto})
    return filas


def guardar(ruta, filas):
    ruta.parent.mkdir(exist_ok=True)
    with ruta.open("w", newline="", encoding="utf-8") as archivo:
        escritor = csv.DictWriter(archivo, fieldnames=["id", "fecha", "canal", "opinion"])
        escritor.writeheader()
        escritor.writerows(filas)
    print(f"{ruta}: {len(filas)} opiniones")


if __name__ == "__main__":
    data = Path(__file__).resolve().parent.parent / "data"
    guardar(data / "opiniones.csv", opiniones(200, [55, 25, 20], semilla=7))
    guardar(data / "opiniones_crisis.csv", opiniones(40, [10, 80, 10], semilla=13))

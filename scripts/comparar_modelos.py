"""Extra del enunciado: comparar la API de lenguaje con un modelo local simple (VADER).

VADER está pensado para inglés: se le agrega un léxico básico de palabras en español con su
polaridad (escala de VADER, −4 a +4). Corre en la laptop, sin costo, sobre un reporte del job.

Uso:
  pip install vaderSentiment==3.3.2
  gcloud storage cp gs://<proyecto>-zz-dev-reportes/<fecha>/reporte-<hora>.csv reporte.csv
  python scripts/comparar_modelos.py reporte.csv [--md docs/comparacion-modelos.md]

Si el CSV no trae la columna "sentimiento" de la API (ej. data/opiniones.csv), solo muestra
la distribución de VADER.
"""
import argparse
import csv
import sys
from collections import Counter

from vaderSentiment.vaderSentiment import NEGATE, SentimentIntensityAnalyzer

LEXICO_ES = {
    # positivas
    "encanta": 3.0, "encantó": 3.0, "excelente": 3.2, "increíble": 3.0, "genial": 3.0, "mejor": 2.0,
    "bueno": 1.9, "buena": 1.9, "buenísimo": 3.0, "rico": 2.0, "rica": 2.0, "delicia": 3.0, "delicioso": 3.0,
    "recomiendo": 2.5, "ideal": 2.0, "favorito": 2.0, "favorita": 2.0, "hermosa": 2.5, "hermoso": 2.5,
    "natural": 1.0, "salvó": 2.0, "gran": 1.5, "feliz": 2.5, "perfecto": 3.0, "perfecta": 3.0, "amo": 3.0,
    "gracias": 1.5, "rápido": 1.0, "fresco": 1.0, "energía": 1.0, "rindo": 1.5,
    # negativas
    "malo": -2.5, "mala": -2.5, "pésimo": -3.2, "pésima": -3.2, "horrible": -3.0, "asco": -3.0,
    "decepcionante": -2.5, "decepción": -2.5, "carísimo": -2.0, "caro": -1.5, "dolor": -2.0,
    "abollada": -1.5, "reclamo": -1.5, "jarabe": -1.0, "artificial": -1.0, "nunca": -0.5, "peor": -2.5,
    "odio": -3.0, "feo": -2.0, "fea": -2.0, "tarde": -1.0, "roto": -2.0, "rota": -2.0, "estafa": -3.0,
}
NEGACIONES_ES = ["no", "ni", "jamás", "tampoco", "sin"]


def crear_modelo():
    modelo = SentimentIntensityAnalyzer()
    modelo.lexicon.update(LEXICO_ES)
    NEGATE.extend(NEGACIONES_ES)
    return modelo


def clasificar(compound):
    if compound >= 0.05:
        return "positivo"
    if compound <= -0.05:
        return "negativo"
    return "neutro"


def comparar(filas, modelo):
    for fila in filas:
        fila["vader_compound"] = modelo.polarity_scores(fila["opinion"].lower())["compound"]
        fila["vader"] = clasificar(fila["vader_compound"])
    return filas


def informe(filas):
    clases = ["positivo", "negativo", "neutro"]
    total = len(filas)
    lineas = [f"Opiniones analizadas: {total}", ""]
    dist_vader = Counter(f["vader"] for f in filas)
    if "sentimiento" not in filas[0]:
        lineas.append("| Sentimiento | VADER |")
        lineas.append("|---|---|")
        lineas += [f"| {c} | {100 * dist_vader[c] / total:.1f} % |" for c in clases]
        return "\n".join(lineas)

    dist_api = Counter(f["sentimiento"] for f in filas)
    acuerdo = sum(f["vader"] == f["sentimiento"] for f in filas)
    lineas.append(f"**Coincidencia VADER vs. API: {100 * acuerdo / total:.1f} %** ({acuerdo} de {total})")
    lineas += ["", "| Sentimiento | API | VADER |", "|---|---|---|"]
    lineas += [f"| {c} | {100 * dist_api[c] / total:.1f} % | {100 * dist_vader[c] / total:.1f} % |" for c in clases]
    lineas += ["", "Matriz de confusión (filas = API, columnas = VADER):", "",
               "| API \\ VADER | " + " | ".join(clases) + " |", "|---|---|---|---|"]
    for real in clases:
        fila = [sum(1 for f in filas if f["sentimiento"] == real and f["vader"] == pred) for pred in clases]
        lineas.append(f"| {real} | " + " | ".join(map(str, fila)) + " |")
    distintas = [f for f in filas if f["vader"] != f["sentimiento"]][:5]
    if distintas:
        lineas += ["", "Ejemplos donde no coinciden:", ""]
        lineas += [f"- \"{f['opinion']}\" → API: {f['sentimiento']} ({float(f['score']):.2f}) · "
                   f"VADER: {f['vader']} ({f['vader_compound']:.2f})" for f in distintas]
    return "\n".join(lineas)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("csv", help="Reporte CSV del job (o un CSV con columna 'opinion')")
    parser.add_argument("--md", help="Guardar el resultado en este archivo Markdown")
    args = parser.parse_args()
    with open(args.csv, encoding="utf-8") as archivo:
        filas = list(csv.DictReader(archivo))
    texto = informe(comparar(filas, crear_modelo()))
    sys.stdout.reconfigure(encoding="utf-8")  # la consola de Windows no es UTF-8 por defecto
    print(texto)
    if args.md:
        with open(args.md, "w", encoding="utf-8") as salida:
            salida.write("# Comparación: Natural Language API vs. VADER (local)\n\n" + texto + "\n")

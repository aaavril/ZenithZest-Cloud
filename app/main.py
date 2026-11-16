"""ZenithZest: job diario que analiza el sentimiento de las opiniones de clientes.

Lee un CSV del bucket de entrada, clasifica cada opinión con la API de lenguaje,
escribe un reporte CSV + HTML en el bucket de reportes, publica el % de cada
sentimiento como métrica personalizada y avisa el resumen por webhook.
"""
import csv
import io
import json
import os
import sys
import urllib.request
from collections import Counter
from datetime import datetime, timezone
from html import escape

UMBRAL = 0.25  # |score| por debajo de esto se considera neutro
METRICA = "custom.googleapis.com/zenithzest/sentiment_pct"


def log(severidad, mensaje, **extra):
    """Log estructurado: Cloud Logging lee 'severity' y 'message' del JSON."""
    print(json.dumps({"severity": severidad, "message": mensaje, **extra}, ensure_ascii=False), flush=True)


def clasificar(score):
    if score >= UMBRAL:
        return "positivo"
    if score <= -UMBRAL:
        return "negativo"
    return "neutro"


def leer_opiniones(texto_csv, maximo):
    filas = list(csv.DictReader(io.StringIO(texto_csv)))
    return [f for f in filas if f.get("opinion", "").strip()][:maximo]


def resumir(resultados):
    total = len(resultados)
    cuenta = Counter(r["sentimiento"] for r in resultados)
    pct = {s: round(100 * cuenta.get(s, 0) / total, 1) if total else 0.0
           for s in ("positivo", "negativo", "neutro")}
    return {"total": total, "pct": pct}


def reporte_csv(resultados):
    salida = io.StringIO()
    campos = ["id", "fecha", "canal", "opinion", "score", "magnitud", "sentimiento"]
    escritor = csv.DictWriter(salida, fieldnames=campos, extrasaction="ignore")
    escritor.writeheader()
    escritor.writerows(resultados)
    return salida.getvalue()


def reporte_html(resultados, resumen, fecha):
    filas = "".join(
        f"<tr class='{escape(r['sentimiento'])}'><td>{escape(str(r.get('id', '')))}</td>"
        f"<td>{escape(r['opinion'])}</td><td>{r['score']:.2f}</td><td>{escape(r['sentimiento'])}</td></tr>"
        for r in resultados)
    p = resumen["pct"]
    return (f"<!doctype html><html lang='es'><meta charset='utf-8'><title>ZenithZest {fecha}</title>"
            "<style>body{font-family:sans-serif;margin:2rem}td{padding:4px 8px;border-bottom:1px solid #ddd}"
            ".positivo{background:#e8f5e9}.negativo{background:#ffebee}</style>"
            f"<h1>Sentimiento de opiniones - {fecha}</h1>"
            f"<p>{resumen['total']} opiniones: <b>{p['positivo']}% positivas</b>, "
            f"<b>{p['negativo']}% negativas</b>, {p['neutro']}% neutras.</p>"
            f"<table><tr><th>id</th><th>opinión</th><th>score</th><th>sentimiento</th></tr>{filas}</table></html>")


def analizar(filas):
    from google.cloud import language_v1
    cliente = language_v1.LanguageServiceClient()
    resultados = []
    for fila in filas:
        doc = language_v1.Document(content=fila["opinion"], type_=language_v1.Document.Type.PLAIN_TEXT, language="es")
        s = cliente.analyze_sentiment(request={"document": doc}).document_sentiment
        resultados.append({**fila, "score": s.score, "magnitud": s.magnitude, "sentimiento": clasificar(s.score)})
    return resultados


def publicar_metricas(proyecto, resumen):
    from google.cloud import monitoring_v3
    cliente = monitoring_v3.MetricServiceClient()
    ahora = monitoring_v3.TimeInterval(end_time={"seconds": int(datetime.now(timezone.utc).timestamp())})
    series = []
    for sentimiento, valor in resumen["pct"].items():
        serie = monitoring_v3.TimeSeries()
        serie.metric.type = METRICA
        serie.metric.labels["sentiment"] = sentimiento
        serie.resource.type = "global"
        serie.resource.labels["project_id"] = proyecto
        serie.points = [monitoring_v3.Point(interval=ahora, value={"double_value": valor})]
        series.append(serie)
    cliente.create_time_series(name=f"projects/{proyecto}", time_series=series)


def notificar(proyecto, secreto, resumen, ruta):
    """El webhook (Discord/Slack) vive en Secret Manager; si no está cargado, se omite el aviso."""
    try:
        from google.cloud import secretmanager
        cliente = secretmanager.SecretManagerServiceClient()
        nombre = f"projects/{proyecto}/secrets/{secreto}/versions/latest"
        url = cliente.access_secret_version(name=nombre).payload.data.decode().strip()
    except Exception as error:  # secreto sin versión o sin permiso: no frena el job
        log("WARNING", "Sin webhook: no se envía el resumen", error=str(error))
        return
    p = resumen["pct"]
    texto = (f"ZenithZest: {resumen['total']} opiniones -> {p['positivo']}% positivas, "
             f"{p['negativo']}% negativas, {p['neutro']}% neutras. Reporte: {ruta}")
    cuerpo = json.dumps({"content": texto, "text": texto}).encode()
    pedido = urllib.request.Request(url, data=cuerpo, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(pedido, timeout=10) as respuesta:
        log("INFO", "Resumen enviado al webhook", status=respuesta.status)


def main():
    from google.cloud import storage
    proyecto = os.environ["PROJECT_ID"]
    entrada, objeto = os.environ["INPUT_BUCKET"], os.environ.get("INPUT_OBJECT", "opiniones.csv")
    reportes, secreto = os.environ["REPORTS_BUCKET"], os.environ.get("SECRET_ID", "zenithzest-webhook")
    maximo = int(os.environ.get("MAX_OPINIONS", "200"))

    gcs = storage.Client(project=proyecto)
    filas = leer_opiniones(gcs.bucket(entrada).blob(objeto).download_as_text(encoding="utf-8"), maximo)
    log("INFO", "Opiniones leídas", total=len(filas), origen=f"gs://{entrada}/{objeto}")

    resultados = analizar(filas)
    resumen = resumir(resultados)
    fecha = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    base = f"{fecha}/reporte-{datetime.now(timezone.utc).strftime('%H%M%S')}"
    bucket = gcs.bucket(reportes)
    bucket.blob(f"{base}.csv").upload_from_string(reporte_csv(resultados), content_type="text/csv")
    bucket.blob(f"{base}.html").upload_from_string(reporte_html(resultados, resumen, fecha), content_type="text/html")
    ruta = f"gs://{reportes}/{base}.html"

    publicar_metricas(proyecto, resumen)
    log("INFO", "Análisis terminado", reporte=ruta, **resumen["pct"])
    notificar(proyecto, secreto, resumen, ruta)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        log("ERROR", "El job falló", error=str(error))
        sys.exit(1)

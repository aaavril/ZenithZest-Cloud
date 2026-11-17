import csv
import io
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import main  # noqa: E402


def test_clasificar_umbral():
    assert main.clasificar(0.8) == "positivo"
    assert main.clasificar(0.25) == "positivo"
    assert main.clasificar(0.1) == "neutro"
    assert main.clasificar(-0.25) == "negativo"


def test_leer_opiniones_respeta_maximo_y_saltea_vacias():
    texto = "id,opinion\n1,Rico\n2,\n3,Malo\n4,Normal\n"
    filas = main.leer_opiniones(texto, 2)
    assert [f["id"] for f in filas] == ["1", "3"]


def test_resumir_porcentajes():
    resultados = [{"sentimiento": s} for s in ["positivo", "positivo", "negativo", "neutro"]]
    resumen = main.resumir(resultados)
    assert resumen["total"] == 4
    assert resumen["pct"] == {"positivo": 50.0, "negativo": 25.0, "neutro": 25.0}


def test_resumir_vacio():
    assert main.resumir([])["pct"]["positivo"] == 0.0


def test_webhook_que_falla_no_hace_fallar_el_job(monkeypatch, capsys):
    import types
    import urllib.request

    falso = types.ModuleType("google.cloud.secretmanager")

    class Cliente:
        def access_secret_version(self, name):
            return types.SimpleNamespace(payload=types.SimpleNamespace(data=b"https://ejemplo.invalid/hook"))

    falso.SecretManagerServiceClient = Cliente
    monkeypatch.setitem(sys.modules, "google.cloud.secretmanager", falso)
    import google.cloud
    monkeypatch.setattr(google.cloud, "secretmanager", falso, raising=False)

    def urlopen_403(pedido, timeout):
        assert pedido.get_header("User-agent", "").startswith("ZenithZest")
        raise urllib.error.HTTPError(pedido.full_url, 403, "Forbidden", None, None)

    monkeypatch.setattr(urllib.request, "urlopen", urlopen_403)
    main.notificar("proyecto", "secreto", main.resumir([{"sentimiento": "positivo"}]), "gs://x")
    assert "No se pudo enviar el resumen" in capsys.readouterr().out


def test_reportes():
    resultados = [{"id": "1", "fecha": "2026-11-01", "canal": "web", "opinion": "Me <encanta>",
                   "score": 0.9, "magnitud": 0.9, "sentimiento": "positivo"}]
    filas = list(csv.DictReader(io.StringIO(main.reporte_csv(resultados))))
    assert filas[0]["sentimiento"] == "positivo"
    html = main.reporte_html(resultados, main.resumir(resultados), "2026-11-01")
    assert "&lt;encanta&gt;" in html and "100.0% positivas" in html

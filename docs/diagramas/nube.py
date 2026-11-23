"""Arquitectura en Google Cloud con íconos oficiales: python nube.py → nube.png; con "ancho" → nube-ancho.png (slides)."""
import sys

from diagrams import Cluster, Diagram, Edge
from diagrams.gcp.compute import Run
from diagrams.gcp.devtools import ContainerRegistry, Scheduler
from diagrams.gcp.ml import NaturalLanguageAPI
from diagrams.gcp.operations import Logging, Monitoring
from diagrams.gcp.security import Iam, SecretManager
from diagrams.gcp.storage import GCS
from diagrams.gcp.management import Billing
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.client import Users
from diagrams.saas.chat import Discord

grafo = {"fontsize": "20", "fontname": "Helvetica", "pad": "0.4", "nodesep": "0.7", "ranksep": "1.1", "newrank": "true"}
nodo = {"fontsize": "13", "fontname": "Helvetica"}
grupo = {"fontsize": "15", "fontname": "Helvetica-Bold", "margin": "18"}

ANCHO = "ancho" in sys.argv[1:]

with Diagram("ZenithZest · arquitectura en Google Cloud", filename="nube-ancho" if ANCHO else "nube", show=False,
             direction="TB" if ANCHO else "LR",
             graph_attr=grafo, node_attr=nodo, outformat="png"):
    gha = GithubActions("GitHub Actions\n(deploy.yml)")

    with Cluster("Google Cloud · proyecto zenithzest · us-central1", graph_attr={**grupo, "bgcolor": "#F1F6FE"}):
        with Cluster("Bootstrap (una vez, desde Cloud Shell)", graph_attr={**grupo, "bgcolor": "#FFF8E1"}):
            wif = Iam("Workload Identity\nFederation (OIDC)")
            registro = ContainerRegistry("Artifact Registry\napp:<sha>")
            state = GCS("Bucket del state\n(versionado, lock)")
            presupuesto = Billing("Presupuesto USD 10\n50 / 80 / 100 %")

        with Cluster("Entorno dev (lo aplica el pipeline)", graph_attr={**grupo, "bgcolor": "#E8F5E9"}):
            cron = Scheduler("Cloud Scheduler\n09:00 diario")
            job = Run("Cloud Run Job\nzenithzest-job")
            entrada = GCS("Bucket entrada\nopiniones.csv")
            reportes = GCS("Bucket reportes\nCSV + HTML")
            secreto = SecretManager("Secret Manager\nwebhook")
            monitoreo = Monitoring("Cloud Monitoring\nmétrica · dashboard\n2 alertas")
            logs = Logging("Cloud Logging\n7 días")

        ia = NaturalLanguageAPI("Natural Language\nAPI")

    with Cluster("Fuera de Google Cloud", graph_attr={**grupo, "bgcolor": "#F8F9FA"}):
        discord = Discord("Discord\n(resumen)")
        equipo = Users("Equipo\n(mail de alerta)")

    gha >> Edge(label="token OIDC,\nsin claves", color="#1A73E8", style="bold") >> wif
    gha >> Edge(label="push imagen", color="#1A73E8") >> registro
    gha >> Edge(label="terraform apply", color="#1A73E8") >> state

    cron >> Edge(label="run.invoker", color="#F9AB00", style="bold") >> job
    registro >> Edge(style="dashed", color="#9AA0A6") >> job
    entrada >> Edge(label="objectViewer") >> job
    secreto >> Edge(label="secretAccessor") >> job
    job >> Edge(label="analyzeSentiment", color="#D93025") >> ia
    job >> Edge(label="objectCreator") >> reportes
    job >> Edge(label="metricWriter") >> monitoreo
    job >> Edge(style="dashed", color="#9AA0A6") >> logs
    job >> Edge(label="resumen", color="#5865F2") >> discord
    monitoreo >> Edge(label="% negativo > 40\no job fallido", color="#D93025") >> equipo
    presupuesto >> Edge(style="dashed", color="#9AA0A6") >> equipo

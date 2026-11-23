"""Diagrama del pipeline CI/CD con íconos (python cicd.py → cicd.png)."""
from diagrams import Cluster, Diagram, Edge
from diagrams.gcp.compute import Run
from diagrams.gcp.devtools import ContainerRegistry
from diagrams.gcp.security import Iam
from diagrams.gcp.storage import GCS
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.client import User
from diagrams.onprem.container import Docker
from diagrams.onprem.iac import Terraform
from diagrams.onprem.vcs import Github
from diagrams.programming.language import Python

grafo = {"fontsize": "20", "fontname": "Helvetica", "pad": "0.4", "nodesep": "0.5", "ranksep": "0.9"}
nodo = {"fontsize": "13", "fontname": "Helvetica"}
grupo = {"fontsize": "15", "fontname": "Helvetica-Bold", "margin": "18"}

with Diagram("ZenithZest · pipeline CI/CD", filename="cicd", show=False, direction="LR",
             graph_attr=grafo, node_attr=nodo, outformat="png"):
    dev = User("Integrante\n(rama + PR)")
    repo = Github("GitHub\nPull Request")

    with Cluster("ci.yml · en cada PR (en paralelo)", graph_attr={**grupo, "bgcolor": "#E8F0FE"}):
        tests = Python("tests de la app\n(pytest)")
        calidad = Terraform("fmt · validate\ntflint · Checkov")
        secretos = GithubActions("gitleaks\n(secretos)")
        imagen = Docker("build + Trivy\n(imagen)")
        costos = GithubActions("Infracost\n(costo del PR)")
        plan = Terraform("terraform plan\ncomentado en el PR")

    revision = User("Compuerta 1\naprobar el PR\n(revisando el plan)")

    with Cluster("deploy.yml · merge a main", graph_attr={**grupo, "bgcolor": "#E6F4EA"}):
        build = Docker("build + Trivy\npush app:<sha>")
        aprobacion = User("Compuerta 2\nenvironment dev\n(required reviewers)")
        apply = Terraform("plan -out\napply tfplan")

    with Cluster("Google Cloud", graph_attr={**grupo, "bgcolor": "#FEF7E0"}):
        wif = Iam("OIDC\n(Workload Identity)")
        registro = ContainerRegistry("Artifact Registry")
        state = GCS("state remoto")
        job = Run("Cloud Run Job")

    otros = GithubActions("run-job.yml · destroy.yml\n(manuales)")

    dev >> repo
    repo >> [tests, calidad, secretos, imagen, costos]
    calidad >> plan
    [tests, plan, secretos, imagen] >> Edge(color="#1A73E8") >> revision
    revision >> Edge(label="merge", color="#1E8E3E", style="bold") >> build
    build >> aprobacion >> apply
    build >> Edge(label="token OIDC", color="#1A73E8", style="dashed") >> wif
    build >> Edge(color="#1A73E8") >> registro
    apply >> Edge(color="#1A73E8") >> state
    apply >> Edge(label="imagen por SHA", color="#1A73E8") >> job
    otros >> Edge(style="dashed", color="#9AA0A6") >> job

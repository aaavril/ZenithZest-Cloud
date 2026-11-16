# Matriz IAM

Principio: **menor privilegio**, cada permiso sobre el recurso más chico posible. Tres identidades técnicas,
ninguna con claves descargables.

| Identidad | Permiso (rol) | Recurso | Justificación |
|---|---|---|---|
| **zenithzest-job-sa** (job) | `roles/storage.objectViewer` | Bucket **entrada** | Leer `opiniones.csv`. No puede escribir ni borrar. |
| zenithzest-job-sa | `roles/storage.objectCreator` | Bucket **reportes** | Crear los reportes. No puede leerlos, sobrescribirlos ni borrarlos. |
| zenithzest-job-sa | `roles/secretmanager.secretAccessor` | Secreto **zenithzest-webhook** | Leer la URL del webhook. Solo ese secreto. |
| zenithzest-job-sa | `roles/monitoring.metricWriter` | Proyecto | Publicar la métrica personalizada. No hay rol a nivel de métrica; no permite leer ni borrar. |
| zenithzest-job-sa | `roles/serviceusage.serviceUsageConsumer` | Proyecto | Consumir la Natural Language API facturando al proyecto. |
| **zenithzest-job-cron** (scheduler) | `roles/run.invoker` | Job **zenithzest-job** | Ejecutar solo ese job. No puede cambiarlo ni ver otros. |
| **zenithzest-pipeline** (GitHub Actions) | `roles/iam.workloadIdentityUser` | La propia cuenta, para `principalSet` del repo | Solo tokens OIDC de **este repositorio** pueden usarla (`attribute_condition`). |
| zenithzest-pipeline | `roles/artifactregistry.writer` | Repositorio **zenithzest** | Subir imágenes. |
| zenithzest-pipeline | `roles/run.admin` | Proyecto | Crear/actualizar el job y ejecutarlo (`run-job.yml`). |
| zenithzest-pipeline | `roles/storage.admin` | Proyecto | Crear los buckets y leer/escribir el state. |
| zenithzest-pipeline | `roles/cloudscheduler.admin` | Proyecto | Crear el programador. |
| zenithzest-pipeline | `roles/secretmanager.admin` | Proyecto | Crear el secreto (vacío) y su IAM. |
| zenithzest-pipeline | `roles/monitoring.editor` | Proyecto | Métrica, dashboard, alertas y canales. |
| zenithzest-pipeline | `roles/logging.configWriter` | Proyecto | Retención de 7 días del bucket `_Default`. |
| zenithzest-pipeline | `roles/iam.serviceAccountAdmin` | Proyecto | Crear las cuentas del job y del scheduler. |
| zenithzest-pipeline | `roles/iam.serviceAccountUser` | Proyecto | Asignar la cuenta del job al job (actAs). |
| zenithzest-pipeline | `roles/resourcemanager.projectIamAdmin` | Proyecto | Dar al job `metricWriter` y `serviceUsageConsumer` a nivel proyecto. |
| **Integrantes** (personas) | Owner del proyecto | Proyecto | Bootstrap inicial y carga del secreto. Fuera de eso, todo cambio pasa por PR + pipeline. |

## Riesgos aceptados

- El pipeline tiene roles amplios (admin de varios servicios, `serviceAccountUser`, `projectIamAdmin`): es lo que
  necesita para crear la infraestructura. Se mitiga con: OIDC limitado al repositorio, credenciales que duran una
  ejecución, aprobación manual del environment `dev` antes de cada apply y ramas protegidas. Checkov lo marca
  (CKV_GCP_41/49) y está justificado en el código.
- Mejora posible: un rol personalizado con solo los permisos usados por el plan, o separar una cuenta "plan"
  (solo lectura, para los PR) de la cuenta "apply".

## Cómo verificarlo en la demo

```bash
gcloud storage buckets get-iam-policy gs://<proyecto>-zz-dev-entrada
gcloud secrets get-iam-policy zenithzest-webhook
gcloud run jobs get-iam-policy zenithzest-job --region us-central1
gcloud projects get-iam-policy <proyecto> --flatten="bindings[].members" \
  --filter="bindings.members:zenithzest-job-sa" --format="table(bindings.role)"
```

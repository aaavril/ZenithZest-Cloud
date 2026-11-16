# Informe de análisis de seguridad

Herramientas: **Checkov 3.2** (Terraform, Dockerfile, GitHub Actions), **tflint** (reglas de Terraform y Google),
**gitleaks** (secretos en el historial de Git) y **Trivy** (vulnerabilidades de la imagen). Todas corren en cada PR
(`ci.yml`); Checkov y Trivy (CRITICAL) bloquean el merge.

## Controles por diseño

- Sin credenciales de larga duración: GitHub → Google Cloud por OIDC (Workload Identity Federation), restringido
  con `attribute_condition` al repositorio.
- Secreto creado vacío por Terraform; el valor se carga por CLI → nunca está en Git ni en el state.
- Buckets privados (`public_access_prevention = enforced`, acceso uniforme), cifrados en reposo por defecto.
- Imagen sin root (`USER 10001`), multi-stage, base `slim` con versión fija, desplegada por SHA (nunca `latest`).
- Permisos mínimos por identidad ([iam.md](iam.md)); `permissions: contents: read` por defecto en los workflows.
- `.gitignore` excluye state, planes, tfvars locales y archivos de credenciales.

## Hallazgos de Checkov (primera corrida, 14/11/2026) y tratamiento

Resultado inicial: Terraform 63 pasaron / 9 fallaron · Dockerfile 30 / 0 · GitHub Actions 234 / 2.

| ID | Recurso | Hallazgo | Decisión |
|---|---|---|---|
| CKV_GCP_62 | Bucket del state, entrada y reportes | Sin logs de acceso del bucket | **Aceptado**: costo y ruido en un entorno de pruebas; los cambios administrativos quedan en Cloud Audit Logs; el state tiene versionado. |
| CKV_GCP_78 | Buckets entrada y reportes | Sin versionado | **Aceptado**: datos de prueba regenerables con TTL. El bucket del state **sí** tiene versionado. |
| CKV_GCP_84 | Artifact Registry | Sin clave de cifrado del cliente | **Aceptado**: cifrado por defecto de Google; CMEK suma costo de KMS y la imagen no contiene datos sensibles. |
| CKV_GCP_41, CKV_GCP_49 | Roles del pipeline | `serviceAccountUser` / `serviceAccountAdmin` a nivel proyecto | **Aceptado con mitigación**: el pipeline crea y asigna las cuentas del job y del scheduler. Mitigado por OIDC limitado al repo, aprobación manual del environment y ramas protegidas. Mejora futura: rol personalizado. |
| CKV_GHA_7 | `destroy.yml`, `run-job.yml` | `workflow_dispatch` con inputs | **Aceptado**: los inputs (texto de confirmación, elección del CSV) no afectan a ningún artefacto construido. |

Cada aceptación está en el código como `#checkov:skip=<ID>:<motivo>` (o en `.checkov.yaml` para CKV_GHA_7).
Después: `soft-fail: false` → resultado Terraform 48 / 0 (24 omitidos justificados), Dockerfile 30 / 0,
GitHub Actions 232 / 0.

## tflint

Primera corrida: faltaban `required_version` y `required_providers` en los módulos. **Corregido**: cada módulo
tiene su `versions.tf`. Segunda corrida: sin hallazgos.

## Trivy (imagen)

Completar con la salida del primer PR (`ci.yml` → job `imagen`):

| Severidad | Cantidad | Paquete | Acción |
|---|---|---|---|
| CRITICAL | | | |
| HIGH | | | |

Correcciones típicas: actualizar la base (`python:3.12-slim` a la última versión de parche), actualizar la
librería afectada en `requirements.txt` o pasar a `distroless`.

## gitleaks

Completar con la salida del primer PR: esperado **0 hallazgos**. Captura para el informe.

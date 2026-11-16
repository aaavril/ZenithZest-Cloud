# Elección de proveedor: Google Cloud

**Decisión:** Google Cloud, región única `us-central1`.

## Por qué

| Criterio | Google Cloud | AWS | Azure |
|---|---|---|---|
| Job de contenedor programado | **Cloud Run Jobs + Cloud Scheduler**: dos recursos, el scheduler llama a la API del job con su propia identidad | ECS Fargate (cluster + task definition + rol de ejecución + EventBridge Scheduler con rol) o Lambda (no es un job de contenedor de larga duración) | Container Apps Jobs: requiere un *Container Apps environment* y un workspace de Log Analytics |
| IA de lenguaje en español | Natural Language API (sentimiento por documento) | Comprehend | AI Language |
| OIDC desde GitHub (requisito: sin claves) | Workload Identity Federation, se crea con Terraform | IAM OIDC provider; **en AWS Academy Learner Lab no se pueden crear roles ni proveedores OIDC** (solo LabRole) | Federated credential en Entra ID; Azure for Students puede limitar el registro de aplicaciones |
| Métrica personalizada + dashboard + alertas como código | Metric descriptor, dashboard JSON y alert policies en Terraform | CloudWatch (similar) | Application Insights (similar) |
| Costo con tráfico de prueba | Todo pago por uso; el job no cobra cuando no corre | Similar | El environment de Container Apps y Log Analytics agregan piezas |
| Créditos | Prueba gratuita para cuentas nuevas y créditos educativos | AWS Academy / Educate | Azure for Students |

En resumen: es el proveedor donde el caso (job programado + IA de lenguaje + secreto + métrica) se arma con
**menos piezas**, y donde el requisito de **OIDC sin claves** se cumple sin las restricciones de las cuentas
académicas de AWS.

## Riesgos y cómo se manejan

- La prueba gratuita pide una tarjeta para la cuenta de facturación → presupuesto de USD 10 con avisos al 50/80/100 %
  creado el primer día (en el bootstrap).
- La API de lenguaje cobra por unidad de texto pasada la cuota gratuita mensual → tope `max_opinions` y scheduler
  pausable (`scheduler_paused`).
- Las condiciones de la capa gratuita cambian: **verificarlas en la página de precios al empezar y anotarlas en
  [finops.md](finops.md)** (lo pide el enunciado).

## Equivalencias (si hubiera que migrar)

| Componente | Google Cloud (elegido) | AWS | Azure |
|---|---|---|---|
| Job | Cloud Run Jobs | ECS Fargate task / Lambda | Container Apps Jobs |
| Programación | Cloud Scheduler | EventBridge Scheduler | Container Apps Jobs (cron) |
| IA de lenguaje | Natural Language API | Comprehend | Azure AI Language |
| Secretos | Secret Manager | SSM Parameter Store / Secrets Manager | Key Vault |
| Métricas | Cloud Monitoring custom metrics | CloudWatch custom metrics | Application Insights |
| Almacenamiento | Cloud Storage | S3 | Blob Storage |
| Registro de imágenes | Artifact Registry | ECR | Container Registry |

El código está organizado en módulos por capacidad (`storage`, `job`, `scheduler`, `secret`, `monitoring`):
migrar significa reescribir el interior de cada módulo, no el diseño.

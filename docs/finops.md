# FinOps

> Estimaciones con las capas gratuitas y precios de referencia de Google Cloud para `us-central1`; el costo real se confirma con la facturación.

## Medidas de ahorro aplicadas

| Medida | Dónde |
|---|---|
| Presupuesto USD 10 con avisos 50/80/100 % al equipo, desde el día 1 | `infra/bootstrap` (`google_billing_budget`) |
| Todo pago por uso: el job no cobra mientras no corre; no hay balanceador, NAT, base gestionada ni clúster | Arquitectura |
| Tope de opiniones por corrida (`max_opinions = 200`) | `dev.tfvars` |
| Scheduler pausable fuera de la demo (`scheduler_paused`) | `dev.tfvars` |
| Retención de logs 7 días | módulo `monitoring` |
| TTL: entrada 30 días, reportes 14 días | módulo `storage` |
| Registro de imágenes: conserva las últimas 5 y borra las de más de 7 días | `infra/bootstrap` |
| Imagen chica (`python:3.12-slim`, multi-stage) | `app/Dockerfile` |
| Una sola región (`us-central1`) | variables |
| `destroy.yml` al terminar cada sesión de trabajo | workflow |

## Costo del entorno de pruebas (estimado)

| Servicio | Uso en pruebas | Capa gratuita | Costo estimado |
|---|---|---|---|
| Natural Language API (sentimiento) | ~200 unidades por corrida × N corridas | 5.000 unidades/mes | USD 0 si N ≤ 25 corridas/mes |
| Cloud Run Jobs | 1 corrida diaria de ~1–2 min, 1 vCPU, 512 MiB | 180.000 vCPU-s y 360.000 GiB-s/mes | USD 0 |
| Cloud Scheduler | 1 job | 3 jobs por cuenta de facturación | USD 0 |
| Secret Manager | 1 secreto, 1 versión, ~1 acceso/día | 6 versiones activas y 10.000 accesos/mes | USD 0 |
| Cloud Storage | < 1 MB | 5 GB-mes en regiones de EE. UU. | USD 0 |
| Artifact Registry | ~5 imágenes de ~60 MB | 0,5 GB | USD 0 – 0,10 |
| Cloud Monitoring | 3 series personalizadas | 150 MiB de métricas/mes | USD 0 |
| Cloud Logging | pocos MB | 50 GiB/mes | USD 0 |
| **Total** | | | **≈ USD 0 – 1 / mes** (coincide con el enunciado) |

Ojo: 200 opiniones × 30 días = 6.000 unidades → pasa la cuota gratuita si el scheduler queda activo todo el mes.
Con el scheduler pausado fuera de la demo, queda dentro.

## Proyección a escala productiva

Supuesto: la marca recibe **10.000 opiniones por día** (redes, encuestas, reseñas), una corrida diaria.

| Servicio | Cálculo | Estimado mensual |
|---|---|---|
| Natural Language API | 10.000 × 30 = 300.000 unidades; (300.000 − 5.000) / 1.000 × USD 1 | ≈ USD 295 |
| Cloud Run Jobs | ~15 min/día de 1 vCPU (llamadas en serie) ≈ 27.000 vCPU-s/mes | dentro de la capa gratuita |
| Resto | igual que pruebas | ≈ USD 1 |
| **Total** | | **≈ USD 300 / mes**, dominado por la API de lenguaje |

Palancas para bajar el costo productivo:
- Deduplicar y filtrar opiniones vacías o repetidas antes de llamar a la API.
- Analizar solo lo nuevo de cada día (incremental), no el histórico.
- Un modelo local para el grueso y la API solo para los casos dudosos (|score| cerca de 0): VADER coincidió
  con la API en el 91 % de las opiniones ([comparacion-modelos.md](comparacion-modelos.md)).
- Paralelizar con `task_count` del job para bajar el tiempo, no el costo.

# Guion de la presentación (15 min, con demo en vivo)

| Min | Quién | Qué |
|---|---|---|
| 0–1 | Avril | El reto: ¿lo que dicen de ZenithZest es positivo o negativo? Qué entregamos. |
| 1–3 | Sebastián | Proveedor y por qué (docs/proveedor.md). Diagrama de arquitectura y flujo de datos. |
| 3–5 | Avril | Terraform: bootstrap vs. entorno, módulos por capacidad, state remoto con bloqueo, etiquetas, variables con validación. |
| 5–7 | Sebastián | CI/CD: un PR con el plan comentado, Checkov/tflint/gitleaks/Trivy, OIDC sin claves, aprobación del environment. |
| 7–11 | Los dos | **Demo** (abajo). |
| 11–13 | Avril | Seguridad e IAM: matriz, hallazgos y cómo se trataron. FinOps: costo real vs. estimado y proyección. |
| 13–15 | Sebastián | Destroy con evidencia, aprendizajes y preguntas. |

## Demo (4 min)

Preparado de antemano: entorno desplegado, secreto cargado, dashboard y bucket de reportes abiertos en pestañas,
canal de Discord/Slack visible.

1. **Job normal**: Actions → run-job → `opiniones.csv`. Mientras corre, mostrar el job en la consola.
2. **Resultado**: reporte HTML en el bucket, mensaje en el webhook y la métrica en el dashboard (~55 % positivo).
3. **Alerta**: run-job → `opiniones_crisis.csv` (80 % negativas) → la alerta "> 40 %" se dispara y llega el mail.
   (Las métricas tardan unos minutos: lanzarlo al empezar la sección de Seguridad y volver al final.)
4. **Seguridad en vivo**: `gcloud storage buckets get-iam-policy` del bucket de entrada; intentar abrir el bucket
   sin autenticación y que falle.
5. **Cierre**: lanzar `destroy.yml` y mostrar `OK: state vacío`.

## Preguntas probables

- ¿Por qué un job y no una función? → Batch que termina, contenedor con dependencias, sin endpoint público.
- ¿Dónde está el secreto? → Solo en Secret Manager; Terraform crea el recurso vacío; gitleaks en CI.
- ¿Qué pasa si el job falla? → Reintento, alerta "job fallido", runbook.
- ¿Cuánto costaría en producción? → ≈ USD 300/mes con 10.000 opiniones/día, casi todo la API de lenguaje; palancas en finops.md.
- ¿Por qué el pipeline tiene roles amplios? → Crea la infraestructura; mitigaciones y mejora en iam.md.
- ¿Cómo sería en AWS? → Tabla de equivalencias en proveedor.md.

# Bitácora: qué pasó, qué salió mal y qué aprendimos

Registro del proceso real de construir y desplegar ZenithZest. Sirve para el informe y para la defensa
("¿qué problemas tuvieron y cómo los resolvieron?").

## Línea de tiempo

| Fecha | Qué |
|---|---|
| 14/11 | Código, Terraform (bootstrap + 5 módulos), workflows y documentación. Validado localmente con Docker: `fmt`, `validate`, tflint, Checkov y tests. |
| 16/11 | Repo en GitHub. Validaciones en todas las variables, `providers.tf`, Infracost, comparación con VADER, diagrama de arquitectura. |
| 17/11 | Diagramas UML. Cuenta de Google Cloud (prueba gratuita), Terraform en Cloud Shell, proyecto `zenithzest-ucu-1711`, bootstrap (33 recursos), variables y environment en GitHub. Primer `deploy` en verde. Primer `run-job`: el análisis funcionó, pero falló el aviso a Discord; corregido. |
| 17/11 | Deploy automático (push a `main`) con el arreglo, aprobado en el environment. `run-job` #2 en verde: reporte en el bucket y resumen recibido en Discord. |
| 17/11 | `run-job` con `opiniones_crisis.csv`: **90 % negativas** → la alerta "opiniones negativas > 40 %" se disparó a las 14:03 UTC y llegó el mail a los dos integrantes. |
| 17/11 | `destroy.yml` en verde: se destruyó todo el entorno dev y el paso de evidencia confirmó que el state quedó vacío. Queda solo el bootstrap (costo casi nulo). |

## Problemas, causas y soluciones

### Cuenta y herramientas

| Problema | Causa | Solución | Aprendizaje |
|---|---|---|---|
| La prueba gratuita pidió un **prepago de USD 30** | En Uruguay Google exige un prepago único para activar la prueba (reembolsable al cerrar la cuenta de facturación) | Se pagó; la prueba quedó activa con USD 300 de crédito hasta el 15/02/2027 | Verificar las condiciones del proveedor **antes** de elegirlo; preguntar por créditos educativos. No pasar a "cuenta completa" para que el consumo salga de los créditos. |
| `git clone` en Cloud Shell pidió usuario y contraseña y falló | El repo era privado y GitHub ya no acepta contraseñas para git (pide un token) | Se hizo el repo **público** (no tiene secretos; el acceso a la nube está limitado a este repo por OIDC). Alternativas: token de solo lectura o subir un .zip | Un repo sin secretos puede ser público; la seguridad no depende de esconder el código. |
| **Terraform no viene en Cloud Shell** y la instalación con `apt` falló | Cloud Shell dejó de traerlo; el comando sugerido se cortó en dos líneas al pegarlo | Se bajó el binario oficial 1.9.8 a `~/.local/bin`, **verificando el SHA256** | Usar la **misma versión** que el pipeline (1.9.8) evita diferencias entre lo local y CI. Verificar la integridad de lo que se descarga. |
| El proyecto no aparecía en el selector de la consola | Se creó por `gcloud` sin organización y nunca se había abierto desde la consola | Estaba en "Sin organización" → pestaña "Todos" | — |

### Despliegue

| Problema | Causa | Solución | Aprendizaje |
|---|---|---|---|
| Las primeras corridas de `deploy` (16 y 17/11) salieron en rojo | Al subir a `main` se dispara el deploy, pero todavía no existían el proyecto ni las variables | Se esperaba; quedó verde una vez hecho el bootstrap | El orden importa: **primero el bootstrap**, después el pipeline (el huevo y la gallina del state y del OIDC). |
| Riesgo de errores "API not enabled" en el bootstrap | En un proyecto nuevo, Terraform puede usar una API antes de que termine de habilitarse | Se habilitaron antes con `gcloud services enable` las APIs base (resourcemanager, serviceusage, iam, storage, billingbudgets) | Prevenir carreras de dependencias en el primer apply. |
| El `destroy` quedó en cola (`pending`) y no arrancaba | Un `deploy` disparado por un push de documentación seguía esperando aprobación, y los dos comparten `concurrency: deploy-dev` (a propósito: nunca dos procesos sobre el mismo state) | Se rechazó (*Reject*) ese deploy y el destroy siguió. Se agregó `paths-ignore` para que los cambios de docs no disparen deploys | La concurrencia protege el state, pero una aprobación pendiente bloquea todo lo que viene detrás: no dejar corridas esperando. |
| Primer intento de cargar el webhook: "Secret Payload cannot be empty" | Se apretó Enter sin pegar la URL | Se repitió | El secreto se carga con `read -s` para que no quede en pantalla ni en el historial. |

### Primera ejecución del job (`run-job` #1)

| Problema | Causa | Solución | Aprendizaje |
|---|---|---|---|
| `run-job` terminó en rojo después de ~4 min | El análisis, el reporte y la métrica funcionaron, pero **Discord respondió 403 Forbidden**: rechaza pedidos sin un *User-Agent* propio (Python manda uno genérico). Como el error no estaba atajado, el programa salió con `exit(1)` y Cloud Run lo reintentó (`max_retries = 1`) con el mismo resultado | Se agregó un `User-Agent` propio y el aviso pasó a ser **no bloqueante**: si falla, queda un WARNING y el job termina bien (commit `d5aea66`), con un test que lo cubre | Un paso **secundario** (avisar) no debe tirar abajo el principal (analizar) que ya terminó bien. Las integraciones con terceros fallan de formas inesperadas: probarlas temprano. |
| Los logs de GitHub no se podían leer sin iniciar sesión | GitHub pide autenticación para descargar logs, aunque el repo sea público | Se leyó el error en **Cloud Logging** | Los **logs estructurados en JSON** (`severity`, `message`, `error`) permitieron ver en un minuto hasta dónde llegó el job ("Opiniones leídas" → "Análisis terminado" → error en el webhook). |

### Resultados del análisis

- Primera corrida real (17/11): **200 opiniones → 69 % positivas, 20 % negativas, 11 % neutras**.
- El generador de datos apuntaba a ~55 / 25 / 20. La diferencia viene de frases que una persona leería como
  neutras y la API puntuó **levemente positivas**: "Probé … ayer en la oficina" (0,30), "está en promoción esta
  semana" (0,50), "sacó un sabor nuevo" (0,70).
- Corrida de crisis (`opiniones_crisis.csv`, 40 opiniones armadas con ~80 % negativas): la API dio **90 % negativas** y disparó la alerta.
- Aprendizaje: el **umbral de clasificación** (±0,25) es una decisión de negocio, no un detalle técnico. Con
  ±0,35 varias de esas pasarían a neutras. Es el motivo para comparar con un segundo modelo (VADER,
  `scripts/comparar_modelos.py`).

### Comparación con VADER (extra)

- Primera comparación: **85 %** de coincidencia. VADER marcaba como negativa "…me cambiaron un pack sin problema":
  en inglés ***sin*** es "pecado" (−2,6). Un **falso amigo** entre idiomas.
- Corregido en el léxico → **91 %**. Las 18 diferencias restantes son frases neutras que la API puntuó levemente
  positivas. Detalle en [comparacion-modelos.md](comparacion-modelos.md).
- Aprendizaje: un modelo pensado para otro idioma puede fallar en silencio; hay que mirar los ejemplos, no solo el %.

### Durante el desarrollo (antes de la nube)

| Problema | Solución |
|---|---|
| El primer PR falló en Checkov con una regla nueva (CKV_GCP_125) que localmente pasaba | La acción de Checkov baja la última versión (3.4.5) y localmente se usaba la 3.2; la regla nueva pide restringir el OIDC por `assertion.sub`, y nosotros restringimos por `assertion.repository` | Justificado en el código (es la forma que recomienda Google) y documentado en seguridad.md. Aprendizaje: fijar la versión del escáner en CI para que una actualización no rompa el pipeline sin aviso. |
| El plan comentado en el PR mostraba los mails del equipo (repo público) | Los canales de alerta llevan el mail como etiqueta y el plan imprime todos los valores | `alert_emails` pasó a `sensitive = true` (el plan muestra `(sensitive value)`) y se borraron los comentarios viejos | El plan es público si el repo lo es: los datos personales también van como sensibles, no solo las contraseñas. |
| En un PR, `tflint --init` falló con *403 API rate limit exceeded* | El plugin de Google se descarga de GitHub sin token, y el límite anónimo es por IP (los runners son compartidos) | Se le pasa `GITHUB_TOKEN` al paso de tflint | Las herramientas que bajan cosas de GitHub en CI necesitan el token del workflow. |
| tflint marcó módulos sin `required_version` ni `required_providers` | Un `versions.tf` en cada módulo |
| Checkov: 11 hallazgos | Revisados uno por uno y justificados en el código; Checkov pasó a bloquear el merge (ver [seguridad.md](seguridad.md)) |
| Un regex de validación de mails rompía el HCL (`\s` no es un escape válido) | Escapar como `\\s` |
| La app llegó a 151 líneas (límite de la consigna: 150) | Se compactó un comentario |
| Instalar dependencias de prueba en el Python global cambió versiones de otras librerías | Se revirtió. Aprendizaje: usar un entorno virtual (`python -m venv .venv`) |
| El diagrama de componentes salía ilegible | Se rehízo más compacto, con la información dentro de cada componente |

## Pendientes conocidos

- ~~Avisos de GitHub "Node.js 20 is deprecated"~~: resuelto en el PR `actualizar-acciones-node24` (checkout v7,
  setup-python v7, github-script v9, auth v3, setup-gcloud v3, setup-terraform v4, setup-tflint v6, gitleaks v3,
  infracost v5; todas verificadas con runtime Node 24).
- `ubuntu-latest` pasa a Ubuntu 26: sin impacto esperado, pero fijar la versión daría builds más predecibles.

# Runbook

## Operación diaria

- El job corre solo a las 09:00 (Montevideo). Para correrlo a mano: Actions → **run-job**, o
  ```bash
  gcloud run jobs execute zenithzest-job --region us-central1 --wait
  ```
- Reporte del día:
  ```bash
  gcloud storage ls gs://<proyecto>-zz-dev-reportes/$(date +%F)/
  gcloud storage cat gs://<proyecto>-zz-dev-reportes/<fecha>/reporte-<hora>.csv | head
  ```
- Dashboard: `terraform output dashboard_url` (en `infra/envs/dev`).

## Alerta "opiniones negativas > 40 %"

1. Abrir el reporte HTML del día y mirar qué productos y canales concentran lo negativo.
2. Avisar a negocio (el resumen ya llegó al webhook).
3. La alerta se cierra sola a las 24 h o cuando una corrida baja del umbral.

## Alerta "ejecución del job fallida"

| Síntoma en los logs | Causa probable | Qué hacer |
|---|---|---|
| `403` en `storage` | Falta el permiso del job sobre el bucket | Revisar `iam.tf`; `terraform plan` |
| `404 ... opiniones.csv` | El objeto no está en el bucket de entrada | Re-aplicar Terraform (sube los CSV) |
| `PERMISSION_DENIED` en `language` | API no habilitada o falta `serviceUsageConsumer` | `gcloud services list --enabled`; revisar `iam.tf` |
| `RESOURCE_EXHAUSTED` / cuota | Muchas llamadas por minuto | Bajar `max_opinions` |
| `WARNING Sin webhook` | El secreto no tiene valor | Cargarlo (abajo); no hace fallar el job |
| La imagen no arranca | Tag inexistente | Ver el último `deploy.yml`; redeploy |

Logs:
```bash
gcloud logging read 'resource.type="cloud_run_job" AND resource.labels.job_name="zenithzest-job" AND severity>=WARNING' --limit 20 --freshness 1d
```

## Cargar o rotar el secreto del webhook

```bash
printf '%s' "https://discord.com/api/webhooks/..." | gcloud secrets versions add zenithzest-webhook --data-file=-
gcloud secrets versions list zenithzest-webhook
gcloud secrets versions disable <versión-vieja> --secret zenithzest-webhook
```

## Rollback

La imagen se despliega por SHA. Para volver a la versión anterior: revertir el commit en `main` (`git revert`) y
dejar que `deploy.yml` aplique; o, de emergencia, re-ejecutar el `deploy.yml` del commit anterior desde Actions.

## Destruir

Actions → **destroy** → `destruir`. Verificar que el último paso diga `OK: state vacío` y guardar la captura.
Revisar en la consola de facturación que no quede nada con costo.

## Checklist antes de la demo (anexo 7 del enunciado)

- [ ] Alerta de presupuesto activa y llega a los dos.
- [ ] Todos los recursos con `project`, `team`, `env`, `owner`.
- [ ] Logs a 7 días y TTL en los buckets.
- [ ] `destroy.yml` probado al menos una vez.
- [ ] Desplegar el día anterior, verificar, destruir; volver a desplegar antes de la clase.
- [ ] Después de la demo: destroy, captura del state vacío y de la facturación del mes.

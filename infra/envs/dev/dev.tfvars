# Valores NO sensibles del entorno dev. project_id, image y alert_emails los pasa el pipeline
# desde las variables del repositorio (o -var al correr a mano).
region                 = "us-central1"
env                    = "dev"
input_object           = "opiniones.csv"
max_opinions           = 200
schedule               = "0 9 * * *"
scheduler_paused       = false
negative_threshold_pct = 40

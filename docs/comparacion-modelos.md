# Comparación: Natural Language API vs. VADER (modelo local)

Extra del enunciado: "comparar el resultado de la API con un modelo local simple (VADER/TextBlob)".

## Cómo se hizo

- **Datos:** el reporte de la corrida real del 17/11 (`run-job` #2), con las 200 opiniones de `data/opiniones.csv`
  y el puntaje que les dio la API (el reporte CSV que el job dejó en el bucket de reportes).
- **Modelo local:** VADER (`vaderSentiment` 3.3.2) con un léxico básico en español agregado (≈60 palabras) y las
  negaciones del español (`no`, `ni`, `jamás`, `tampoco`, `sin`). Umbral estándar de VADER: compound ≥ 0,05
  positivo, ≤ −0,05 negativo.
- **Script:** `python scripts/comparar_modelos.py reporte.csv` (el reporte CSV bajado del bucket).
  Corre en la laptop, sin costo.

## Resultado

**Coincidencia VADER vs. API: 91,0 %** (182 de 200).

| Sentimiento | API | VADER |
|---|---|---|
| positivo | 69,0 % | 60,0 % |
| negativo | 20,0 % | 20,0 % |
| neutro | 11,0 % | 20,0 % |

Matriz de confusión (filas = API, columnas = VADER):

| API \ VADER | positivo | negativo | neutro |
|---|---|---|---|
| positivo | 120 | 0 | 18 |
| negativo | 0 | 40 | 0 |
| neutro | 0 | 0 | 22 |

- Los **negativos coinciden al 100 %** (40 de 40): las quejas son claras para los dos modelos.
- Las **18 diferencias** son frases que la API puntuó **levemente positivas** y VADER deja en neutro:
  - "Probé ZenithZest Ginger ayer en la oficina" → API 0,30 · VADER 0,00
  - "ZenithZest sacó un sabor nuevo de ZenithZest Citrus" → API 0,70 · VADER 0,00

  En esos casos VADER se parece más a lo que leería una persona, que vería esas frases como informativas.

## Hallazgo: el "falso amigo"

La primera comparación dio **85 %**: VADER marcaba como **negativa** la frase muy positiva
"Gran atención al cliente de ZenithZest, me cambiaron un pack sin problema" (−0,27).

Causa: el léxico de VADER es en inglés, y en inglés ***sin*** significa **pecado** (−2,6). Leyó "sin problema"
como algo muy negativo. Al indicarle que en español "sin" es neutro (y una negación), la coincidencia subió a
**91 %** y desaparecieron los falsos negativos (positivo → negativo pasó de 12 a 0).

## Conclusiones

1. Para esta tarea, un modelo local adaptado coincide con la API en 9 de cada 10 opiniones, **sin costo por uso**.
2. La API entiende el idioma sin ajustes; VADER necesita un léxico en español y cuidar los falsos amigos. Un modelo
   en otro idioma puede fallar de forma silenciosa.
3. Las diferencias están en los neutros, que es donde más pesa el **umbral** (±0,25 en el job): clasificar es una
   decisión de negocio.
4. Palanca de FinOps (ver [finops.md](finops.md)): usar el modelo local para el grueso de las opiniones y la API
   solo para las dudosas (puntaje cerca de 0) bajaría mucho el costo a escala.

Limitación: el dataset es sintético (24 frases que se repiten con distintos productos); con opiniones reales la
coincidencia sería menor.

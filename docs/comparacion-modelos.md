# Comparación: Natural Language API vs. VADER (local)

Opiniones analizadas: 200

**Coincidencia VADER vs. API: 91.0 %** (182 de 200)

| Sentimiento | API | VADER |
|---|---|---|
| positivo | 69.0 % | 60.0 % |
| negativo | 20.0 % | 20.0 % |
| neutro | 11.0 % | 20.0 % |

Matriz de confusión (filas = API, columnas = VADER):

| API \ VADER | positivo | negativo | neutro |
|---|---|---|---|
| positivo | 120 | 0 | 18 |
| negativo | 0 | 40 | 0 |
| neutro | 0 | 0 | 22 |

Ejemplos donde no coinciden:

- "Probé ZenithZest Ginger ayer en la oficina" → API: positivo (0.30) · VADER: neutro (0.00)
- "ZenithZest sacó un sabor nuevo de ZenithZest Citrus" → API: positivo (0.70) · VADER: neutro (0.00)

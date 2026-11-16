# Etapa 1: instalar dependencias
FROM python:3.12-slim AS build
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/deps -r requirements.txt

# Etapa 2: imagen final mínima, sin herramientas de build ni secretos
FROM python:3.12-slim
WORKDIR /app
COPY --from=build /deps /usr/local
COPY main.py .
USER 10001
ENV PYTHONUNBUFFERED=1
HEALTHCHECK NONE
CMD ["python", "main.py"]

FROM python:3.12-alpine
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

WORKDIR /app

# # Copiamos los archivos de configuración primero para aprovechar el caché
# COPY pyproject.toml uv.lock /app/
# Añadimos README.md a la lista de archivos iniciales
COPY pyproject.toml uv.lock README.md /app/

# CORRECCIÓN CLAVE: Copiamos la carpeta src completa a /app/src
# No pongas el "/" al final de src si quieres que se copie la carpeta entera
COPY src /app/src

# Instalamos dependencias
RUN uv sync --no-dev --compile-bytecode

# Ajustamos la ruta en el CMD para que apunte a la nueva ubicación
CMD ["uv", "run", "--no-dev", "fastapi", "run", "src/blazing/main.py", "--port", "80"]
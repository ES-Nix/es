FROM python:3.11-slim

WORKDIR /code

COPY poetry.lock .
COPY pyproject.toml .
RUN pip install --no-cache-dir poetry \
    && poetry config virtualenvs.create false \
    && poetry install --no-interaction --no-ansi --no-root \
    && pip uninstall -y poetry

# Copy the app folder into the container
COPY . .

# Set Python path so "app" is importable
ENV PYTHONPATH=/code

# Start FastAPI app
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]



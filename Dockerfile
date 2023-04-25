FROM python:3.11-slim

ENV POETRY_VERSION=1.4.0

RUN pip install --upgrade pip

# Set working directory. Install poetry, install deps, copy code, run GUNICORN
WORKDIR /app
RUN pip install "poetry==$POETRY_VERSION" 
RUN poetry config virtualenvs.create false

COPY poetry.lock pyproject.toml ./
RUN poetry install --no-interaction --no-ansi

COPY . .

CMD ["gunicorn", "wsgi:app", "-w", "4", "-b", "0.0.0.0:8080" ] 
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y build-essential libpq-dev postgresql-client && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY ./app .
COPY ./sql/init_schema.sql ./init.sql
COPY entrypoint.sh ./entrypoint.sh

RUN chmod +x entrypoint.sh
EXPOSE 8000

CMD ["/app/entrypoint.sh"]
# CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
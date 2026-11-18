FROM postgres:15-alpine
WORKDIR /migration

COPY 01-init.sql .
COPY 02-import.sql .
COPY csv_data/ ./csv_data/
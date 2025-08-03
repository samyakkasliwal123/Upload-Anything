#!/usr/bin/env bash

set -e
[ -r "/shared/secrets" ] && . "/shared/secrets"
DEFAULT_MODULE_NAME=doc_processing_service.config.asgi:application

DEFAULT_GUNICORN_CONF=../gunicorn_config.py
export GUNICORN_CONF=${GUNICORN_CONF:-$DEFAULT_GUNICORN_CONF}
export WORKER_CLASS=${WORKER_CLASS:-"uvicorn.workers.UvicornWorker"}

python manage.py migrate
python manage.py collectstatic --noinput
python manage.py add_admin_user

newrelic-admin run-program python -m gunicorn --forwarded-allow-ips "*" -k "$WORKER_CLASS" -c "$GUNICORN_CONF" "$DEFAULT_MODULE_NAME"


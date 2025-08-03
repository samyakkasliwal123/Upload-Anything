#!/usr/bin/env bash

set -e
[ -r "/shared/secrets" ] && . "/shared/secrets"
python manage.py migrate
newrelic-admin run-program python manage.py start_temporal_worker
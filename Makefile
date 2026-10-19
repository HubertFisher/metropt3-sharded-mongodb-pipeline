PYTHON ?= $(if $(wildcard .venv/bin/python),.venv/bin/python,python3)
DATASET_URL ?= https://archive.ics.uci.edu/static/public/791/metropt+3+dataset.zip
DATASET_PATH ?= data/metropt+3+dataset.zip

.PHONY: install format lint test check compose-config download-data cluster-up cluster-status cluster-verify cluster-down ingest

install:
	$(PYTHON) -m pip install -e '.[dev]'

format:
	$(PYTHON) -m ruff format .
	$(PYTHON) -m ruff check --fix .

lint:
	$(PYTHON) -m ruff format --check .
	$(PYTHON) -m ruff check .
	$(PYTHON) -m mypy src tests

test:
	$(PYTHON) -m pytest --cov --cov-report=term-missing

compose-config:
	docker compose config --quiet

download-data:
	@mkdir -p $(dir $(DATASET_PATH))
	@if [ -f "$(DATASET_PATH)" ]; then \
		echo "Dataset already present at $(DATASET_PATH)"; \
	else \
		echo "Downloading MetroPT-3 dataset from UCI repository..."; \
		curl -fL "$(DATASET_URL)" -o "$(DATASET_PATH)"; \
	fi

cluster-up:
	docker compose up -d --wait

cluster-status:
	docker compose exec -T mongos mongosh --quiet --file /scripts/inspect-cluster.js

cluster-verify:
	docker compose exec -T mongos mongosh --quiet --file /scripts/verify-cluster.js

cluster-down:
	docker compose down

ingest:
	docker compose --profile ingest run --build --rm ingest

check: lint test compose-config

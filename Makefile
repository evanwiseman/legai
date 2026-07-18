.PHONY: help clean

DIST ?= dist
CHECK = strict_python tests packages/example_lib

help:  ## Show available make targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-14s %s\n", $$1, $$2}'

clean:  ## Remove caches, Skylos data, build artifacts, and test/coverage outputs
	find . -type d -name __pycache__ -not -path './.venv/*' -exec rm -rf {} +
	find . \( -path './.venv' -o -path './.git' \) -prune -o -type f \( -name '*.pyc' -o -name '*.pyo' \) -print | while IFS= read -r f; do rm -f "$$f"; done
	find . \( -path './.venv' -o -path './.git' \) -prune -o -type d -name '*.egg-info' -print | while IFS= read -r d; do rm -rf "$$d"; done
	rm -rf \
		.skylos \
		.pytest_cache \
		.ruff_cache \
		.pyright_cache \
		.pytest_results \
		.coverage \
		htmlcov \
		coverage.xml \
		junit.xml \
		build \
		"$(DIST)" \
		wheels \
		.eggs

lock:  ## Refresh uv.lock
	uv lock

install: lock  ## Install project + dev tools
	uv sync --extra dev

run:  ## Run the application
	uv run main

format:  ## Ruff format + fixes
	uv run ruff format $(CHECK)
	uv run ruff check --fix $(CHECK)

lint:  ## Ruff
	uv run ruff check $(CHECK)

typecheck:  ## Type-check with basedpyright
	uv run basedpyright $(CHECK)

skylos:  ## Skylos (dead code, secrets, quality)
	uv run skylos --no-upload $(CHECK)

test:  ## Pytest (coverage and options from pyproject)
	uv run pytest tests

prek:  ## Fast local hooks (format + lint + types)
	uv run prek auto-update
	uv run prek run --all-files

check: format lint typecheck skylos test  ## Local quality pipeline

build: lock  ## Wheels + sdists for app and every workspace member
	rm -rf "$(DIST)"
	mkdir -p "$(DIST)"
	uv build --all-packages -o $(DIST)

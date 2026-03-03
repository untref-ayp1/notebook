# Variables
DC            = docker compose
PROJECT_NAME  = ijava-course
CONTAINER     = ijava-notebook
PORT          = 8888
NOTEBOOK_URL  = http://localhost:$(PORT)

.PHONY: help check start stop restart logs shell status clean open

help: ## Muestra este menú de ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# ─── Verificación del entorno ────────────────────────────────────────────────

check: ## Verifica que tenés todo lo necesario instalado
	@echo "🔍 Verificando dependencias...\n"

	@# Docker
	@if command -v docker > /dev/null 2>&1; then \
		echo "✅ Docker:         $$(docker --version)"; \
	else \
		echo "❌ Docker:         NO encontrado — instalá desde https://docs.docker.com/get-docker/"; \
	fi

	@# Docker Compose
	@if docker compose version > /dev/null 2>&1; then \
		echo "✅ Docker Compose: $$(docker compose version)"; \
	else \
		echo "❌ Docker Compose: NO encontrado (requiere Docker Desktop o plugin v2)"; \
	fi

	@# Docker daemon corriendo
	@if docker info > /dev/null 2>&1; then \
		echo "✅ Docker daemon:  corriendo"; \
	else \
		echo "❌ Docker daemon:  NO está corriendo — abrí Docker Desktop"; \
	fi

	@# curl (para healthcheck local)
	@if command -v curl > /dev/null 2>&1; then \
		echo "✅ curl:           $$(curl --version | head -1)"; \
	else \
		echo "⚠️  curl:           NO encontrado (opcional, usado por make open)"; \
	fi

	@# Carpeta notebooks
	@if [ -d "./notebooks" ]; then \
		echo "✅ ./notebooks:    existe"; \
	else \
		echo "⚠️  ./notebooks:    no existe — se creará al hacer make start"; \
	fi

	@# Archivo .env
	@if [ -f ".env" ]; then \
		echo "✅ .env:            existe"; \
	else \
		echo "⚠️  .env:            no existe — usando token por defecto (tatu)"; \
	fi

	@echo "\n🏁 Verificación completa."

# ─── Ciclo de vida ───────────────────────────────────────────────────────────

start: ## Levanta el contenedor y espera a que esté healthy
	@mkdir -p notebooks
	$(DC) up -d
	@echo "⏳ Esperando a que el notebook esté listo..."
	@while [ "$$(docker inspect --format='{{.State.Health.Status}}' $(CONTAINER) 2>/dev/null)" != "healthy" ]; do \
		sleep 2; \
		printf "."; \
	done
	@echo "\n---------------------------------------------------"
	@echo "🚀 Notebook listo en: $(NOTEBOOK_URL)/tree/work"
	@echo "🔑 Token:             $$(grep -s JUPYTER_TOKEN .env | cut -d= -f2 || echo tatu)"
	@echo "---------------------------------------------------"

stop: ## Detiene los contenedores
	$(DC) stop
	@echo "⏹️  Contenedor detenido."

restart: ## Reinicia el servicio
	$(DC) restart
	@echo "🔄 Reiniciando..."

open: ## Abre el notebook en el browser (Mac/Linux)
	@echo "🌐 Abriendo $(NOTEBOOK_URL) ..."
	@open $(NOTEBOOK_URL)/tree/work 2>/dev/null || xdg-open $(NOTEBOOK_URL)/tree/work 2>/dev/null || \
		echo "No pude abrir el browser — entrá manualmente a $(NOTEBOOK_URL)"

# ─── Observabilidad ──────────────────────────────────────────────────────────

logs: ## Muestra los logs en tiempo real
	$(DC) logs -f

status: ## Muestra el estado y health del contenedor
	@docker ps --filter "name=$(CONTAINER)" --format \
		"table {{.Names}}\t{{.Status}}\t{{.Ports}}"

shell: ## Entra a la terminal del contenedor
	docker exec -it $(CONTAINER) /bin/bash

# ─── Limpieza ────────────────────────────────────────────────────────────────

clean: ## Detiene y elimina contenedores y redes (NO borra ./notebooks)
	$(DC) down
	@echo "🧹 Entorno limpiado. Tus notebooks en ./notebooks están intactos."

clean-all: ## Como clean pero también elimina volúmenes anónimos
	$(DC) down -v
	@echo "🧹 Entorno y volúmenes eliminados."
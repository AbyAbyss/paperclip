# Convenience targets for local development. Run `make help` to list them.
# Requires Node.js >= 24.11 (pnpm is provided via corepack).

export COREPACK_ENABLE_DOWNLOAD_PROMPT := 0
PNPM ?= corepack pnpm

.DEFAULT_GOAL := help
.PHONY: help check-node setup install start dev once server stop list build typecheck test db-migrate clean onboard uninstall purge

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-12s %s\n", $$1, $$2}'

check-node:
	@node -e "const [a,b]=process.versions.node.split('.').map(Number); if (a<24||(a===24&&b<11)) { console.error('Node.js >= 24.11 required, found '+process.versions.node); process.exit(1) }"

setup: check-node ## Enable pnpm via corepack and install dependencies
	corepack enable 2>/dev/null || true
	$(PNPM) install

install: setup ## Alias for setup

node_modules: package.json pnpm-lock.yaml
	@$(MAKE) setup
	@touch node_modules

start: node_modules ## Install deps if needed, then run UI + API at http://localhost:3100
	$(PNPM) dev

dev: start ## Alias for start

once: node_modules ## Run UI + API without file watching
	$(PNPM) dev:once

server: node_modules ## Run API server only
	$(PNPM) dev:server

stop: ## Stop managed dev services
	$(PNPM) dev:stop

list: ## List managed dev services
	$(PNPM) dev:list

build: node_modules ## Build all packages
	$(PNPM) build

typecheck: node_modules ## Type-check all packages
	$(PNPM) typecheck

test: node_modules ## Run the default Vitest suite
	$(PNPM) test

db-migrate: node_modules ## Apply database migrations
	$(PNPM) db:migrate

clean: ## Remove node_modules (re-run `make setup` afterwards)
	rm -rf node_modules

PAPERCLIP_HOME ?= $(HOME)/.paperclip

onboard: check-node ## Install the Paperclip CLI + background service (npx paperclipai onboard)
	npx --yes paperclipai@latest onboard --yes

uninstall: ## Remove the background service, managed CLI, shim and PATH lines (keeps data)
	@if command -v paperclipai >/dev/null 2>&1; then paperclipai uninstall; \
	elif [ -x "$(HOME)/.local/bin/paperclipai" ]; then "$(HOME)/.local/bin/paperclipai" uninstall; \
	else echo "paperclipai CLI not found; nothing to uninstall."; fi

purge: uninstall ## uninstall + DELETE ALL DATA in ~/.paperclip (asks for confirmation)
	@printf "This permanently deletes $(PAPERCLIP_HOME) (company, agents, database, secrets, backups). Type 'yes' to continue: "; \
	read ans; if [ "$$ans" = "yes" ]; then rm -rf "$(PAPERCLIP_HOME)" && echo "Deleted $(PAPERCLIP_HOME)."; else echo "Aborted; data kept."; fi

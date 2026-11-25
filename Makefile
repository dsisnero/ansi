.PHONY: install update tools build format lint test parity parity-refresh parity-reconcile clean sidecars

# Prefer the ameba built from the installed shard (`make tools`), and fall back
# to a system-wide install.
AMEBA ?= $(shell if [ -x bin/ameba ]; then echo ./bin/ameba; else echo ameba; fi)

# Parity checks come from the installed cross-language-crystal-parity skill
# (see AGENTS.md "Parity tooling"). The scripts are invoked in place, never
# copied into this repo, and tree-sitter mode must resolve a verified toolchain.
PARITY_SKILL ?= $(HOME)/.config/opencode/skills/cross-language-crystal-parity
PARITY_LANGUAGE ?= go
PARITY_SOURCE ?= x/ansi
PARITY_INVENTORY := plans/inventory/$(PARITY_LANGUAGE)_port_inventory.tsv
PARITY_SNAPSHOTS := plans/inventory/$(PARITY_LANGUAGE)_source_parity.tsv plans/inventory/$(PARITY_LANGUAGE)_test_parity.tsv
PARITY_ENV := PORT_PARSER=tree-sitter

sidecars:
	@find . -name '._*' -not -path './.git/*' -delete
	@find .git -name '._*' -delete

install:
	shards install

update:
	shards update

# Builds the lint tool from the installed ameba shard so CI does not depend on
# a system-wide ameba.
tools: sidecars
	@mkdir -p bin
	crystal build lib/ameba/src/cli.cr -o bin/ameba

build: sidecars
	crystal build --no-codegen src/ansi.cr

format: sidecars
	crystal tool format --check src spec

lint: sidecars
	$(AMEBA) --fix src spec
	$(AMEBA) src spec

test: sidecars
	crystal spec

# Read-only drift checks: validates the curated ledger and both generated
# snapshots against the pinned upstream checkout. Safe to run continuously.
parity: sidecars
	@test -x "$(PARITY_SKILL)/scripts/check_port_inventory.sh" || { \
	  echo "parity: install the cross-language-crystal-parity skill or set PARITY_SKILL"; exit 1; }
	$(PARITY_ENV) "$(PARITY_SKILL)/scripts/check_port_inventory.sh" . "$(PARITY_INVENTORY)" "$(PARITY_SOURCE)" "$(PARITY_LANGUAGE)"
	$(PARITY_ENV) "$(PARITY_SKILL)/scripts/check_source_parity.sh" . "plans/inventory/$(PARITY_LANGUAGE)_source_parity.tsv" "$(PARITY_SOURCE)" "$(PARITY_LANGUAGE)"
	$(PARITY_ENV) "$(PARITY_SKILL)/scripts/check_test_parity.sh" . "plans/inventory/$(PARITY_LANGUAGE)_test_parity.tsv" "$(PARITY_SOURCE)" "$(PARITY_LANGUAGE)"

# Intentional upstream bump only: re-derives the source/test snapshots. It never
# touches the curated port inventory.
parity-refresh: sidecars
	@test -x "$(PARITY_SKILL)/scripts/ensure_parity_plan.sh" || { \
	  echo "parity-refresh: install the cross-language-crystal-parity skill or set PARITY_SKILL"; exit 1; }
	$(PARITY_ENV) "$(PARITY_SKILL)/scripts/ensure_parity_plan.sh" . "$(PARITY_SOURCE)" "$(PARITY_LANGUAGE)" tree-sitter 1

# Disposable reconciliation bundle (plans/generated/ is gitignored): per-entity
# maps, arity drift, and ledger-vs-structure divergences.
parity-reconcile: sidecars
	@test -x "$(PARITY_SKILL)/scripts/reconcile_parity.sh" || { \
	  echo "parity-reconcile: install the cross-language-crystal-parity skill or set PARITY_SKILL"; exit 1; }
	$(PARITY_ENV) "$(PARITY_SKILL)/scripts/reconcile_parity.sh" . "$(PARITY_SOURCE)" "$(PARITY_LANGUAGE)" src plans/parity_rules.yml

clean: sidecars
	rm -rf ./temp/*

.PHONY: install update tools build format lint test clean sidecars

# Prefer the ameba built from the installed shard (`make tools`), and fall back
# to a system-wide install.
AMEBA ?= $(shell if [ -x bin/ameba ]; then echo ./bin/ameba; else echo ameba; fi)

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

clean: sidecars
	rm -rf ./temp/*

.PHONY: install update build format lint test clean sidecars

sidecars:
	@find . -name '._*' -not -path './.git/*' -delete
	@find .git -name '._*' -delete

install:
	shards install

update:
	shards update

build: sidecars
	crystal build --no-codegen src/ansi.cr

format: sidecars
	crystal tool format --check src spec

lint: sidecars
	ameba --fix src spec
	ameba src spec

test: sidecars
	crystal spec

clean: sidecars
	rm -rf ./temp/*

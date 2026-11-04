SHELL := /bin/sh
PREFIX ?= $(HOME)/.local
SCRIPTS := bin/kirisute lib/*.sh scripts/*.sh .github/scripts/*.sh test/*.sh test/*.bash test/*.bats test/bin/gum screens/*.sh

.PHONY: help fmt lint test test-all test-linux coverage check screens install

help:
	@echo "targets:"
	@echo "  fmt         format every script with shfmt -i 2"
	@echo "  lint        shfmt, shellcheck -o all and mandoc at zero findings"
	@echo "  test        bats suites under the system sh"
	@echo "  test-all    bats suites under every installed shell"
	@echo "  test-linux  the same suites in an Ubuntu container"
	@echo "  coverage    bashcov on this Mac and in the Ubuntu container, merged, gate 100%"
	@echo "  check       lint and test"
	@echo "  screens     record the README screens from the real tool with VHS, on macOS"
	@echo "  install     install the tool, man page and completions under PREFIX (default ~/.local)"

fmt:
	shfmt -i 2 -w $(SCRIPTS)

lint:
	shfmt -i 2 -d $(SCRIPTS)
	shellcheck -x -s sh -o all bin/kirisute lib/*.sh scripts/*.sh .github/scripts/*.sh test/call.sh test/run-matrix.sh test/linux-container.sh test/bin/gum screens/*.sh
	sh scripts/check-names.sh
	shellcheck -x -o all test/*.bash test/*.bats
	shellcheck -s bash -o all completions/kirisute.bash
	mandoc -T lint man/kirisute.1

test:
	KIRISUTE_TEST_SHELLS=sh sh test/run-matrix.sh

test-all:
	sh test/run-matrix.sh

test-linux:
	sh test/linux-container.sh sh test/run-matrix.sh

coverage:
	sh scripts/coverage.sh 0 && cp -f coverage/.resultset.json coverage-macos.json
	sh test/linux-container.sh sh scripts/linux-coverage.sh
	python3 scripts/coverage-gate.py '/(bin/kirisute|lib/[a-z0-9]+\.sh)\Z' 100 coverage-macos.json coverage-linux.json

screens:
	sh screens/record.sh

check: lint test

install:
	mkdir -p "$(PREFIX)/share/kirisute" "$(PREFIX)/bin" "$(PREFIX)/share/man/man1" "$(PREFIX)/share/bash-completion/completions" "$(PREFIX)/share/zsh/site-functions" "$(PREFIX)/share/fish/vendor_completions.d"
	cp -R bin lib "$(PREFIX)/share/kirisute/"
	cp -f man/kirisute.1 "$(PREFIX)/share/man/man1/kirisute.1"
	cp -f completions/kirisute.bash "$(PREFIX)/share/bash-completion/completions/kirisute"
	cp -f completions/_kirisute "$(PREFIX)/share/zsh/site-functions/_kirisute"
	cp -f completions/kirisute.fish "$(PREFIX)/share/fish/vendor_completions.d/kirisute.fish"
	printf '#!/bin/sh\nexec "%s/share/kirisute/bin/kirisute" "$$@"\n' "$(PREFIX)" > "$(PREFIX)/bin/kirisute"
	chmod 755 "$(PREFIX)/bin/kirisute"

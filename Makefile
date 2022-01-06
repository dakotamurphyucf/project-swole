.DEFAULT_GOAL := all

.PHONY: all
all:
	opam exec -- dune build --root .

.PHONY: build
build:
	opam exec -- dune build --root .

.PHONY: deps
deps: ## Install development dependencies
	opam install -y dune merlin ocamlformat ocaml-lsp-server utop core ppx_jane ppx_log ppx_expect  ppx_bin_prot ppx_csv_conv  ppx_sexp_value ppx_sexp_message ppx_yojson_conv ocamlformat-rpc

.PHONY: create_switch
create_switch:
	opam switch create . 4.12.1 --no-install
	opam repo add janestreet-bleeding https://ocaml.janestreet.com/opam-repository
	opam repo add janestreet-bleeding-external https://github.com/janestreet/opam-repository.git\#external-packages
	opam update
	
.PHONY: switch
switch: create_switch deps ## Create an opam switch and install development dependencies


.PHONY: test
test: ## Run the unit tests
	opam exec -- dune build --root . @runtest

.PHONY: clean
clean: ## Clean build artifacts and other generated files
	opam exec -- dune clean --root .

.PHONY: doc
doc: ## Generate odoc documentation
	opam exec -- dune build --root . @doc

.PHONY: fmt
fmt: ## Format the codebase with ocamlformat
	opam exec -- dune build --root . --auto-promote @fmt


.PHONY: watch
watch: ## Watch for the filesystem and rebuild on every change
	opam exec -- dune build @all -w --terminal-persistence=clear-on-rebuild


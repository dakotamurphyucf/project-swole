# Contributing

## Setup your development environment

You need Opam, you can install it by following
[Opam's documentation](https://opam.ocaml.org/doc/Install.html).

With Opam installed, you can install the dependencies in a new local switch
with:

```bash
make switch
```

Or globally, with:

```bash
make deps
```

Then, build the project with:

```bash
make 
```

### Running Tests

You can run the test compiled with:

```bash
make test
```

This will run  the OCaml tests 

### Format code

To format the code, you can run:

```
make fmt
```

This will format the OCaml source code with `ocamlformat` .


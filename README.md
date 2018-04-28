# Panacea

A code golf language based off Elixir

## [Documentation](https://github.com/okx-code/Panacea/wiki)

## Compilation

To enable debug messages compile with:

    mix escript.build

To disable debug message compile with:

    MIX_ENV=prod mix escript.build

then, to run:

    ./panacea <file>

When running a program, Panacea will read input until it receives an end of input signal regardless of whether the code actually requires input.

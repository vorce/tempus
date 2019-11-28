[![CircleCI](https://circleci.com/gh/vorce/tempus.svg?style=svg)](https://circleci.com/gh/vorce/tempus) [![Dependabot Status](https://api.dependabot.com/badges/status?host=github&repo=vorce/tempus)](https://dependabot.com)

# Tempus

Time and date experiments.

#### I have no plans to continue with this project

## Goals

- Gain better understanding of how `DateTime`, `Date`, `Time` work and how they can be manipulated (together with time zones)
- Approach datetime manipulation from a "property based testing first" mindset to ensure correctness
- Provide some convenience functions that can be handy for Elixir developers

## Available functions

- `shift/2`, `shift/3` - return a new date "shifted" x days or months (backward or forward).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `tempus` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tempus, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/tempus](https://hexdocs.pm/tempus).


defmodule Tempus do
  @moduledoc """
  Functions to manipulate Elixir DateTime data.
  """

  defdelegate shift(datetime, opts), to: Tempus.Shift
  defdelegate shift(datetime, opts, resolver_fn), to: Tempus.Shift
end

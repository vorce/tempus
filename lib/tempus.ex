defmodule Tempus do
  @moduledoc """
  Functions to manipulate Elixir DateTime data.
  """

  @doc """
  `shift` allows you to move a date forward or backwards by some units.
  """
  @spec shift(
          datetime :: DateTime.t(),
          opts :: [{:months | :days, integer}],
          resolver_fn :: Function.t()
        ) :: {:ok, DateTime.t()} | {:error, :invalid_date}
  def shift(datetime, shift_opts, resolver_fn \\ &default_resolver/1)

  def shift(datetime, [days: n], resolver_fn) do
    shifted_erl_date =
      datetime
      |> DateTime.to_date()
      |> Date.to_erl()
      |> :calendar.date_to_gregorian_days()
      |> Kernel.+(n)
      |> :calendar.gregorian_days_to_date()

    erl_time =
      datetime
      |> DateTime.to_time()
      |> Time.to_erl()

    with {:ok, naive} <- NaiveDateTime.from_erl({shifted_erl_date, erl_time}),
         {:ok, shifted} <- DateTime.from_naive(naive, datetime.time_zone, Tzdata.TimeZoneDatabase) do
      {:ok, shifted}
    else
      {:ambiguous, _, _} = amb ->
        {:ok, resolver_fn.(amb)}

      {:gap, _, _} = gap ->
        {:ok, resolver_fn.(gap)}

      other ->
        other
    end
  end

  def shift(datetime, [months: 0], _) do
    {:ok, datetime}
  end

  def shift({:ok, datetime}, opts, resolver_fn), do: shift(datetime, opts, resolver_fn)

  def shift({:ambiguous, _, _} = amb, opts, resolver_fn),
    do: amb |> resolver_fn.() |> shift(opts, resolver_fn)

  def shift({:gap, _, _} = gap, opts, resolver_fn),
    do: gap |> resolver_fn.() |> shift(opts, resolver_fn)

  def shift(datetime, [months: -1], resolver_fn) do
    shift(datetime, [days: -datetime.day], resolver_fn)
  end

  def shift(datetime, [months: 1], resolver_fn) do
    days_in_month = Calendar.ISO.days_in_month(datetime.year, datetime.month)
    remaining_days_in_month = days_in_month - datetime.day
    shift(datetime, [days: remaining_days_in_month + 1], resolver_fn)
  end

  def shift({:ok, datetime}, [months: n], resolver_fn) when n < 1,
    do: shift(datetime, [months: n], resolver_fn)

  def shift(datetime, [months: n], resolver_fn) when n < 1 do
    datetime
    |> shift([months: -1], resolver_fn)
    |> shift([months: n + 1], resolver_fn)
  end

  def shift({:ok, datetime}, [months: n], resolver_fn) when n > 1,
    do: shift(datetime, [months: n], resolver_fn)

  def shift(datetime, [months: n], resolver_fn) when n > 1 do
    datetime
    |> shift([months: 1], resolver_fn)
    |> shift([months: n - 1], resolver_fn)
  end

  defp default_resolver({:ambiguous, _first, second}), do: second
  defp default_resolver({:gap, _just_before, just_after}), do: just_after
end

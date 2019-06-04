defmodule Tempus do
  @moduledoc """
  Documentation for Tempus.
  """

  def shift(datetime, shift_opts, resolver_fn \\ &default_resolver/1)

  def shift(datetime, [days: n], resolver_fn) do
    erl_date =
      datetime
      |> DateTime.to_date()
      |> Date.to_erl()

    shifted_erl_date =
      :calendar.gregorian_days_to_date(:calendar.date_to_gregorian_days(erl_date) + n)

    utc_erl_time = DateTime.to_time(datetime) |> Time.to_erl()
    {:ok, naive} = NaiveDateTime.from_erl({shifted_erl_date, utc_erl_time})

    case DateTime.from_naive(naive, datetime.time_zone, Tzdata.TimeZoneDatabase) do
      {:ok, _} = ok ->
        ok
      other ->
        {:ok, resolver_fn.(other)}
    end
  end

  def shift(datetime, [months: 0], _) do
    {:ok, datetime}
  end

  def shift({:ok, datetime}, [months: 1], resolver_fn), do: shift(datetime, [months: 1], resolver_fn)
  def shift({:ambiguous, _, _} = amb, [months: 1], resolver_fn), do: amb |> resolver_fn.() |> shift([months: 1], resolver_fn)
  def shift({:gap, _, _} = gap, [months: 1], resolver_fn), do: gap |> resolver_fn.() |> shift([months: 1], resolver_fn)

  def shift(datetime, [months: 1], resolver_fn) do
    days_in_month = Calendar.ISO.days_in_month(datetime.year, datetime.month)
    remaining_days_in_month = days_in_month - datetime.day
    shift(datetime, [days: remaining_days_in_month + 1], resolver_fn)
  end

  def shift({:ok, datetime}, [months: n], resolver_fn) when n > 1, do: shift(datetime, [months: n], resolver_fn)

  def shift(datetime, [months: n], resolver_fn) when n > 1 do
    datetime
    |> shift([months: 1], resolver_fn)
    |> shift([months: n - 1], resolver_fn)
  end

  defp default_resolver({:ambiguous, _first, second}), do: second
  defp default_resolver({:gap, _just_before, just_after}), do: just_after
end

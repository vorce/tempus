defmodule Tempus.Shift do
  @moduledoc """
  Shift allows changing a datetime into the future or back in the past based on some units
  """
  @type shift_units ::
          :months | :weeks | :days | :hours | :minutes | :seconds | :milliseconds | :microseconds

  @microseconds_per_millisecond 1_000
  @microseconds_per_second 1_000_000
  @seconds_per_minute 60
  @minutes_per_hour 60
  @days_in_week 7

  @doc "Supported units for shifting"
  @spec units() :: list(shift_units)
  def units(),
    do: [:months, :weeks, :days, :hours, :minutes, :seconds, :milliseconds, :microseconds]

  @doc """
  `shift` allows you to move a DateTime forward or backwards by some units.

  The `resolver_fn` is optional, but can be supplied to resolve ambiguous dates (or gaps) in a custom way.
  The default `resolver_fn` will always pick the second datetime for ambiguous and gap datetimes. See: https://hexdocs.pm/elixir/DateTime.html#from_naive/3
  """
  @spec shift(
          datetime ::
            DateTime.t()
            | {:ok, DateTime.t()}
            | {:ambiguous, DateTime.t(), DateTime.t()}
            | {:gap, DateTime.t(), DateTime.t()},
          opts :: [{shift_units, integer()}],
          resolver_fn :: function()
        ) :: {:ok, DateTime.t()} | {:error, :invalid_date}
  def shift(datetime, shift_opts, resolver_fn \\ &default_resolver/1)

  def shift(datetime, [microseconds: micros], resolver_fn) do
    {current_microseconds, current_precision} = datetime.microsecond

    microseconds_from_zero =
      :calendar.datetime_to_gregorian_seconds({
        {datetime.year, datetime.month, datetime.day},
        {datetime.hour, datetime.minute, datetime.second}
      }) * @microseconds_per_second + current_microseconds + micros

    if microseconds_from_zero < 0 do
      {:error, :shift_to_invalid_date}
    else
      seconds_from_zero = div(microseconds_from_zero, @microseconds_per_second)
      rem_microseconds = rem(microseconds_from_zero, @microseconds_per_second)

      shifted_erl = :calendar.gregorian_seconds_to_datetime(seconds_from_zero)

      with {:ok, naive} <- NaiveDateTime.from_erl(shifted_erl),
           naive <- Map.put(naive, :miscrosecond, {rem_microseconds, current_precision}),
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
  end

  def shift(datetime, [milliseconds: n], resolver_fn),
    do: shift(datetime, [microseconds: n * @microseconds_per_millisecond], resolver_fn)

  def shift(datetime, [seconds: n], resolver_fn),
    do: shift(datetime, [microseconds: n * @microseconds_per_second], resolver_fn)

  def shift(datetime, [minutes: n], resolver_fn),
    do: shift(datetime, [microseconds: n * @seconds_per_minute * @microseconds_per_second], resolver_fn)

  def shift(datetime, [hours: n], resolver_fn),
    do:
      shift(
        datetime,
        [microseconds: n * @minutes_per_hour * @seconds_per_minute * @microseconds_per_second],
        resolver_fn
      )

  def shift(datetime, [weeks: n], resolver_fn), do: shift(datetime, [days: n * @days_in_week], resolver_fn)

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

  def shift({:ambiguous, _, _} = amb, opts, resolver_fn), do: amb |> resolver_fn.() |> shift(opts, resolver_fn)

  def shift({:gap, _, _} = gap, opts, resolver_fn), do: gap |> resolver_fn.() |> shift(opts, resolver_fn)

  def shift(datetime, [months: -1], resolver_fn), do: shift(datetime, [days: -datetime.day], resolver_fn)

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

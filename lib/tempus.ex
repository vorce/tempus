defmodule Tempus do
  @moduledoc """
  Documentation for Tempus.
  """

  def shift(datetime, days: n) do
    erl_date =
      datetime
      |> DateTime.to_date()
      |> Date.to_erl()

    shifted_erl_date =
      :calendar.gregorian_days_to_date(:calendar.date_to_gregorian_days(erl_date) + n)

    utc_erl_time = DateTime.to_time(datetime) |> Time.to_erl()
    {:ok, naive} = NaiveDateTime.from_erl({shifted_erl_date, utc_erl_time})

    DateTime.from_naive(naive, datetime.time_zone, Tzdata.TimeZoneDatabase)
  end

  def shift(datetime, months: 0) do
    {:ok, datetime}
  end

  def shift({:ok, datetime}, months: 1), do: shift(datetime, months: 1)

  def shift(datetime, months: 1) do
    days_in_month = Calendar.ISO.days_in_month(datetime.year, datetime.month)
    remaining_days_in_month = days_in_month - datetime.day
    shift(datetime, days: remaining_days_in_month + 1)
  end

  def shift({:ok, datetime}, months: n) when n > 1, do: shift(datetime, months: n)

  def shift(datetime, months: n) when n > 1 do
    datetime
    |> shift(months: 1)
    |> shift(months: n - 1)
  end
end

defmodule Tempus.ShiftTest do
  use ExUnit.Case
  use ExUnitProperties
  doctest Tempus.Shift

  property "positive shift amount results in a datetime in the future" do
    check all shift_unit <- shift_unit_generator(:coarse),
              time_zone <- time_zone_generator(),
              shift_amount <- StreamData.positive_integer(),
              now <- date_time_generator(),
              max_runs: 1000 do
      {:ok, now_with_tz} = DateTime.shift_zone(now, time_zone, Tzdata.TimeZoneDatabase) |> unambiguate()

      {:ok, shifted} = Tempus.shift(now_with_tz, [{shift_unit, shift_amount}])

      assert DateTime.compare(shifted, now_with_tz) == :gt
    end
  end

  property "negative shift amount results in a datetime in the past" do
    check all shift_unit <- shift_unit_generator(:coarse),
              time_zone <- time_zone_generator(),
              shift_amount <- StreamData.integer(-1000..-1),
              now <- date_time_generator(),
              max_runs: 1000 do
      {:ok, now_with_tz} = DateTime.shift_zone(now, time_zone, Tzdata.TimeZoneDatabase) |> unambiguate()

      {:ok, shifted} = Tempus.shift(now_with_tz, [{shift_unit, shift_amount}])

      assert DateTime.compare(shifted, now_with_tz) == :lt
    end
  end

  property "shifting days gives the same result as shifting by the same amount*24 hours" do
    check all time_zone <- time_zone_generator(),
              shift_amount <- StreamData.integer(),
              now <- date_time_generator(),
              max_runs: 1000 do
      {:ok, now_with_tz} = DateTime.shift_zone(now, time_zone, Tzdata.TimeZoneDatabase) |> unambiguate()

      {:ok, shifted_days} = Tempus.shift(now_with_tz, days: shift_amount)
      {:ok, shifted_hours} = Tempus.shift(now_with_tz, hours: shift_amount * 24)

      assert DateTime.compare(shifted_days, shifted_hours) == :eq
    end
  end

  describe "days" do
    test "negative" do
      date = DateTime.from_naive!(~N[2019-04-30T21:30:00], "Etc/UTC")
      time_zone = "Europe/Helsinki"
      {:ok, date_with_timezone} = DateTime.shift_zone(date, time_zone, Tzdata.TimeZoneDatabase)

      {:ok, shifted_date} = Tempus.shift(date_with_timezone, days: -32)

      assert DateTime.to_iso8601(shifted_date) == "2019-03-30T00:30:00+02:00"
      assert shifted_date.time_zone == time_zone
    end
  end

  describe "months" do
    test "negative" do
      date = DateTime.from_naive!(~N[2019-04-30T21:30:00], "Etc/UTC")
      time_zone = "Europe/Helsinki"
      {:ok, date_with_timezone} = DateTime.shift_zone(date, time_zone, Tzdata.TimeZoneDatabase)

      {:ok, shifted_date} = Tempus.shift(date_with_timezone, months: -6)

      assert DateTime.to_iso8601(shifted_date) == "2018-11-30T00:30:00+02:00"
      assert shifted_date.time_zone == time_zone
    end

    test "helsinki" do
      date = DateTime.from_naive!(~N[2019-04-30T21:30:00], "Etc/UTC")
      time_zone = "Europe/Helsinki"
      {:ok, date_with_timezone} = DateTime.shift_zone(date, time_zone, Tzdata.TimeZoneDatabase)

      {:ok, shifted_date} = Tempus.shift(date_with_timezone, months: 1)

      assert DateTime.to_iso8601(shifted_date) == "2019-06-01T00:30:00+03:00"
      assert shifted_date.time_zone == time_zone
    end
  end

  describe "hours" do
    test "positive" do
      date = DateTime.from_naive!(~N[2019-04-30T21:30:00], "Etc/UTC")
      time_zone = "Europe/Berlin"
      {:ok, date_with_timezone} = DateTime.shift_zone(date, time_zone, Tzdata.TimeZoneDatabase)

      {:ok, shifted_date} = Tempus.shift(date_with_timezone, hours: 3)

      assert DateTime.to_iso8601(shifted_date) == "2019-05-01T02:30:00+02:00"
      assert shifted_date.time_zone == time_zone
    end

    test "negative" do
      date = DateTime.from_naive!(~N[2019-04-30T21:30:00], "Etc/UTC")
      time_zone = "Europe/Berlin"
      {:ok, date_with_timezone} = DateTime.shift_zone(date, time_zone, Tzdata.TimeZoneDatabase)

      {:ok, shifted_date} = Tempus.shift(date_with_timezone, hours: -24)

      assert DateTime.to_iso8601(shifted_date) == "2019-04-29T23:30:00+02:00"
      assert shifted_date.time_zone == time_zone
    end
  end

  defp unambiguate({:ok, datetime}), do: {:ok, datetime}
  defp unambiguate({:ambiguous, first, _second}), do: {:ok, first}

  defp date_time_generator() do
    [
      StreamData.integer(2018..2030),
      StreamData.integer(1..12),
      StreamData.integer(1..28),
      StreamData.integer(0..23),
      StreamData.integer(0..59),
      StreamData.integer(0..59)
    ]
    |> StreamData.fixed_list()
    |> StreamData.map(fn [year, month, day, hour, minute, second] ->
      with {:ok, naive} <- NaiveDateTime.from_erl({{year, month, day}, {hour, minute, second}}),
           {:ok, datetime} <- DateTime.from_naive(naive, "Etc/UTC") do
        datetime
      end
    end)
  end

  defp time_zone_generator() do
    StreamData.member_of(Tzdata.zone_list())
  end

  defp shift_unit_generator() do
    StreamData.member_of(Tempus.Shift.units())
  end

  defp shift_unit_generator(:coarse) do
    Tempus.Shift.units()
    |> Enum.reject(fn unit -> unit == :microseconds or unit == :milliseconds end)
    |> StreamData.member_of()
  end
end

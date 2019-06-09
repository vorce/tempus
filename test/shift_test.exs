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
    test "adding 1 day while crossing a DST boundary should not affect time (BST -> GMT)" do
      time_zone = "Europe/London"
      date = DateTime.from_naive!(~N[2012-10-28T00:00:00], time_zone, Tzdata.TimeZoneDatabase)

      {:ok, shifted_date} = Tempus.shift(date, days: 1)

      assert DateTime.to_iso8601(shifted_date) == "2012-10-29T00:00:00+00:00"
      assert shifted_date.time_zone == time_zone
    end

    test "adding 1 day while crossing a DST boundary should not affect time (PDT -> PST)" do
      time_zone = "America/Los_Angeles"
      date = DateTime.from_naive!(~N[2013-11-03T00:00:00], time_zone, Tzdata.TimeZoneDatabase)

      {:ok, shifted_date} = Tempus.shift(date, days: 1)

      assert DateTime.to_iso8601(shifted_date) == "2013-11-04T00:00:00-08:00"
      assert shifted_date.time_zone == time_zone
    end

    test "adding 1 day while crossing a DST boundary should not affect time (PST -> PDT)" do
      date = DateTime.from_naive!(~N[2014-03-09T00:00:00], "America/Los_Angeles", Tzdata.TimeZoneDatabase)

      {:ok, shifted_date} = Tempus.shift(date, days: 1)

      assert DateTime.to_iso8601(shifted_date) == "2014-03-10T00:00:00-07:00"
    end

    test "subtracting 1 day while crossing a DST boundary should not affect time (GMT -> BST)" do
      date = DateTime.from_naive!(~N[2012-10-29T00:00:00], "Europe/London", Tzdata.TimeZoneDatabase)

      {:ok, shifted_date} = Tempus.shift(date, days: -1)

      assert DateTime.to_iso8601(shifted_date) == "2012-10-28T00:00:00+01:00"
    end

    test "subtracting 1 day while crossing a DST boundary should not affect time (PST -> PDT)" do
      date = DateTime.from_naive!(~N[2013-11-04T00:00:00], "America/Los_Angeles", Tzdata.TimeZoneDatabase)

      {:ok, shifted_date} = Tempus.shift(date, days: -1)

      assert DateTime.to_iso8601(shifted_date) == "2013-11-03T00:00:00-07:00"
    end

    test "subtracting 1 day while crossing a DST boundary should not affect time (PDT -> PST)" do
      date = DateTime.from_naive!(~N[2014-03-10T00:00:00], "America/Los_Angeles", Tzdata.TimeZoneDatabase)

      {:ok, shifted_date} = Tempus.shift(date, days: -1)

      assert DateTime.to_iso8601(shifted_date) == "2014-03-09T00:00:00-08:00"
    end

    test "negative" do
      date = DateTime.from_naive!(~N[2019-04-30T21:30:00], "Etc/UTC")
      time_zone = "Europe/Helsinki"
      {:ok, date_with_timezone} = DateTime.shift_zone(date, time_zone, Tzdata.TimeZoneDatabase)

      {:ok, shifted_date} = Tempus.shift(date_with_timezone, days: -32)

      assert DateTime.to_iso8601(shifted_date) == "2019-03-30T00:30:00+02:00"
      assert shifted_date.time_zone == time_zone
    end

    test "going exactly to DST" do
      date = DateTime.from_naive!(~N[2019-05-10 00:00:00], "Etc/UTC")
      time_zone = "Europe/Warsaw"
      {:ok, date_with_timezone} = DateTime.shift_zone(date, time_zone, Tzdata.TimeZoneDatabase)

      {:ok, shifted_date} = Tempus.shift(date_with_timezone, days: -40)
      {:ok, shifted_utc} = DateTime.shift_zone(shifted_date, "Etc/UTC", Tzdata.TimeZoneDatabase)

      assert DateTime.to_iso8601(shifted_utc) == "2019-03-31T01:00:00Z"
    end
  end

  describe "months" do
    test "adding 1 month while crossing a DST boundary should not affect time (PST -> PDT)" do
      date = DateTime.from_naive!(~N[2014-03-09T00:00:00], "America/Los_Angeles", Tzdata.TimeZoneDatabase)

      {:ok, shifted_date} = Tempus.shift(date, months: 1)

      assert DateTime.to_iso8601(shifted_date) == "2014-04-09T00:00:00-07:00"
    end

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

    test "with resolved ambiguity" do
      time_zone = "America/New_York"
      {:ok, date_with_timezone} = DateTime.from_naive(~N[2018-11-04T00:30:00], time_zone, Tzdata.TimeZoneDatabase)

      {:ok, shifted_date} = Tempus.shift(date_with_timezone, hours: 1)
      # 2018-11-04 01:30:00 America/New_York is ambiguous
      # ie it can be either of:
      # 2018-11-04 01:30:00-04:00 EDT America/New_York
      # 2018-11-04 01:30:00-05:00 EST America/New_York
      # The default resolver_fn always takes the second datetime when this happens.

      assert shifted_date.time_zone == time_zone
      assert DateTime.to_iso8601(shifted_date) == "2018-11-04T01:30:00-05:00"
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

defmodule TempusTest do
  use ExUnit.Case
  use ExUnitProperties
  doctest Tempus

  describe "shift" do
    test "negative days" do
      date = DateTime.from_naive!(~N[2019-04-30T21:30:00], "Etc/UTC")
      time_zone = "Europe/Helsinki"
      {:ok, date_with_timezone} = DateTime.shift_zone(date, time_zone, Tzdata.TimeZoneDatabase)

      {:ok, shifted_date} = Tempus.shift(date_with_timezone, days: -32)

      assert DateTime.to_iso8601(shifted_date) == "2019-03-30T00:30:00+02:00"
      assert shifted_date.time_zone == time_zone
    end

    test "negative months" do
      date = DateTime.from_naive!(~N[2019-04-30T21:30:00], "Etc/UTC")
      time_zone = "Europe/Helsinki"
      {:ok, date_with_timezone} = DateTime.shift_zone(date, time_zone, Tzdata.TimeZoneDatabase)

      {:ok, shifted_date} = Tempus.shift(date_with_timezone, months: -6)

      assert DateTime.to_iso8601(shifted_date) == "2018-11-30T00:30:00+02:00"
      assert shifted_date.time_zone == time_zone
    end

    test "helsinki 1 month" do
      date = DateTime.from_naive!(~N[2019-04-30T21:30:00], "Etc/UTC")
      time_zone = "Europe/Helsinki"
      {:ok, date_with_timezone} = DateTime.shift_zone(date, time_zone, Tzdata.TimeZoneDatabase)

      {:ok, shifted_date} = Tempus.shift(date_with_timezone, months: 1)

      assert DateTime.to_iso8601(shifted_date) == "2019-06-01T00:30:00+03:00"
      assert shifted_date.time_zone == time_zone
    end

    property "positive shift amount results in a datetime in the future" do
      check all shift_unit <- StreamData.member_of([:days, :months]),
                time_zone <- time_zone_generator(),
                shift_amount <- StreamData.positive_integer(),
                now <- date_time_generator(),
                max_runs: 1000 do
        {:ok, now_with_tz} =
          DateTime.shift_zone(now, time_zone, Tzdata.TimeZoneDatabase) |> unambiguate()

        {:ok, shifted} = Tempus.shift(now_with_tz, [{shift_unit, shift_amount}])

        assert DateTime.compare(shifted, now_with_tz) == :gt
      end
    end

    property "negative shift amount results in a datetime in the past" do
      check all shift_unit <- StreamData.member_of([:days, :months]),
                time_zone <- time_zone_generator(),
                shift_amount <- StreamData.integer(-1000..-1),
                now <- date_time_generator(),
                max_runs: 1000 do
        {:ok, now_with_tz} =
          DateTime.shift_zone(now, time_zone, Tzdata.TimeZoneDatabase) |> unambiguate()

        {:ok, shifted} = Tempus.shift(now_with_tz, [{shift_unit, shift_amount}])

        assert DateTime.compare(shifted, now_with_tz) == :lt
      end
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
    Tzdata.zone_list()
    |> StreamData.member_of()
  end
end

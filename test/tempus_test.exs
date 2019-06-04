defmodule TempusTest do
  use ExUnit.Case
  doctest Tempus

  test "shift" do
    date = DateTime.from_naive!(~N[2019-04-30T21:30:00], "Etc/UTC")
    time_zone = "Europe/Helsinki"
    {:ok, date_with_timezone} = DateTime.shift_zone(date, time_zone, Tzdata.TimeZoneDatabase)
    {:ok, shifted_date} = Tempus.shift(date_with_timezone, months: 1)

    assert DateTime.to_iso8601(shifted_date) == "2019-06-01T00:30:00+03:00"
    assert shifted_date.time_zone == time_zone
  end
end

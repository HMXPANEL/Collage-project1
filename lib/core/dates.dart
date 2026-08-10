/// Local (calendar) day representation, ignoring the time-of-day component.
DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// The day immediately after [day], as a date-only value.
DateTime nextDay(DateTime day) => DateTime(day.year, day.month, day.day + 1);

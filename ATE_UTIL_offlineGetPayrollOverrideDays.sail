/*
  ATE_UTIL_offlineGetPayrollOverrideDays
  Returns the days (1..dayCount) that weekly payroll override edits apply to for one work order.
  Default (nothing chosen yet for this work order) = whole week.

  Rule inputs:
    overrideDaysByWo  (Any Type)  list of a!map(woNumber: Text, days: List of Integer)
    woNumber          (Text)
    dayCount          (Integer)   number of days in weekCrewData (7)
*/
a!localVariables(
  local!entry: index(
    a!defaultValue(ri!overrideDaysByWo, {}),
    wherecontains(
      tostring(ri!woNumber),
      touniformstring(index(a!defaultValue(ri!overrideDaysByWo, {}), "woNumber", {}))
    ),
    {}
  ),
  if(
    a!isNullOrEmpty(local!entry),
    enumerate(a!defaultValue(ri!dayCount, 0)) + 1,
    tointeger(index(index(local!entry, 1, null), "days", {}))
  )
)

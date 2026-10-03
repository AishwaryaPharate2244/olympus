/*
  ATE_UTIL_offlineGetPayrollOverrideDays
  Weekly view: the days (1..7) that payroll override edits apply to for one work order.
  Read from the "payrollOverrideDays" key stored on that work order in weekCrewData.
  Nothing saved yet = whole week (same as online).

  Rule inputs:
    weekCrewData  (Any Type)
    woNumber      (Text)
*/
a!localVariables(
  /* Saved value on each day for this work order (null where not saved) */
  local!savedPerDay: a!forEach(
    items: a!defaultValue(ri!weekCrewData, {}),
    expression: index(
      index(
        index(
          index(fv!item, "woCrewData", {}),
          wherecontains(
            tostring(ri!woNumber),
            touniformstring(index(index(fv!item, "woCrewData", {}), "workOrderNumber", {}))
          ),
          {}
        ),
        1,
        null
      ),
      "payrollOverrideDays",
      null
    )
  ),
  /* First day that has a saved value (all days hold the same value) */
  local!firstSavedDay: index(
    wherecontains(
      true(),
      a!forEach(items: local!savedPerDay, expression: a!isNotNullOrEmpty(fv!item))
    ),
    1,
    null
  ),
  if(
    isnull(local!firstSavedDay),
    enumerate(count(a!defaultValue(ri!weekCrewData, {}))) + 1,
    tointeger(index(local!savedPerDay, local!firstSavedDay, {}))
  )
)

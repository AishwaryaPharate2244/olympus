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
  /* This work order's entry on each day (one map or null per day - maps do not get flattened) */
  local!woEntries: a!forEach(
    items: a!defaultValue(ri!weekCrewData, {}),
    expression: index(
      index(
        index(fv!item, "woCrewData", {}),
        wherecontains(
          trim(tostring(ri!woNumber)),
          trim(touniformstring(index(index(fv!item, "woCrewData", {}), "workOrderNumber", {})))
        ),
        {}
      ),
      1,
      null
    )
  ),
  /* First day whose entry has a saved selection (all days hold the same value) */
  local!firstSavedDay: index(
    wherecontains(
      true(),
      a!forEach(
        items: local!woEntries,
        expression: a!isNotNullOrEmpty(index(fv!item, "payrollOverrideDays", null))
      )
    ),
    1,
    null
  ),
  if(
    isnull(local!firstSavedDay),
    enumerate(count(a!defaultValue(ri!weekCrewData, {}))) + 1,
    tointeger(
      index(
        index(local!woEntries, local!firstSavedDay, null),
        "payrollOverrideDays",
        {}
      )
    )
  )
)

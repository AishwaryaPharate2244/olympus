/*
  ATE_UTIL_offlineGetPayrollOverrideDays
  Weekly view: the days (1..7) that payroll override applies to for ONE employee
  or ONE equipment on one work order.
  Read from the "payrollOverrideDays" key stored on that labor / equipment row.
  Nothing saved yet = whole week (same as online).

  Rule inputs:
    weekCrewData  (Any Type)
    woNumber      (Text)
    rowKey        (Text)   "labors" or "equipments"
    rowId         (Text)   employeeId or equipmentId
*/
a!localVariables(
  local!idKey: if(ri!rowKey = "labors", "employeeId", "equipmentId"),
  /* This row on each day (one map or null per day - maps do not get flattened) */
  local!rowEntries: a!forEach(
    items: a!defaultValue(ri!weekCrewData, {}),
    expression: a!localVariables(
      local!wos: index(fv!item, "woCrewData", {}),
      local!wo: index(
        index(
          local!wos,
          wherecontains(
            trim(tostring(ri!woNumber)),
            trim(touniformstring(index(local!wos, "workOrderNumber", {})))
          ),
          {}
        ),
        1,
        null
      ),
      local!rows: index(local!wo, ri!rowKey, {}),
      index(
        index(
          local!rows,
          wherecontains(
            tostring(ri!rowId),
            touniformstring(index(local!rows, local!idKey, {}))
          ),
          {}
        ),
        1,
        null
      )
    )
  ),
  /* First day whose row has a saved selection (all days hold the same value) */
  local!firstSavedDay: index(
    wherecontains(
      true(),
      a!forEach(
        items: local!rowEntries,
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
        index(local!rowEntries, local!firstSavedDay, null),
        "payrollOverrideDays",
        {}
      )
    )
  )
)

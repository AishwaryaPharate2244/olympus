/*
  ATE_UTIL_offlineSetPayrollOverrideDays
  Weekly view: stores the selected days on one work order for EVERY day of the week,
  so a save that rebuilds one day's data cannot reset the selection.
  Returns the updated weekCrewData.

  Rule inputs:
    weekCrewData  (Any Type)
    woNumber      (Text)
    days          (Integer, array)
*/
a!forEach(
  items: a!defaultValue(ri!weekCrewData, {}),
  expression: a!update(
    data: fv!item,
    index: "woCrewData",
    value: a!forEach(
      items: index(fv!item, "woCrewData", {}),
      expression: if(
        tostring(index(fv!item, "workOrderNumber", "")) = tostring(ri!woNumber),
        a!update(
          data: fv!item,
          index: "payrollOverrideDays",
          value: tointeger(ri!days)
        ),
        fv!item
      )
    )
  )
)

/*
  ATE_UTIL_offlineSetPayrollOverrideDays
  Saves which days get the payroll override for one work order, then clears the override
  on the days that are not selected.

  Step 1: write the selected days on this work order, on every day of the week.
  Step 2: clear the payroll override on the days that are not selected.

  Rule inputs:
    weekCrewData  (Any Type)
    woNumber      (Text)
    days          (Integer, array)   selected days ({0} = no days)
  Returns the updated weekCrewData.
*/
a!localVariables(
  /* Step 1 */
  local!weekWithDays: a!forEach(
    items: ri!weekCrewData,
    expression: a!update(
      data: fv!item,
      index: "woCrewData",
      value: a!forEach(
        items: index(fv!item, "woCrewData", {}),
        expression: if(
          trim(tostring(index(fv!item, "workOrderNumber", ""))) = trim(tostring(ri!woNumber)),
          a!update(data: fv!item, index: "payrollOverrideDays", value: tointeger(ri!days)),
          fv!item
        )
      )
    )
  ),
  /* Step 2 */
  rule!ATE_UTIL_offlineClearExcludedPayrollOverrideDays(
    weekData: local!weekWithDays,
    woKey: "woCrewData"
  )
)

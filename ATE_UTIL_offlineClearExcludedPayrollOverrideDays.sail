/*
  ATE_UTIL_offlineClearExcludedPayrollOverrideDays
  On each day that a work order has NOT selected in "payrollOverrideDays",
  set its labor and equipment payroll override (category + rate) to null.

  Inputs:
    weekData (Any Type) : the 7 day maps, Sun (1) .. Sat (7)
    woKey    (Text)     : "woCrewData" (screen) or "workOrderData" (final map)
*/
a!forEach(
  items: ri!weekData,
  expression: a!localVariables(
    local!day: fv!index,
    a!update(
      data: fv!item,
      index: ri!woKey,
      value: a!forEach(
        items: index(fv!item, ri!woKey, {}),
        expression: a!localVariables(
          local!days: tointeger(index(fv!item, "payrollOverrideDays", {})),
          if(
            /* nothing saved, or this day is selected: keep as it is */
            or(a!isNullOrEmpty(local!days), contains(local!days, local!day)),
            fv!item,
            /* day not selected: clear labor and equipment */
            a!update(
              data: a!update(
                data: fv!item,
                index: "labors",
                value: a!forEach(
                  items: index(fv!item, "labors", {}),
                  expression: a!update(
                    data: a!update(data: fv!item, index: "payrollConfigOverrideId", value: null),
                    index: "hourTypes",
                    value: a!forEach(
                      items: index(fv!item, "hourTypes", {}),
                      expression: a!update(data: fv!item, index: "payrollOverrideRate", value: null)
                    )
                  )
                )
              ),
              index: "equipments",
              value: a!forEach(
                items: index(fv!item, "equipments", {}),
                expression: a!update(
                  data: a!update(data: fv!item, index: "payrollConfigOverrideId", value: null),
                  index: "payrollOverrideRate",
                  value: null
                )
              )
            )
          )
        )
      )
    )
  )
)

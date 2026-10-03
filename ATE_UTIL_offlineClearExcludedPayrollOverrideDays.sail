/*
  ATE_UTIL_offlineClearExcludedPayrollOverrideDays
  Each labor / equipment row can have its own "payrollOverrideDays".
  On a day that the row has NOT selected, set that row's payroll override
  (category + rate) to null. Rows with nothing saved are left as they are.

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
        expression: a!update(
          data: a!update(
            data: fv!item,
            index: "labors",
            /* labor: clear category and every hour type rate */
            value: a!forEach(
              items: index(fv!item, "labors", {}),
              expression: a!localVariables(
                local!days: tointeger(index(fv!item, "payrollOverrideDays", {})),
                if(
                  or(a!isNullOrEmpty(local!days), contains(local!days, local!day)),
                  fv!item,
                  a!update(
                    data: a!update(data: fv!item, index: "payrollConfigOverrideId", value: null),
                    index: "hourTypes",
                    value: a!forEach(
                      items: index(fv!item, "hourTypes", {}),
                      expression: a!update(data: fv!item, index: "payrollOverrideRate", value: null)
                    )
                  )
                )
              )
            )
          ),
          index: "equipments",
          /* equipment: clear category and rate */
          value: a!forEach(
            items: index(fv!item, "equipments", {}),
            expression: a!localVariables(
              local!days: tointeger(index(fv!item, "payrollOverrideDays", {})),
              if(
                or(a!isNullOrEmpty(local!days), contains(local!days, local!day)),
                fv!item,
                a!update(
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

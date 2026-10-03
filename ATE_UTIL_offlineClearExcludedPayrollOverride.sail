/*
  ATE_UTIL_offlineClearExcludedPayrollOverride
  Weekly: on every day that is NOT in a work order's "payrollOverrideDays",
  sets that work order's payroll override data to null:
    labors[].payrollConfigOverrideId, labors[].hourTypes[].payrollOverrideRate,
    equipments[].payrollConfigOverrideId, equipments[].payrollOverrideRate
  Work orders without a saved selection are left unchanged (whole week).

  Use it in two places:
    - the screen data:  woKey = "woCrewData"     (called by ATE_UTIL_offlineSetPayrollOverrideDays)
    - the final map before building ROME Contractor Timesheet: woKey = "workOrderData"

  Rule inputs:
    weekData  (Any Type)  list of day maps, ordered Sun (1) .. Sat (7)
    woKey     (Text)      "woCrewData" or "workOrderData"
  Returns the updated list.
*/
a!forEach(
  items: a!defaultValue(ri!weekData, {}),
  expression: a!localVariables(
    local!dayIdx: fv!index,
    a!update(
      data: fv!item,
      index: ri!woKey,
      value: a!forEach(
        items: index(fv!item, ri!woKey, {}),
        expression: a!localVariables(
          local!days: tointeger(index(fv!item, "payrollOverrideDays", {})),
          if(
            /* no selection saved, or this day is included: keep as is */
            or(
              a!isNullOrEmpty(local!days),
              contains(local!days, local!dayIdx)
            ),
            fv!item,
            /* excluded day: null all payroll override data of this work order */
            a!update(
              data: a!update(
                data: fv!item,
                index: "labors",
                value: a!forEach(
                  items: index(fv!item, "labors", {}),
                  expression: a!update(
                    data: a!update(
                      data: fv!item,
                      index: "payrollConfigOverrideId",
                      value: null
                    ),
                    index: "hourTypes",
                    value: a!forEach(
                      items: index(fv!item, "hourTypes", {}),
                      expression: a!update(
                        data: fv!item,
                        index: "payrollOverrideRate",
                        value: null
                      )
                    )
                  )
                )
              ),
              index: "equipments",
              value: a!forEach(
                items: index(fv!item, "equipments", {}),
                expression: a!update(
                  data: a!update(
                    data: fv!item,
                    index: "payrollConfigOverrideId",
                    value: null
                  ),
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

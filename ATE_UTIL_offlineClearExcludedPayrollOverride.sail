/*
  ATE_UTIL_offlineClearExcludedPayrollOverride
  For each day of the week: if a work order's "payrollOverrideDays" does NOT include that day,
  remove the payroll override from all of its labor and equipment rows on that day.
  Work orders with no saved selection are left as they are (= whole week).

  Rule inputs:
    weekData  (Any Type)  the 7 day maps, ordered Sun (1) .. Sat (7)
    woKey     (Text)      name of the work order list in a day map:
                          "woCrewData" on the screen, "workOrderData" in the final map
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
          local!selectedDays: tointeger(index(fv!item, "payrollOverrideDays", {})),
          local!isExcluded: and(
            a!isNotNullOrEmpty(local!selectedDays),
            not(contains(local!selectedDays, local!day))
          ),
          if(
            local!isExcluded,
            /* excluded day: clear every labor and equipment row */
            a!update(
              data: a!update(
                data: fv!item,
                index: "labors",
                value: a!forEach(
                  items: index(fv!item, "labors", {}),
                  expression: rule!ATE_UTIL_offlineClearLaborPayrollOverride(labor: fv!item)
                )
              ),
              index: "equipments",
              value: a!forEach(
                items: index(fv!item, "equipments", {}),
                expression: rule!ATE_UTIL_offlineClearEquipmentPayrollOverride(equipment: fv!item)
              )
            ),
            /* included day: keep as it is */
            fv!item
          )
        )
      )
    )
  )
)

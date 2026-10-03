a!localVariables(
  local!wo: index(
    if(
      a!defaultValue(ri!isWeekly, false()),
      index(index(ri!weekCrewData, ri!selectedDay, {}), "woCrewData", {}),
      ri!woCrewData
    ),
    ri!woIndex,
    {}
  ),
  local!row: index(index(local!wo, "labors", {}), ri!laborIndex, {}),
  if(
    not(a!defaultValue(ri!isWeekly, false())),
    updatearray(
      ri!woCrewData,
      ri!woIndex,
      a!update(
        data: local!wo,
        index: "labors",
        value: updatearray(
          index(local!wo, "labors", {}),
          ri!laborIndex,
          rule!ATE_UTIL_offlineapplypayrolloverride(
            laborRow: local!row,
            categoryId: ri!categoryId,
            rate: ri!rate,
            hourTypeId: ri!hourTypeId
          )
        )
      )
    ),
    a!forEach(
      items: ri!weekCrewData,
      expression: a!localVariables(
        local!day: fv!index,
        if(
          and(
            a!isNotNullOrEmpty(ri!targetDays),
            local!day <> ri!selectedDay,
            not(contains(tointeger(ri!targetDays), local!day))
          ),
          fv!item,
          a!update(
            data: fv!item,
            index: "woCrewData",
            value: a!forEach(
              items: index(fv!item, "woCrewData", {}),
              expression: a!localVariables(
                local!woIdx: fv!index,
                if(
                  tostring(index(fv!item, "workOrderNumber", "")) <> tostring(index(local!wo, "workOrderNumber", "")),
                  fv!item,
                  a!update(
                    data: fv!item,
                    index: "labors",
                    value: a!forEach(
                      items: index(fv!item, "labors", {}),
                      expression: if(
                        or(
                          and(local!day = ri!selectedDay, local!woIdx = ri!woIndex, fv!index = ri!laborIndex),
                          and(
                            a!isNotNullOrEmpty(trim(tostring(index(local!row, "employeeId", "")))),
                            trim(tostring(index(fv!item, "employeeId", ""))) = trim(tostring(index(local!row, "employeeId", "")))
                          )
                        ),
                        rule!ATE_UTIL_offlineapplypayrolloverride(
                          laborRow: fv!item,
                          categoryId: ri!categoryId,
                          rate: ri!rate,
                          hourTypeId: ri!hourTypeId
                        ),
                        fv!item
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)

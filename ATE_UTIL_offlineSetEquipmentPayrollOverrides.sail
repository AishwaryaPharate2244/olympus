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
  local!row: index(index(local!wo, "equipments", {}), ri!equipmentIndex, {}),
  if(
    not(a!defaultValue(ri!isWeekly, false())),
    updatearray(
      ri!woCrewData,
      ri!woIndex,
      a!update(
        data: local!wo,
        index: "equipments",
        value: updatearray(
          index(local!wo, "equipments", {}),
          ri!equipmentIndex,
          a!update(
            data: a!update(data: local!row, index: "payrollConfigOverrideId", value: tointeger(ri!categoryId)),
            index: "payrollOverrideRate",
            value: if(a!isNullOrEmpty(ri!rate), null, round(todecimal(ri!rate), 2))
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
                    index: "equipments",
                    value: a!forEach(
                      items: index(fv!item, "equipments", {}),
                      expression: if(
                        or(
                          and(local!day = ri!selectedDay, local!woIdx = ri!woIndex, fv!index = ri!equipmentIndex),
                          and(
                            a!isNotNullOrEmpty(trim(tostring(index(local!row, "equipmentId", "")))),
                            trim(tostring(index(fv!item, "equipmentId", ""))) = trim(tostring(index(local!row, "equipmentId", "")))
                          ),
                          and(
                            a!isNullOrEmpty(trim(tostring(index(local!row, "equipmentId", "")))),
                            not(a!defaultValue(index(local!row, "isAdhoc", false()), false())),
                            not(a!defaultValue(index(fv!item, "isAdhoc", false()), false())),
                            if(
                              a!isNotNullOrEmpty(trim(tostring(index(local!row, "equipmentName", "")))),
                              trim(tostring(index(fv!item, "equipmentName", ""))) = trim(tostring(index(local!row, "equipmentName", ""))),
                              fv!index = ri!equipmentIndex
                            )
                          )
                        ),
                        a!update(
                          data: a!update(data: fv!item, index: "payrollConfigOverrideId", value: tointeger(ri!categoryId)),
                          index: "payrollOverrideRate",
                          value: if(a!isNullOrEmpty(ri!rate), null, round(todecimal(ri!rate), 2))
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

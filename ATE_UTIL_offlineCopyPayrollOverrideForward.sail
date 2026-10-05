a!localVariables(
  local!wo: index(index(index(ri!weekCrewData, ri!selectedDay, {}), "woCrewData", {}), ri!woIndex, {}),
  local!source: index(index(local!wo, ri!rowKey, {}), ri!rowIndex, {}),
  local!key: if(
    ri!rowKey = "labors",
    "employeeId",
    if(
      a!isNotNullOrEmpty(trim(tostring(index(local!source, "equipmentId", "")))),
      "equipmentId",
      "equipmentName"
    )
  ),
  local!sourceKey: trim(tostring(index(local!source, local!key, ""))),
  local!sourceHourTypes: index(local!source, "hourTypes", {}),
  local!sourceHourTypeIds: tointeger(index(local!sourceHourTypes, "hourTypeId", {})),
  a!forEach(
    items: ri!weekCrewData,
    expression: if(
      or(fv!index <= ri!selectedDay, a!isNullOrEmpty(local!sourceKey)),
      fv!item,
      a!update(
        data: fv!item,
        index: "woCrewData",
        value: a!forEach(
          items: index(fv!item, "woCrewData", {}),
          expression: if(
            trim(tostring(index(fv!item, "workOrderNumber", ""))) <> trim(tostring(index(local!wo, "workOrderNumber", ""))),
            fv!item,
            a!update(
              data: fv!item,
              index: ri!rowKey,
              value: a!forEach(
                items: index(fv!item, ri!rowKey, {}),
                expression: if(
                  trim(tostring(index(fv!item, local!key, ""))) <> local!sourceKey,
                  fv!item,
                  a!update(
                    data: a!update(data: fv!item, index: "payrollConfigOverrideId", value: index(local!source, "payrollConfigOverrideId", null)),
                    index: if(ri!rowKey = "labors", "hourTypes", "payrollOverrideRate"),
                    value: if(
                      ri!rowKey = "labors",
                      a!localVariables(
                        local!rowHourTypes: index(fv!item, "hourTypes", {}),
                        append(
                          a!forEach(
                            items: local!rowHourTypes,
                            expression: a!update(
                              data: fv!item,
                              index: "payrollOverrideRate",
                              value: index(
                                index(
                                  index(
                                    local!sourceHourTypes,
                                    wherecontains(tointeger(index(fv!item, "hourTypeId", null)), local!sourceHourTypeIds),
                                    {}
                                  ),
                                  "payrollOverrideRate",
                                  {}
                                ),
                                1,
                                null
                              )
                            )
                          ),
                          reject(
                            fn!isnull,
                            a!forEach(
                              items: local!sourceHourTypes,
                              expression: if(
                                contains(
                                  tointeger(index(local!rowHourTypes, "hourTypeId", {})),
                                  tointeger(index(fv!item, "hourTypeId", null))
                                ),
                                null,
                                a!map(
                                  hourTypeId: index(fv!item, "hourTypeId", null),
                                  hours: null,
                                  payrollOverrideRate: index(fv!item, "payrollOverrideRate", null)
                                )
                              )
                            )
                          )
                        )
                      ),
                      index(local!source, "payrollOverrideRate", null)
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

a!localVariables(
  local!idKey: if(ri!rowKey = "labors", "employeeId", "equipmentId"),
  local!source: index(
    reject(
      fn!isnull,
      a!flatten(
        a!forEach(
          items: a!flatten(index(ri!weekCrewData, "woCrewData", {})),
          expression: if(
            trim(tostring(index(fv!item, "workOrderNumber", ""))) = trim(tostring(ri!woNumber)),
            a!forEach(
              items: index(fv!item, ri!rowKey, {}),
              expression: if(
                and(
                  tostring(index(fv!item, local!idKey, "")) = tostring(ri!rowId),
                  a!isNotNullOrEmpty(index(fv!item, "payrollConfigOverrideId", null))
                ),
                fv!item,
                null
              )
            ),
            null
          )
        )
      )
    ),
    1,
    null
  ),
  rule!ATE_UTIL_offlineClearExcludedPayrollOverrideDays(
    weekData: a!forEach(
      items: ri!weekCrewData,
      expression: a!localVariables(
        local!day: fv!index,
        a!update(
          data: fv!item,
          index: "woCrewData",
          value: a!forEach(
            items: index(fv!item, "woCrewData", {}),
            expression: if(
              trim(tostring(index(fv!item, "workOrderNumber", ""))) = trim(tostring(ri!woNumber)),
              a!update(
                data: fv!item,
                index: ri!rowKey,
                value: a!forEach(
                  items: index(fv!item, ri!rowKey, {}),
                  expression: if(
                    tostring(index(fv!item, local!idKey, "")) <> tostring(ri!rowId),
                    fv!item,
                    if(
                      and(
                        contains(tointeger(ri!days), local!day),
                        a!isNullOrEmpty(index(fv!item, "payrollConfigOverrideId", null)),
                        a!isNotNullOrEmpty(local!source)
                      ),
                      a!update(
                        data: a!update(
                          data: a!update(data: fv!item, index: "payrollOverrideDays", value: tointeger(ri!days)),
                          index: "payrollConfigOverrideId",
                          value: index(local!source, "payrollConfigOverrideId", null)
                        ),
                        index: if(ri!rowKey = "labors", "hourTypes", "payrollOverrideRate"),
                        value: if(
                          ri!rowKey = "labors",
                          a!forEach(
                            items: index(fv!item, "hourTypes", {}),
                            expression: a!update(
                              data: fv!item,
                              index: "payrollOverrideRate",
                              value: index(
                                index(
                                  index(
                                    index(local!source, "hourTypes", {}),
                                    wherecontains(
                                      tointeger(index(fv!item, "hourTypeId", null)),
                                      tointeger(index(index(local!source, "hourTypes", {}), "hourTypeId", {}))
                                    ),
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
                          index(local!source, "payrollOverrideRate", null)
                        )
                      ),
                      a!update(data: fv!item, index: "payrollOverrideDays", value: tointeger(ri!days))
                    )
                  )
                )
              ),
              fv!item
            )
          )
        )
      )
    ),
    woKey: "woCrewData"
  )
)

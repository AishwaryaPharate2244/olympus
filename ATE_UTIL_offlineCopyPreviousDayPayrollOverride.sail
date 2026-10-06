a!localVariables(
  local!wos: index(index(ri!weekCrewData, ri!selectedDay, {}), "woCrewData", {}),
  local!wo: index(local!wos, ri!woIndex, {}),
  local!row: index(index(local!wo, ri!rowKey, {}), ri!rowIndex, {}),
  local!sourceHourTypes: index(ri!sourceRow, "hourTypes", {}),
  local!rowHourTypes: index(local!row, "hourTypes", {}),
  local!newRow: a!update(
    data: a!update(data: local!row, index: "payrollConfigOverrideId", value: index(ri!sourceRow, "payrollConfigOverrideId", null)),
    index: if(ri!rowKey = "labors", "hourTypes", "payrollOverrideRate"),
    value: if(
      ri!rowKey = "labors",
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
                  wherecontains(
                    tointeger(index(fv!item, "hourTypeId", null)),
                    tointeger(index(local!sourceHourTypes, "hourTypeId", {}))
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
      ),
      index(ri!sourceRow, "payrollOverrideRate", null)
    )
  ),
  a!update(
    data: ri!weekCrewData,
    index: ri!selectedDay,
    value: a!update(
      data: ri!weekCrewData[ri!selectedDay],
      index: "woCrewData",
      value: updatearray(
        local!wos,
        ri!woIndex,
        a!update(
          data: local!wo,
          index: ri!rowKey,
          value: updatearray(index(local!wo, ri!rowKey, {}), ri!rowIndex, local!newRow)
        )
      )
    )
  )
)

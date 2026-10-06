a!localVariables(
  local!wos: index(index(ri!weekCrewData, ri!selectedDay, {}), "woCrewData", {}),
  local!wo: index(local!wos, ri!woIndex, {}),
  local!row: index(index(local!wo, ri!rowKey, {}), ri!rowIndex, {}),
  local!rowHourTypes: index(local!row, "hourTypes", {}),
  local!sourceHourTypes: index(ri!sourceRow, "hourTypes", {}),
  local!sourceHourTypeIds: tointeger(index(local!sourceHourTypes, "hourTypeId", {})),
  local!rowWithCategory: a!update(
    data: local!row,
    index: "payrollConfigOverrideId",
    value: index(ri!sourceRow, "payrollConfigOverrideId", null)
  ),
  local!copiedRow: if(
    ri!rowKey = "labors",
    a!update(
      data: local!rowWithCategory,
      index: "hourTypes",
      value: append(
        /* Hour types already on this day: take the rate from the same hour type, keep the hours */
        a!forEach(
          items: local!rowHourTypes,
          expression: a!update(
            data: fv!item,
            index: "payrollOverrideRate",
            value: index(
              index(
                index(local!sourceHourTypes, wherecontains(tointeger(index(fv!item, "hourTypeId", null)), local!sourceHourTypeIds), {}),
                "payrollOverrideRate",
                {}
              ),
              1,
              null
            )
          )
        ),
        /* Hour types only on the previous day: add them with their rate and no hours */
        reject(
          fn!isnull,
          a!forEach(
            items: local!sourceHourTypes,
            expression: if(
              contains(tointeger(index(local!rowHourTypes, "hourTypeId", {})), tointeger(index(fv!item, "hourTypeId", null))),
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
    a!update(
      data: local!rowWithCategory,
      index: "payrollOverrideRate",
      value: index(ri!sourceRow, "payrollOverrideRate", null)
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
          value: updatearray(index(local!wo, ri!rowKey, {}), ri!rowIndex, local!copiedRow)
        )
      )
    )
  )
)

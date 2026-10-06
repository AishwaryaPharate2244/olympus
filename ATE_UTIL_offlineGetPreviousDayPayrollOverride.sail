a!localVariables(
  local!wo: index(index(index(ri!weekCrewData, ri!selectedDay, {}), "woCrewData", {}), ri!woIndex, {}),
  local!row: index(index(local!wo, ri!rowKey, {}), ri!rowIndex, {}),
  /* Employees match on employeeId; equipment on equipmentId, or name when it has no id */
  local!matchField: if(
    ri!rowKey = "labors",
    "employeeId",
    if(a!isNullOrEmpty(trim(tostring(index(local!row, "equipmentId", "")))), "equipmentName", "equipmentId")
  ),
  local!matchValue: trim(tostring(index(local!row, local!matchField, ""))),
  local!previousDayWos: index(index(ri!weekCrewData, ri!selectedDay - 1, {}), "woCrewData", {}),
  local!previousDayRows: a!flatten(
    index(
      index(
        local!previousDayWos,
        wherecontains(
          trim(tostring(index(local!wo, "workOrderNumber", ""))),
          trim(touniformstring(index(local!previousDayWos, "workOrderNumber", {})))
        ),
        {}
      ),
      ri!rowKey,
      {}
    )
  ),
  if(
    or(ri!selectedDay <= 1, a!isNullOrEmpty(local!matchValue)),
    null,
    index(
      index(
        local!previousDayRows,
        wherecontains(local!matchValue, trim(touniformstring(index(local!previousDayRows, local!matchField, {})))),
        {}
      ),
      1,
      null
    )
  )
)

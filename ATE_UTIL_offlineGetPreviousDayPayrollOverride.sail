a!localVariables(
  local!wo: index(index(index(ri!weekCrewData, ri!selectedDay, {}), "woCrewData", {}), ri!woIndex, {}),
  local!row: index(index(local!wo, ri!rowKey, {}), ri!rowIndex, {}),
  local!key: if(
    ri!rowKey = "labors",
    "employeeId",
    if(
      a!isNotNullOrEmpty(trim(tostring(index(local!row, "equipmentId", "")))),
      "equipmentId",
      "equipmentName"
    )
  ),
  local!rowKeyValue: trim(tostring(index(local!row, local!key, ""))),
  local!previousWos: index(index(ri!weekCrewData, ri!selectedDay - 1, {}), "woCrewData", {}),
  local!previousRows: a!flatten(
    index(
      index(
        local!previousWos,
        wherecontains(
          trim(tostring(index(local!wo, "workOrderNumber", ""))),
          trim(touniformstring(index(local!previousWos, "workOrderNumber", {})))
        ),
        {}
      ),
      ri!rowKey,
      {}
    )
  ),
  if(
    or(ri!selectedDay <= 1, a!isNullOrEmpty(local!rowKeyValue)),
    null,
    index(
      index(
        local!previousRows,
        wherecontains(local!rowKeyValue, trim(touniformstring(index(local!previousRows, local!key, {})))),
        {}
      ),
      1,
      null
    )
  )
)

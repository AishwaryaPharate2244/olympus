a!localVariables(
  local!wos: if(
    a!defaultValue(ri!isWeekly, false()),
    index(index(ri!weekCrewData, ri!selectedDay, {}), "woCrewData", {}),
    ri!woCrewData
  ),
  local!wo: index(local!wos, ri!woIndex, {}),
  local!newWos: updatearray(
    local!wos,
    ri!woIndex,
    a!update(
      data: local!wo,
      index: "equipments",
      value: updatearray(
        index(local!wo, "equipments", {}),
        ri!equipmentIndex,
        a!update(
          data: a!update(
            data: index(index(local!wo, "equipments", {}), ri!equipmentIndex, {}),
            index: "payrollConfigOverrideId",
            value: tointeger(ri!categoryId)
          ),
          index: "payrollOverrideRate",
          value: if(a!isNullOrEmpty(ri!rate), null, round(todecimal(ri!rate), 2))
        )
      )
    )
  ),
  if(
    a!defaultValue(ri!isWeekly, false()),
    a!update(
      data: ri!weekCrewData,
      index: ri!selectedDay,
      value: a!update(data: ri!weekCrewData[ri!selectedDay], index: "woCrewData", value: local!newWos)
    ),
    local!newWos
  )
)

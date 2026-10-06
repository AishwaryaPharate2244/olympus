a!localVariables(
  local!isWeekly: a!defaultValue(ri!isWeekly, false()),
  local!wos: if(local!isWeekly, index(index(ri!weekCrewData, ri!selectedDay, {}), "woCrewData", {}), ri!woCrewData),
  local!wo: index(local!wos, ri!woIndex, {}),
  local!equipments: index(local!wo, "equipments", {}),
  local!updatedWos: updatearray(
    local!wos,
    ri!woIndex,
    a!update(
      data: local!wo,
      index: "equipments",
      value: updatearray(
        local!equipments,
        ri!equipmentIndex,
        a!update(
          data: a!update(
            data: index(local!equipments, ri!equipmentIndex, {}),
            index: "payrollConfigOverrideId",
            value: tointeger(ri!categoryId)
          ),
          index: "payrollOverrideRate",
          value: if(a!isNullOrEmpty(ri!rate), null, round(todecimal(ri!rate), 2))
        )
      )
    )
  ),
  /* Daily returns woCrewData, weekly returns weekCrewData with only the selected day changed */
  if(
    local!isWeekly,
    a!update(
      data: ri!weekCrewData,
      index: ri!selectedDay,
      value: a!update(data: ri!weekCrewData[ri!selectedDay], index: "woCrewData", value: local!updatedWos)
    ),
    local!updatedWos
  )
)

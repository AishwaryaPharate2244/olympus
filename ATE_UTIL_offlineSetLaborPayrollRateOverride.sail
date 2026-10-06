a!localVariables(
  local!isWeekly: a!defaultValue(ri!isWeekly, false()),
  local!wos: if(local!isWeekly, index(index(ri!weekCrewData, ri!selectedDay, {}), "woCrewData", {}), ri!woCrewData),
  local!wo: index(local!wos, ri!woIndex, {}),
  local!labors: index(local!wo, "labors", {}),
  local!updatedWos: updatearray(
    local!wos,
    ri!woIndex,
    a!update(
      data: local!wo,
      index: "labors",
      value: updatearray(
        local!labors,
        ri!laborIndex,
        rule!ATE_UTIL_offlineapplypayrolloverride(
          laborRow: index(local!labors, ri!laborIndex, {}),
          categoryId: ri!categoryId,
          rate: ri!rate,
          hourTypeId: ri!hourTypeId
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

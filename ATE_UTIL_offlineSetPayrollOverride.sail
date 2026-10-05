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
      index: "labors",
      value: updatearray(
        index(local!wo, "labors", {}),
        ri!laborIndex,
        rule!ATE_UTIL_offlineapplypayrolloverride(
          laborRow: index(index(local!wo, "labors", {}), ri!laborIndex, {}),
          categoryId: ri!categoryId,
          rate: ri!rate,
          hourTypeId: ri!hourTypeId
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

/*
  ATE_UTIL_offlineSetPayrollOverrideDays
  Weekly: saves the selected days for one work order (on every day of the week) and keeps
  the payroll override data consistent with them:
    - newly included day : category + rate(s) are copied from a day that was already included
                           (same employee / same equipment)
    - excluded day       : category + rate(s) are set to null
  Returns the updated weekCrewData.

  Rule inputs:
    weekCrewData  (Any Type)
    woNumber      (Text)
    days          (Integer, array)  new selection ({0} = no days)
    previousDays  (Integer, array)  selection before this change
*/
a!localVariables(
  local!wo: trim(tostring(ri!woNumber)),
  local!newDays: tointeger(ri!days),
  local!oldDays: tointeger(a!defaultValue(ri!previousDays, {})),

  /* A day that was included before and still is: the values to copy come from here */
  local!sourceDay: index(intersection(local!oldDays, local!newDays), 1, null),
  local!sourceWos: if(
    isnull(local!sourceDay),
    {},
    index(index(ri!weekCrewData, local!sourceDay, {}), "woCrewData", {})
  ),
  local!sourceWo: index(
    index(
      local!sourceWos,
      wherecontains(
        local!wo,
        trim(touniformstring(index(local!sourceWos, "workOrderNumber", {})))
      ),
      {}
    ),
    1,
    null
  ),
  local!srcLabors: index(local!sourceWo, "labors", {}),
  local!srcLaborIds: trim(touniformstring(index(local!srcLabors, "employeeId", {}))),
  local!srcEquips: index(local!sourceWo, "equipments", {}),
  /* equipment is matched by id, or by name when the id is blank */
  local!srcEquipKeys: a!forEach(
    items: local!srcEquips,
    expression: if(
      a!isNullOrEmpty(trim(tostring(index(fv!item, "equipmentId", "")))),
      "N|" & trim(tostring(index(fv!item, "equipmentName", ""))),
      "I|" & trim(tostring(index(fv!item, "equipmentId", "")))
    )
  ),

  /* 1. Save the selection on every day and copy values into newly included days */
  local!updated: a!forEach(
    items: ri!weekCrewData,
    expression: a!localVariables(
      local!isNewDay: and(
        contains(local!newDays, fv!index),
        not(contains(local!oldDays, fv!index)),
        not(isnull(local!sourceWo))
      ),
      a!update(
        data: fv!item,
        index: "woCrewData",
        value: a!forEach(
          items: index(fv!item, "woCrewData", {}),
          expression: if(
            trim(tostring(index(fv!item, "workOrderNumber", ""))) <> local!wo,
            fv!item,
            a!update(
              data: if(
                local!isNewDay,
                a!update(
                  data: a!update(
                    data: fv!item,
                    index: "labors",
                    value: a!forEach(
                      items: index(fv!item, "labors", {}),
                      expression: a!localVariables(
                        local!src: index(
                          local!srcLabors,
                          index(
                            wherecontains(
                              trim(tostring(index(fv!item, "employeeId", ""))),
                              local!srcLaborIds
                            ),
                            1,
                            0
                          ),
                          null
                        ),
                        local!srcIds: tointeger(index(index(local!src, "hourTypes", {}), "hourTypeId", {})),
                        local!srcRates: index(index(local!src, "hourTypes", {}), "payrollOverrideRate", {}),
                        local!fallbackRate: index(reject(fn!isnull, local!srcRates), 1, null),
                        if(
                          isnull(local!src),
                          fv!item,
                          a!update(
                            data: a!update(
                              data: fv!item,
                              index: "payrollConfigOverrideId",
                              value: index(local!src, "payrollConfigOverrideId", null)
                            ),
                            index: "hourTypes",
                            value: a!forEach(
                              items: index(fv!item, "hourTypes", {}),
                              expression: a!update(
                                data: fv!item,
                                index: "payrollOverrideRate",
                                /* same hour type's rate, else the first rate of the source */
                                value: index(
                                  local!srcRates,
                                  index(
                                    wherecontains(
                                      tointeger(index(fv!item, "hourTypeId", null)),
                                      local!srcIds
                                    ),
                                    1,
                                    0
                                  ),
                                  local!fallbackRate
                                )
                              )
                            )
                          )
                        )
                      )
                    )
                  ),
                  index: "equipments",
                  value: a!forEach(
                    items: index(fv!item, "equipments", {}),
                    expression: a!localVariables(
                      local!key: if(
                        a!isNullOrEmpty(trim(tostring(index(fv!item, "equipmentId", "")))),
                        "N|" & trim(tostring(index(fv!item, "equipmentName", ""))),
                        "I|" & trim(tostring(index(fv!item, "equipmentId", "")))
                      ),
                      local!src: index(
                        local!srcEquips,
                        index(wherecontains(local!key, touniformstring(local!srcEquipKeys)), 1, 0),
                        null
                      ),
                      if(
                        isnull(local!src),
                        fv!item,
                        a!update(
                          data: a!update(
                            data: fv!item,
                            index: "payrollConfigOverrideId",
                            value: index(local!src, "payrollConfigOverrideId", null)
                          ),
                          index: "payrollOverrideRate",
                          value: index(local!src, "payrollOverrideRate", null)
                        )
                      )
                    )
                  )
                ),
                fv!item
              ),
              index: "payrollOverrideDays",
              value: local!newDays
            )
          )
        )
      )
    )
  ),

  /* 2. Null the payroll override data on the excluded days */
  rule!ATE_UTIL_offlineClearExcludedPayrollOverride(
    weekData: local!updated,
    woKey: "woCrewData"
  )
)

/*
  ATE_UTIL_offlineSetPayrollOverrideDays
  Saves which days get the payroll override for ONE employee or ONE equipment
  on one work order, then clears the override on the days that are not selected.

  Step 1: find this row's override on another day (the source to copy from).
  Step 2: write the selected days on that row, on every day of the week.
          A selected day with no override (for example a day that was unchecked
          and checked again) gets the category and rates from the source.
  Step 3: clear the payroll override on the days that are not selected.

  Rule inputs:
    weekCrewData  (Any Type)
    woNumber      (Text)
    rowKey        (Text)             "labors" or "equipments"
    rowId         (Text)             employeeId or equipmentId
    days          (Integer, array)   selected days ({0} = no days)
  Returns the updated weekCrewData.
*/
a!localVariables(
  local!idKey: if(ri!rowKey = "labors", "employeeId", "equipmentId"),
  /* Step 1 */
  local!wos: a!flatten(index(ri!weekCrewData, "woCrewData", {})),
  local!rows: a!flatten(
    index(
      index(
        local!wos,
        wherecontains(
          trim(tostring(ri!woNumber)),
          trim(touniformstring(index(local!wos, "workOrderNumber", {})))
        ),
        {}
      ),
      ri!rowKey,
      {}
    )
  ),
  local!myRows: index(
    local!rows,
    wherecontains(
      tostring(ri!rowId),
      touniformstring(index(local!rows, local!idKey, {}))
    ),
    {}
  ),
  local!sourceIndex: index(
    wherecontains(
      false(),
      toboolean(
        a!forEach(
          items: local!myRows,
          expression: a!isNullOrEmpty(index(fv!item, "payrollConfigOverrideId", null))
        )
      )
    ),
    1,
    null
  ),
  local!source: if(isnull(local!sourceIndex), null, local!myRows[local!sourceIndex]),
  local!sourceHourTypes: index(local!source, "hourTypes", {}),
  local!sourceRate: index(
    reject(
      a!isNullOrEmpty(_),
      todecimal(index(local!sourceHourTypes, "payrollOverrideRate", {}))
    ),
    1,
    null
  ),
  /* Step 2 */
  local!weekWithDays: a!forEach(
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
                  tostring(index(fv!item, local!idKey, "")) = tostring(ri!rowId),
                  a!localVariables(
                    local!row: a!update(data: fv!item, index: "payrollOverrideDays", value: tointeger(ri!days)),
                    if(
                      or(
                        isnull(local!source),
                        not(contains(tointeger(ri!days), local!day)),
                        a!isNotNullOrEmpty(index(local!row, "payrollConfigOverrideId", null))
                      ),
                      local!row,
                      if(
                        ri!rowKey = "labors",
                        a!update(
                          data: a!update(
                            data: local!row,
                            index: "payrollConfigOverrideId",
                            value: index(local!source, "payrollConfigOverrideId", null)
                          ),
                          index: "hourTypes",
                          value: a!forEach(
                            items: index(local!row, "hourTypes", {}),
                            expression: a!update(
                              data: fv!item,
                              index: "payrollOverrideRate",
                              value: a!defaultValue(
                                index(
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
                                ),
                                local!sourceRate
                              )
                            )
                          )
                        ),
                        a!update(
                          data: a!update(
                            data: local!row,
                            index: "payrollConfigOverrideId",
                            value: index(local!source, "payrollConfigOverrideId", null)
                          ),
                          index: "payrollOverrideRate",
                          value: index(local!source, "payrollOverrideRate", null)
                        )
                      )
                    )
                  ),
                  fv!item
                )
              )
            ),
            fv!item
          )
        )
      )
    )
  ),
  /* Step 3 */
  rule!ATE_UTIL_offlineClearExcludedPayrollOverrideDays(
    weekData: local!weekWithDays,
    woKey: "woCrewData"
  )
)

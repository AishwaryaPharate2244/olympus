a!localVariables(
  local!idKey: if(ri!rowKey = "labors", "employeeId", "equipmentId"),
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
  local!days: reject(
    a!isNullOrEmpty(_),
    tointeger(
      a!flatten(
        index(
          index(
            local!rows,
            wherecontains(
              tostring(ri!rowId),
              touniformstring(index(local!rows, local!idKey, {}))
            ),
            {}
          ),
          "payrollOverrideDays",
          {}
        )
      )
    )
  ),
  if(
    a!isNullOrEmpty(local!days),
    enumerate(count(a!defaultValue(ri!weekCrewData, {}))) + 1,
    union(local!days, local!days)
  )
)

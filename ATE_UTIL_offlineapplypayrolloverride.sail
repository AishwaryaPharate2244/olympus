a!localVariables(
  local!rate: if(a!isNullOrEmpty(ri!rate), null, round(todecimal(ri!rate), 2)),
  a!update(
    data: a!update(data: ri!laborRow, index: "payrollConfigOverrideId", value: tointeger(ri!categoryId)),
    index: "hourTypes",
    /* No hourTypeId means the rate applies to every hour type of the employee */
    value: a!forEach(
      items: index(ri!laborRow, "hourTypes", {}),
      expression: if(
        or(
          a!isNullOrEmpty(ri!hourTypeId),
          tointeger(index(fv!item, "hourTypeId", null)) = tointeger(ri!hourTypeId)
        ),
        a!update(data: fv!item, index: "payrollOverrideRate", value: local!rate),
        fv!item
      )
    )
  )
)

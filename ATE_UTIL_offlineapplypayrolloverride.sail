a!update(
  data: a!update(
    data: ri!laborRow,
    index: "payrollConfigOverrideId",
    value: tointeger(ri!categoryId)
  ),
  index: "hourTypes",
  value: append(
    a!forEach(
      items: index(ri!laborRow, "hourTypes", {}),
      expression: if(
        or(
          a!isNullOrEmpty(ri!hourTypeId),
          tointeger(index(fv!item, "hourTypeId", null)) = tointeger(ri!hourTypeId)
        ),
        a!update(
          data: fv!item,
          index: "payrollOverrideRate",
          value: if(a!isNullOrEmpty(ri!rate), null, round(todecimal(ri!rate), 2))
        ),
        fv!item
      )
    ),
    if(
      or(
        a!isNullOrEmpty(ri!hourTypeId),
        a!isNullOrEmpty(ri!rate),
        contains(
          tointeger(index(index(ri!laborRow, "hourTypes", {}), "hourTypeId", {})),
          tointeger(ri!hourTypeId)
        )
      ),
      {},
      a!map(
        hourTypeId: tointeger(ri!hourTypeId),
        hours: null,
        payrollOverrideRate: round(todecimal(ri!rate), 2)
      )
    )
  )
)

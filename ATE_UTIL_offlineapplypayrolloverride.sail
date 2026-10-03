a!localVariables(
  local!rate: if(
    a!isNullOrEmpty(ri!value),
    null,
    if(
      ri!action = "CATEGORY",
      if(
        a!defaultValue(ri!canCustomizeRate, false()),
        todecimal(
          displayvalue(
            tointeger(ri!value),
            tointeger(index(ri!options, "id", {})),
            index(ri!options, "rate", {}),
            null
          )
        ),
        null
      ),
      round(todecimal(ri!value), 2)
    )
  ),
  if(
    not(contains({ "CATEGORY", "EMPLOYEE_RATE", "HOURTYPE_RATE" }, ri!action)),
    ri!laborRow,
    a!update(
      data: if(
        ri!action = "CATEGORY",
        a!update(data: ri!laborRow, index: "payrollConfigOverrideId", value: tointeger(ri!value)),
        ri!laborRow
      ),
      index: "hourTypes",
      value: a!forEach(
        items: index(ri!laborRow, "hourTypes", {}),
        expression: if(
          or(
            ri!action <> "HOURTYPE_RATE",
            and(
              a!isNotNullOrEmpty(ri!hourTypeId),
              tointeger(index(fv!item, "hourTypeId", null)) = tointeger(ri!hourTypeId)
            )
          ),
          a!update(data: fv!item, index: "payrollOverrideRate", value: local!rate),
          fv!item
        )
      )
    )
  )
)

/*
  ATE_UTIL_offlineClearLaborPayrollOverride
  Removes the payroll override from ONE labor row:
  the category and the rate on every hour type become null.

  Rule input:
    labor  (Any Type)  one labor row
*/
a!update(
  data: a!update(
    data: ri!labor,
    index: "payrollConfigOverrideId",
    value: null
  ),
  index: "hourTypes",
  value: a!forEach(
    items: index(ri!labor, "hourTypes", {}),
    expression: a!update(data: fv!item, index: "payrollOverrideRate", value: null)
  )
)

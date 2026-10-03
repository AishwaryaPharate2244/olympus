/*
  ATE_UTIL_offlineClearEquipmentPayrollOverride
  Removes the payroll override from ONE equipment row:
  the category and the rate become null.

  Rule input:
    equipment  (Any Type)  one equipment row
*/
a!update(
  data: a!update(
    data: ri!equipment,
    index: "payrollConfigOverrideId",
    value: null
  ),
  index: "payrollOverrideRate",
  value: null
)

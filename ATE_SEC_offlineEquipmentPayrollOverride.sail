/*
  ATE_SEC_offlineEquipmentPayrollOverride
  Payroll Override section for one equipment row (category, rate, weekly days).

  Rule inputs:
    payrollOverride  (Any Type)
    brandingMap      (Any Type)
    isWeekly         (Boolean)
    selectedDay      (Integer)
    weekCrewData     (Any Type)  saved into
    woCrewData       (Any Type)  saved into
    woIndex          (Integer)
    equipmentIndex   (Integer)
    woItem           (Any Type)
*/
a!localVariables(
  local!epShow: a!defaultValue(index(ri!payrollOverride, "equipShowFields", false()), false()),
  local!epCanCustomize: a!defaultValue(index(ri!payrollOverride, "equipCanCustomizeRate", false()), false()),
  local!epOptions: a!defaultValue(index(ri!payrollOverride, "equipOptions", {}), {}),
  local!epOptionIds: tointeger(index(local!epOptions, "id", {})),
  local!epRow: if(
    ri!isWeekly,
    ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].equipments[ri!equipmentIndex],
    ri!woCrewData[ri!woIndex].equipments[ri!equipmentIndex]
  ),
  /* Weekly: days this row gets payroll override (empty = not weekly) */
  local!epDays: if(
    a!defaultValue(ri!isWeekly, false()),
    tointeger(
      rule!ATE_UTIL_offlineGetPayrollOverrideDays(
        weekCrewData: ri!weekCrewData,
        woNumber: tostring(index(ri!woItem, "workOrderNumber", "")),
        rowKey: "equipments",
        rowId: tostring(index(local!epRow, "equipmentId", ""))
      )
    ),
    {}
  ),
  local!epActiveToday: or(
    not(a!defaultValue(ri!isWeekly, false())),
    contains(local!epDays, tointeger(ri!selectedDay))
  ),
  local!epCategoryId: tointeger(
    index(local!epRow, "payrollConfigOverrideId", null)
  ),
  local!epRate: index(local!epRow, "payrollOverrideRate", null),
  a!sectionLayout(
    label: "Payroll Override",
    labelSize: "SMALL",
    labelColor: ri!brandingMap.headingLabelColor,
    isCollapsible: true,
    isInitiallyCollapsed: a!isNullOrEmpty(local!epCategoryId),
    marginAbove: "STANDARD",
    showWhen: local!epShow,
    contents: {
      /* Weekly: days this equipment gets payroll override */
      if(
        a!defaultValue(ri!isWeekly, false()),
        rule!ATE_SEC_offlinePayrollOverrideDays(
          weekCrewData: ri!weekCrewData,
          woNumber: tostring(index(ri!woItem, "workOrderNumber", "")),
          rowKey: "equipments",
          rowId: tostring(index(local!epRow, "equipmentId", "")),
          selectedDay: ri!selectedDay
        ),
        {}
      ),
      /* Category / rate fields only on highlighted days */
      if(
        local!epActiveToday,
        {
          a!dropdownField(
            label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{3779d42f-c2b4-451f-a2a1-9c03215e1927}Payroll Override Category',
            placeholder: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{f41a3d1a-7ae4-4053-9cff-d854c5601192}Select Category',
            choiceLabels: index(local!epOptions, "name", {}),
            choiceValues: local!epOptionIds,
            value: if(
              contains(local!epOptionIds, local!epCategoryId),
              local!epCategoryId,
              null
            ),
            saveInto: if(
              ri!isWeekly,
              a!save(
                ri!weekCrewData,
                rule!ATE_UTIL_offlineSetEquipmentPayrollOverrides(
                  isWeekly: true(),
                  weekCrewData: ri!weekCrewData,
                  selectedDay: ri!selectedDay,
                  woIndex: ri!woIndex,
                  equipmentIndex: ri!equipmentIndex,
                  categoryId: save!value,
                  rate: displayvalue(tointeger(save!value), local!epOptionIds, index(local!epOptions, "rate", {}), null),
                  targetDays: local!epDays
                )
              ),
              a!save(
                ri!woCrewData,
                rule!ATE_UTIL_offlineSetEquipmentPayrollOverrides(
                  isWeekly: false(),
                  woCrewData: ri!woCrewData,
                  woIndex: ri!woIndex,
                  equipmentIndex: ri!equipmentIndex,
                  categoryId: save!value,
                  rate: displayvalue(tointeger(save!value), local!epOptionIds, index(local!epOptions, "rate", {}), null)
                )
              )
            ),
            required: false
          ),
          a!textField(
            label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{c191ec45-b3d6-4f9a-b056-52d50b4a0071}Payroll Override Rate',
            placeholder: "0.00",
            showWhen: local!epCanCustomize,
            value: local!epRate,
            refreshAfter: "UNFOCUS",
            required: a!isNotNullOrEmpty(local!epCategoryId),
            disabled: a!isNullOrEmpty(local!epCategoryId),
            saveInto: {
              if(
                ri!isWeekly,
                a!save(
                  ri!weekCrewData,
                  rule!ATE_UTIL_offlineSetEquipmentPayrollOverrides(
                    isWeekly: true(),
                    weekCrewData: ri!weekCrewData,
                    selectedDay: ri!selectedDay,
                    woIndex: ri!woIndex,
                    equipmentIndex: ri!equipmentIndex,
                    categoryId: local!epCategoryId,
                    rate: save!value,
                    targetDays: local!epDays
                  )
                ),
                a!save(
                  ri!woCrewData,
                  rule!ATE_UTIL_offlineSetEquipmentPayrollOverrides(
                    isWeekly: false(),
                    woCrewData: ri!woCrewData,
                    woIndex: ri!woIndex,
                    equipmentIndex: ri!equipmentIndex,
                    categoryId: local!epCategoryId,
                    rate: save!value
                  )
                )
              )
            },
            validations: if(
              and(
                a!isNotNullOrEmpty(local!epRate),
                todecimal(local!epRate) <= 0
              ),
              'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{70339712-a331-423b-be90-3cff450d2788}Rate must be greater than 0..',
              {}
            )
          )
        },
        {}
      )
    }
  )
)

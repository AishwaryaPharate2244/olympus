/*
  ATE_SEC_offlineEquipmentPayrollOverride
  Payroll Override section for one equipment row: a checkbox shows the category and rate; weekly view also offers "Copy to following days".

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
  local!epCategoryId: tointeger(
    index(local!epRow, "payrollConfigOverrideId", null)
  ),
  local!epShowFields: a!isNotNullOrEmpty(local!epCategoryId),
  local!epRate: index(local!epRow, "payrollOverrideRate", null),
  a!sectionLayout(
    marginAbove: "STANDARD",
    showWhen: local!epShow,
    contents: {
      a!checkboxField(
        labelPosition: "COLLAPSED",
        choiceLabels: { "Payroll Override" },
        choiceValues: { true() },
        value: if(local!epShowFields, { true() }, {}),
        saveInto: a!save(local!epShowFields, a!isNotNullOrEmpty(save!value))
      ),
      if(
        local!epShowFields,
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
                  rate: displayvalue(tointeger(save!value), local!epOptionIds, index(local!epOptions, "rate", {}), null)
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
                    rate: save!value
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
          ),
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            showWhen: and(
              a!defaultValue(ri!isWeekly, false()),
              ri!selectedDay < count(ri!weekCrewData),
              a!isNotNullOrEmpty(local!epCategoryId)
            ),
            value: a!richTextItem(
              text: { a!richTextIcon(icon: "copy"), " Copy to following days" },
              style: "STRONG",
              size: "SMALL",
              color: cons!ROME_TEXT_HEX_ORANGE,
              linkStyle: "STANDALONE",
              link: a!dynamicLink(
                saveInto: a!save(
                  ri!weekCrewData,
                  rule!ATE_UTIL_offlineCopyPayrollOverrideForward(
                    weekCrewData: ri!weekCrewData,
                    selectedDay: ri!selectedDay,
                    woIndex: ri!woIndex,
                    rowKey: "equipments",
                    rowIndex: ri!equipmentIndex
                  )
                )
              )
            )
          )
        },
        {}
      )
    }
  )
)

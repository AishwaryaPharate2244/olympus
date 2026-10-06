a!localVariables(
  local!isWeekly: a!defaultValue(ri!isWeekly, false()),
  local!showSection: a!defaultValue(index(ri!payrollOverride, "equipShowFields", false()), false()),
  local!canCustomize: a!defaultValue(index(ri!payrollOverride, "equipCanCustomizeRate", false()), false()),
  local!options: a!defaultValue(index(ri!payrollOverride, "equipOptions", {}), {}),
  local!optionIds: tointeger(index(local!options, "id", {})),
  local!equipment: if(
    local!isWeekly,
    ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].equipments[ri!equipmentIndex],
    ri!woCrewData[ri!woIndex].equipments[ri!equipmentIndex]
  ),
  local!categoryId: tointeger(index(local!equipment, "payrollConfigOverrideId", null)),
  local!rate: index(local!equipment, "payrollOverrideRate", null),
  local!showFields: a!isNotNullOrEmpty(local!categoryId),
  local!previousDayEquipment: if(
    and(local!isWeekly, ri!selectedDay > 1),
    rule!ATE_UTIL_offlineGetPreviousDayPayrollOverride(
      weekCrewData: ri!weekCrewData,
      selectedDay: ri!selectedDay,
      woIndex: ri!woIndex,
      rowKey: "equipments",
      rowIndex: ri!equipmentIndex
    ),
    null
  ),
  local!copyMessage: a!refreshVariable(value: null, refreshOnVarChange: ri!selectedDay),
  a!sectionLayout(
    marginAbove: "STANDARD",
    showWhen: local!showSection,
    contents: {
      a!checkboxField(
        labelPosition: "COLLAPSED",
        choiceLabels: { "Payroll Override" },
        choiceValues: { true() },
        value: if(local!showFields, { true() }, {}),
        saveInto: a!save(local!showFields, a!isNotNullOrEmpty(save!value))
      ),
      /* Weekly only: copy category and rate from the same equipment on the previous day */
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        showWhen: and(local!isWeekly, ri!selectedDay > 1),
        value: {
          a!richTextItem(
            text: { a!richTextIcon(icon: "copy"), " Copy from previous day" },
            style: "STRONG",
            size: "SMALL",
            color: cons!ROME_TEXT_HEX_ORANGE,
            linkStyle: "STANDALONE",
            link: a!dynamicLink(
              saveInto: if(
                a!isNullOrEmpty(index(local!previousDayEquipment, "payrollConfigOverrideId", null)),
                a!save(local!copyMessage, "No previous day data"),
                {
                  a!save(
                    ri!weekCrewData,
                    rule!ATE_UTIL_offlineCopyPreviousDayPayrollOverride(
                      weekCrewData: ri!weekCrewData,
                      selectedDay: ri!selectedDay,
                      woIndex: ri!woIndex,
                      rowKey: "equipments",
                      rowIndex: ri!equipmentIndex,
                      sourceRow: local!previousDayEquipment
                    )
                  ),
                  a!save(local!copyMessage, null)
                }
              )
            )
          ),
          a!richTextItem(
            text: "   " & local!copyMessage,
            size: "SMALL",
            color: "SECONDARY",
            style: "EMPHASIS",
            showWhen: a!isNotNullOrEmpty(local!copyMessage)
          )
        }
      ),
      a!dropdownField(
        label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{3779d42f-c2b4-451f-a2a1-9c03215e1927}Payroll Override Category',
        placeholder: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{f41a3d1a-7ae4-4053-9cff-d854c5601192}Select Category',
        choiceLabels: index(local!options, "name", {}),
        choiceValues: local!optionIds,
        value: if(contains(local!optionIds, local!categoryId), local!categoryId, null),
        saveInto: if(
          local!isWeekly,
          a!save(
            ri!weekCrewData,
            rule!ATE_UTIL_offlineSetEquipmentPayrollRateOverrides(
              isWeekly: true(),
              weekCrewData: ri!weekCrewData,
              selectedDay: ri!selectedDay,
              woIndex: ri!woIndex,
              equipmentIndex: ri!equipmentIndex,
              categoryId: save!value,
              rate: displayvalue(tointeger(save!value), local!optionIds, index(local!options, "rate", {}), null)
            )
          ),
          a!save(
            ri!woCrewData,
            rule!ATE_UTIL_offlineSetEquipmentPayrollRateOverrides(
              isWeekly: false(),
              woCrewData: ri!woCrewData,
              woIndex: ri!woIndex,
              equipmentIndex: ri!equipmentIndex,
              categoryId: save!value,
              rate: displayvalue(tointeger(save!value), local!optionIds, index(local!options, "rate", {}), null)
            )
          )
        ),
        showWhen: local!showFields
      ),
      a!textField(
        label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{c191ec45-b3d6-4f9a-b056-52d50b4a0071}Payroll Override Rate',
        placeholder: "0.00",
        value: local!rate,
        refreshAfter: "UNFOCUS",
        required: a!isNotNullOrEmpty(local!categoryId),
        disabled: a!isNullOrEmpty(local!categoryId),
        saveInto: if(
          local!isWeekly,
          a!save(
            ri!weekCrewData,
            rule!ATE_UTIL_offlineSetEquipmentPayrollRateOverrides(
              isWeekly: true(),
              weekCrewData: ri!weekCrewData,
              selectedDay: ri!selectedDay,
              woIndex: ri!woIndex,
              equipmentIndex: ri!equipmentIndex,
              categoryId: local!categoryId,
              rate: save!value
            )
          ),
          a!save(
            ri!woCrewData,
            rule!ATE_UTIL_offlineSetEquipmentPayrollRateOverrides(
              isWeekly: false(),
              woCrewData: ri!woCrewData,
              woIndex: ri!woIndex,
              equipmentIndex: ri!equipmentIndex,
              categoryId: local!categoryId,
              rate: save!value
            )
          )
        ),
        validations: if(
          and(a!isNotNullOrEmpty(local!rate), todecimal(local!rate) <= 0),
          'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{70339712-a331-423b-be90-3cff450d2788}Rate must be greater than 0..',
          {}
        ),
        showWhen: and(local!showFields, local!canCustomize)
      )
    }
  )
)

a!localVariables(
  local!isWeekly: a!defaultValue(ri!isWeekly, false()),
  local!showSection: a!defaultValue(index(ri!payrollOverride, "showFields", false()), false()),
  local!canCustomize: a!defaultValue(index(ri!payrollOverride, "canCustomizeRate", false()), false()),
  local!isHourTypeLevel: a!defaultValue(index(ri!payrollOverride, "isHourTypeLevel", false()), false()),
  local!options: a!defaultValue(index(ri!payrollOverride, "options", {}), {}),
  local!optionIds: tointeger(index(local!options, "id", {})),
  local!labor: if(
    local!isWeekly,
    ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[ri!laborIndex],
    ri!woCrewData[ri!woIndex].labors[ri!laborIndex]
  ),
  local!hourTypes: index(local!labor, "hourTypes", {}),
  /* Only hour types that have been selected get a rate field */
  local!selectedHourTypes: index(
    local!hourTypes,
    wherecontains(false(), a!forEach(local!hourTypes, a!isNullOrEmpty(index(fv!item, "hourTypeId", null)))),
    {}
  ),
  local!categoryId: tointeger(index(local!labor, "payrollConfigOverrideId", null)),
  local!rate: index(reject(a!isNullOrEmpty(_), index(local!hourTypes, "payrollOverrideRate", {})), 1, null),
  local!showFields: a!isNotNullOrEmpty(local!categoryId),
  local!previousDayLabor: if(
    and(local!isWeekly, ri!selectedDay > 1),
    rule!ATE_UTIL_offlineGetPreviousDayPayrollOverride(
      weekCrewData: ri!weekCrewData,
      selectedDay: ri!selectedDay,
      woIndex: ri!woIndex,
      rowKey: "labors",
      rowIndex: ri!laborIndex
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
      /* Weekly only: copy category and rates from the same employee on the previous day */
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
                a!isNullOrEmpty(index(local!previousDayLabor, "payrollConfigOverrideId", null)),
                a!save(local!copyMessage, "No previous day data"),
                {
                  a!save(
                    ri!weekCrewData,
                    rule!ATE_UTIL_offlineCopyPreviousDayPayrollOverride(
                      weekCrewData: ri!weekCrewData,
                      selectedDay: ri!selectedDay,
                      woIndex: ri!woIndex,
                      rowKey: "labors",
                      rowIndex: ri!laborIndex,
                      sourceRow: local!previousDayLabor
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
        label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{5d3a3777-9011-4e30-814b-4cbdd3faabb2}Job Category Override for Payroll',
        helpTooltip: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{47688bd2-3804-4b0c-a3a8-bfd99470d9c7}Select the job category if the employee worked outside their assigned role..',
        placeholder: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{f41a3d1a-7ae4-4053-9cff-d854c5601192}Select Category',
        choiceLabels: index(local!options, "name", {}),
        choiceValues: local!optionIds,
        value: if(contains(local!optionIds, local!categoryId), local!categoryId, null),
        saveInto: if(
          local!isWeekly,
          a!save(
            ri!weekCrewData,
            rule!ATE_UTIL_offlineSetLaborPayrollRateOverride(
              isWeekly: true(),
              weekCrewData: ri!weekCrewData,
              selectedDay: ri!selectedDay,
              woIndex: ri!woIndex,
              laborIndex: ri!laborIndex,
              categoryId: save!value,
              rate: displayvalue(tointeger(save!value), local!optionIds, index(local!options, "rate", {}), null)
            )
          ),
          a!save(
            ri!woCrewData,
            rule!ATE_UTIL_offlineSetLaborPayrollRateOverride(
              isWeekly: false(),
              woCrewData: ri!woCrewData,
              woIndex: ri!woIndex,
              laborIndex: ri!laborIndex,
              categoryId: save!value,
              rate: displayvalue(tointeger(save!value), local!optionIds, index(local!options, "rate", {}), null)
            )
          )
        ),
        showWhen: local!showFields
      ),
      /* One rate for the employee */
      a!textField(
        label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{c191ec45-b3d6-4f9a-b056-52d50b4a0071}Payroll Override Rate',
        helpTooltip: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{d3c96425-ff9a-476d-84ff-1401fe39d7c0}Edit the payroll rate for the selected job category',
        placeholder: "0.00",
        value: local!rate,
        refreshAfter: "UNFOCUS",
        required: a!isNotNullOrEmpty(local!categoryId),
        disabled: a!isNullOrEmpty(local!categoryId),
        saveInto: if(
          local!isWeekly,
          a!save(
            ri!weekCrewData,
            rule!ATE_UTIL_offlineSetLaborPayrollRateOverride(
              isWeekly: true(),
              weekCrewData: ri!weekCrewData,
              selectedDay: ri!selectedDay,
              woIndex: ri!woIndex,
              laborIndex: ri!laborIndex,
              categoryId: local!categoryId,
              rate: save!value
            )
          ),
          a!save(
            ri!woCrewData,
            rule!ATE_UTIL_offlineSetLaborPayrollRateOverride(
              isWeekly: false(),
              woCrewData: ri!woCrewData,
              woIndex: ri!woIndex,
              laborIndex: ri!laborIndex,
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
        showWhen: and(local!showFields, local!canCustomize, not(local!isHourTypeLevel))
      ),
      /* One rate per hour type, two fields per row */
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        marginAbove: "STANDARD",
        marginBelow: "LESS",
        value: a!richTextItem(
          text: upper('translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{c191ec45-b3d6-4f9a-b056-52d50b4a0071}Payroll Override Rate'),
          color: "SECONDARY",
          size: "SMALL",
          style: "STRONG"
        ),
        showWhen: and(local!showFields, local!canCustomize, local!isHourTypeLevel)
      ),
      a!forEach(
        items: if(
          and(local!showFields, local!canCustomize, local!isHourTypeLevel),
          enumerate(ceiling(count(local!selectedHourTypes) / 2)) * 2 + 1,
          {}
        ),
        expression: a!sideBySideLayout(
          items: a!forEach(
            items: { fv!item, fv!item + 1 },
            expression: if(
              fv!item > count(local!selectedHourTypes),
              a!sideBySideItem(width: "1X", item: a!richTextDisplayField(labelPosition: "COLLAPSED", value: "")),
              a!localVariables(
                local!hourTypeId: tointeger(index(local!selectedHourTypes[fv!item], "hourTypeId", null)),
                local!hourTypeRate: index(local!selectedHourTypes[fv!item], "payrollOverrideRate", null),
                a!sideBySideItem(
                  width: "1X",
                  item: a!textField(
                    label: a!match(
                      value: local!hourTypeId,
                      equals: tointeger(cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[1]),
                      then: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{357eaa30-3c51-43d3-9203-6770f1fb3e70}Straight',
                      equals: tointeger(cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[2]),
                      then: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{ded7768f-481f-4fad-a4f9-0e48bfbc0bc4}Overtime',
                      default: displayvalue(
                        local!hourTypeId,
                        tointeger(index(ri!rejStOtRefHourData, 'recordType!{0ba490b0-1715-4af0-a10a-1c8f99d9f481}ROME Ref Hour Type.fields.{f343f388-81a2-4036-9c0d-c8e692e65cc3}hourTypeId', {})),
                        index(ri!rejStOtRefHourData, 'recordType!{0ba490b0-1715-4af0-a10a-1c8f99d9f481}ROME Ref Hour Type.fields.{b27c18e1-9c0c-4709-8944-9e79b07bb027}name', {}),
                        "Hour Type"
                      )
                    ),
                    placeholder: "0.00",
                    value: local!hourTypeRate,
                    refreshAfter: "UNFOCUS",
                    required: a!isNotNullOrEmpty(local!categoryId),
                    disabled: a!isNullOrEmpty(local!categoryId),
                    saveInto: if(
                      local!isWeekly,
                      a!save(
                        ri!weekCrewData,
                        rule!ATE_UTIL_offlineSetLaborPayrollRateOverride(
                          isWeekly: true(),
                          weekCrewData: ri!weekCrewData,
                          selectedDay: ri!selectedDay,
                          woIndex: ri!woIndex,
                          laborIndex: ri!laborIndex,
                          categoryId: local!categoryId,
                          rate: save!value,
                          hourTypeId: local!hourTypeId
                        )
                      ),
                      a!save(
                        ri!woCrewData,
                        rule!ATE_UTIL_offlineSetLaborPayrollRateOverride(
                          isWeekly: false(),
                          woCrewData: ri!woCrewData,
                          woIndex: ri!woIndex,
                          laborIndex: ri!laborIndex,
                          categoryId: local!categoryId,
                          rate: save!value,
                          hourTypeId: local!hourTypeId
                        )
                      )
                    ),
                    validations: if(
                      and(
                        a!isNotNullOrEmpty(local!hourTypeRate),
                        todecimal(local!hourTypeRate) <= 0,
                        not(
                          contains(
                            tointeger({ cons!ROME_INT_HOUR_TYPE_SICK, cons!ROME_INT_HOUR_TYPE_VACATION, cons!ROME_INT_HOUR_TYPE_HOLIDAY }),
                            local!hourTypeId
                          )
                        )
                      ),
                      'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{70339712-a331-423b-be90-3cff450d2788}Rate must be greater than 0..',
                      {}
                    )
                  )
                )
              )
            )
          )
        )
      )
    }
  )
)

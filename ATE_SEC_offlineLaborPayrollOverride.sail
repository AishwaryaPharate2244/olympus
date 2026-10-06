/*
  ATE_SEC_offlineLaborPayrollOverride
  Payroll Override section for one employee row: a checkbox shows the category and rates; weekly view also offers "Copy to following days".

  Rule inputs:
    payrollOverride     (Any Type)
    brandingMap         (Any Type)
    isWeekly            (Boolean)
    selectedDay         (Integer)
    weekCrewData        (Any Type)  saved into
    woCrewData          (Any Type)  saved into
    woIndex             (Integer)
    laborIndex          (Integer)
    woItem              (Any Type)
    rejStOtRefHourData  (Any Type)
*/
a!localVariables(
  local!poShow: a!defaultValue(index(ri!payrollOverride, "showFields", false()), false()),
  local!poCanCustomize: a!defaultValue(index(ri!payrollOverride, "canCustomizeRate", false()), false()),
  local!poHourTypeLevel: a!defaultValue(index(ri!payrollOverride, "isHourTypeLevel", false()), false()),
  local!poOptions: a!defaultValue(index(ri!payrollOverride, "options", {}), {}),
  local!poOptionIds: tointeger(index(local!poOptions, "id", {})),
  local!poRow: if(
    ri!isWeekly,
    ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[ri!laborIndex],
    ri!woCrewData[ri!woIndex].labors[ri!laborIndex]
  ),
  local!hourTypes: index(local!poRow, "hourTypes", {}),
  local!poCategoryId: tointeger(
    index(local!poRow, "payrollConfigOverrideId", null)
  ),
  local!poShowFields: a!isNotNullOrEmpty(local!poCategoryId),
  local!poEmployeeRate: index(
    reject(
      a!isNullOrEmpty(_),
      index(local!hourTypes, "payrollOverrideRate", {})
    ),
    1,
    null
  ),
  a!sectionLayout(
    marginAbove: "STANDARD",
    showWhen: local!poShow,
    contents: {
      a!checkboxField(
        labelPosition: "COLLAPSED",
        choiceLabels: { "Payroll Override" },
        choiceValues: { true() },
        value: if(local!poShowFields, { true() }, {}),
        saveInto: a!save(local!poShowFields, a!isNotNullOrEmpty(save!value))
      ),
      if(
        local!poShowFields,
        {
          a!dropdownField(
            label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{5d3a3777-9011-4e30-814b-4cbdd3faabb2}Job Category Override for Payroll',
            helpTooltip: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{47688bd2-3804-4b0c-a3a8-bfd99470d9c7}Select the job category if the employee worked outside their assigned role..',
            placeholder: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{f41a3d1a-7ae4-4053-9cff-d854c5601192}Select Category',
            choiceLabels: index(local!poOptions, "name", {}),
            choiceValues: local!poOptionIds,
            value: if(
              contains(local!poOptionIds, local!poCategoryId),
              local!poCategoryId,
              null
            ),
            saveInto: if(
              ri!isWeekly,
              a!save(
                ri!weekCrewData,
                rule!ATE_UTIL_offlineSetLaborPayrollRateOverride(
                  isWeekly: true(),
                  weekCrewData: ri!weekCrewData,
                  selectedDay: ri!selectedDay,
                  woIndex: ri!woIndex,
                  laborIndex: ri!laborIndex,
                  categoryId: save!value,
                  rate: displayvalue(tointeger(save!value), local!poOptionIds, index(local!poOptions, "rate", {}), null)
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
                  rate: displayvalue(tointeger(save!value), local!poOptionIds, index(local!poOptions, "rate", {}), null)
                )
              )
            ),
            required: false
          ),
          a!textField(
            label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{c191ec45-b3d6-4f9a-b056-52d50b4a0071}Payroll Override Rate',
            helpTooltip: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{d3c96425-ff9a-476d-84ff-1401fe39d7c0}Edit the payroll rate for the selected job category',
            placeholder: "0.00",
            showWhen: and(
              local!poCanCustomize,
              not(local!poHourTypeLevel)
            ),
            value: local!poEmployeeRate,
            refreshAfter: "UNFOCUS",
            required: a!isNotNullOrEmpty(local!poCategoryId),
            disabled: a!isNullOrEmpty(local!poCategoryId),
            saveInto: {
              if(
                ri!isWeekly,
                a!save(
                  ri!weekCrewData,
                  rule!ATE_UTIL_offlineSetLaborPayrollRateOverride(
                    isWeekly: true(),
                    weekCrewData: ri!weekCrewData,
                    selectedDay: ri!selectedDay,
                    woIndex: ri!woIndex,
                    laborIndex: ri!laborIndex,
                    categoryId: local!poCategoryId,
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
                    categoryId: local!poCategoryId,
                    rate: save!value
                  )
                )
              )
            },
            validations: if(
              and(
                a!isNotNullOrEmpty(local!poEmployeeRate),
                todecimal(local!poEmployeeRate) <= 0
              ),
              'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{70339712-a331-423b-be90-3cff450d2788}Rate must be greater than 0..',
              {}
            )
          ),
          if(
            and(
              local!poCanCustomize,
              local!poHourTypeLevel
            ),
            {
              a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                marginAbove: "STANDARD",
                marginBelow: "LESS",
                value: a!richTextItem(
                  text: upper(
                    'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{c191ec45-b3d6-4f9a-b056-52d50b4a0071}Payroll Override Rate'
                  ),
                  color: "SECONDARY",
                  size: "SMALL",
                  style: "STRONG"
                )
              ),
              a!forEach(
                items: enumerate(ceiling(count(local!hourTypes) / 2)),
                expression: a!sideBySideLayout(
                  items: a!forEach(
                    items: { fv!item * 2 + 1, fv!item * 2 + 2 },
                    expression: if(
                      fv!item > count(local!hourTypes),
                      a!sideBySideItem(
                        width: "1X",
                        item: a!richTextDisplayField(labelPosition: "COLLAPSED", value: "")
                      ),
                      a!localVariables(
                        local!htIdx: fv!item,
                        local!htId: tointeger(
                          index(
                            local!hourTypes[local!htIdx],
                            "hourTypeId",
                            null
                          )
                        ),
                        local!htRate: index(
                          local!hourTypes[local!htIdx],
                          "payrollOverrideRate",
                          null
                        ),
                        local!htName: a!match(
                          value: local!htId,
                          equals: tointeger(
                            cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[1]
                          ),
                          then: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{357eaa30-3c51-43d3-9203-6770f1fb3e70}Straight',
                          equals: tointeger(
                            cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[2]
                          ),
                          then: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{ded7768f-481f-4fad-a4f9-0e48bfbc0bc4}Overtime',
                          default: if(
                            a!isNullOrEmpty(local!htId),
                            "Hour Type",
                            index(
                              index(
                                index(
                                  ri!rejStOtRefHourData,
                                  'recordType!{0ba490b0-1715-4af0-a10a-1c8f99d9f481}ROME Ref Hour Type.fields.{b27c18e1-9c0c-4709-8944-9e79b07bb027}name',
                                  {}
                                ),
                                wherecontains(
                                  local!htId,
                                  tointeger(
                                    index(
                                      ri!rejStOtRefHourData,
                                      'recordType!{0ba490b0-1715-4af0-a10a-1c8f99d9f481}ROME Ref Hour Type.fields.{f343f388-81a2-4036-9c0d-c8e692e65cc3}hourTypeId',
                                      {}
                                    )
                                  )
                                ),
                                {}
                              ),
                              1,
                              "Hour Type"
                            )
                          )
                        ),
                        a!sideBySideItem(
                          width: "1X",
                          item: a!textField(
                            label: local!htName,
                            placeholder: "0.00",
                            value: local!htRate,
                            refreshAfter: "UNFOCUS",
                            required: and(
                              a!isNotNullOrEmpty(local!poCategoryId),
                              a!isNotNullOrEmpty(local!htId)
                            ),
                            disabled: or(
                              a!isNullOrEmpty(local!poCategoryId),
                              a!isNullOrEmpty(local!htId)
                            ),
                            saveInto: {
                              if(
                                ri!isWeekly,
                                a!save(
                                  ri!weekCrewData,
                                  rule!ATE_UTIL_offlineSetLaborPayrollRateOverride(
                                    isWeekly: true(),
                                    weekCrewData: ri!weekCrewData,
                                    selectedDay: ri!selectedDay,
                                    woIndex: ri!woIndex,
                                    laborIndex: ri!laborIndex,
                                    categoryId: local!poCategoryId,
                                    rate: save!value,
                                    hourTypeId: local!htId
                                  )
                                ),
                                a!save(
                                  ri!woCrewData,
                                  rule!ATE_UTIL_offlineSetLaborPayrollRateOverride(
                                    isWeekly: false(),
                                    woCrewData: ri!woCrewData,
                                    woIndex: ri!woIndex,
                                    laborIndex: ri!laborIndex,
                                    categoryId: local!poCategoryId,
                                    rate: save!value,
                                    hourTypeId: local!htId
                                  )
                                )
                              )
                            },
                            validations: if(
                              and(
                                a!isNotNullOrEmpty(local!htRate),
                                todecimal(local!htRate) <= 0,
                                not(
                                  contains(
                                    tointeger(
                                      {
                                        cons!ROME_INT_HOUR_TYPE_SICK,
                                        cons!ROME_INT_HOUR_TYPE_VACATION,
                                        cons!ROME_INT_HOUR_TYPE_HOLIDAY
                                      }
                                    ),
                                    local!htId
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
            },
            {}
          ),
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            showWhen: and(
              a!defaultValue(ri!isWeekly, false()),
              ri!selectedDay < count(ri!weekCrewData),
              a!isNotNullOrEmpty(local!poCategoryId)
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
                    rowKey: "labors",
                    rowIndex: ri!laborIndex
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

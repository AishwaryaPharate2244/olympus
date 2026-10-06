a!localVariables(
  local!isManual: false(),
  local!selectedHourTypeId,
  local!selectedDay: 2,
  local!isWeekly: ri!entryMode = cons!ATE_TXT_DAILY_WEEKLY_MTE_OFFLINE[2],
  local!weekStart: ri!weekEndingDate - 6,
  local!selectedWOIdsText: touniformstring(ri!selectedWOIds),
  local!selectedWoIdx: wherecontains(
    local!selectedWOIdsText,
    touniformstring(ri!woCrewData.workOrderNumber)
  ),
  local!selectedWoCrewData: index(ri!woCrewData, local!selectedWoIdx, {}),
  local!allTimesheetLabors: a!flatten(
    index(local!selectedWoCrewData, "labors", {})
  ),
  local!allTimesheetEquipments: a!flatten(
    index(
      local!selectedWoCrewData,
      "equipments",
      {}
    )
  ),
  local!dynamicTarget: ri!target * (
    length(local!allTimesheetLabors) + length(local!allTimesheetEquipments)
  ),
  local!straightHourTypeId: cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[1],
  local!equipmentSyncHrsTypes: cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[{ 1, 2, 6 }],
  local!selectedWoDetailWONumbers: index(
    ri!selectedWoDetails,
    'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{dba57993-6687-4e94-adce-3841f30378ed}workOrderNumber',
    {}
  ),
  local!configHourTypeConfigIds: tointeger(
    index(
      ri!allSelectedWoConfigHourType,
      'recordType!{0426e3e6-4546-41d3-8b1b-85aebf27b019}ATE L Configuration Hour Type.fields.{32bbd2a9-113e-471e-9c11-d45398b827d5}configurationId',
      {}
    )
  ),
  local!refHourTypeIds: tointeger(
    index(
      ri!allRefHourTypeData,
      'recordType!{0ba490b0-1715-4af0-a10a-1c8f99d9f481}ROME Ref Hour Type.fields.{f343f388-81a2-4036-9c0d-c8e692e65cc3}hourTypeId',
      {}
    )
  ),
  local!rejectedStOtRefData: remove(
    ri!allRefHourTypeData,
    wherecontains(
      {
        cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[1],
        cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[2]
      },
      ri!allRefHourTypeData['recordType!{0ba490b0-1715-4af0-a10a-1c8f99d9f481}ROME Ref Hour Type.fields.{f343f388-81a2-4036-9c0d-c8e692e65cc3}hourTypeId']
    )
  ),
  local!rejectedStOtRefHourTypeIds: tointeger(
    index(
      local!rejectedStOtRefData,
      'recordType!{0ba490b0-1715-4af0-a10a-1c8f99d9f481}ROME Ref Hour Type.fields.{f343f388-81a2-4036-9c0d-c8e692e65cc3}hourTypeId',
      {}
    )
  ),
  local!selectedWorkOrder,
  a!columnsLayout(
    showWhen: ri!step = 3,
    columns: {
      a!columnLayout(
        contents: {
          /* Day badge */
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            value: {
              a!richTextIcon(
                icon: "calendar",
                color: ri!brandingMap.headingLabelColor
              ),
              a!richTextItem(
                text: "  Today · " & upper(text(today(), "DDDD")) & " - " & text(today(), "M/d"),
                style: "STRONG"
              ),
              a!richTextItem(
                text: "      " & "Week of " & text(today() - weekday(today()) + 1, "M/d") & " - " & text(today() - weekday(today()) + 7, "M/d, YYYY"),
                color: "SECONDARY",
                size: "STANDARD",
                style: "EMPHASIS",
                showWhen: ri!entryMode = cons!ATE_TXT_DAILY_WEEKLY_MTE_OFFLINE[1]
              ),
              a!richTextItem(
                text: "      " & touniformstring(ri!dayTotal) & "h logged of " & touniformstring(local!dynamicTarget) & "h target",
                color: "SECONDARY",
                size: "SMALL"
              )
            }
          ),
          /* Weekly day card */
          a!cardLayout(
            contents: {
              a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                value: {
                  a!richTextItem(
                    text: "Week of " & text(local!weekStart, "M/d") & " - " & text(local!weekStart + 6, "M/d, YYYY"),
                    style: "STRONG"
                  )
                }
              ),
              a!localVariables(
                local!mobilePageSize: 4,
                local!mobileStartIndex: if(tointeger(ri!selectedDay) > 4, 5, 1),
                local!displayWeekData: if(
                  a!isPageWidth("PHONE"),
                  index(
                    ri!weekCrewData,
                    enumerate(
                      min(
                        local!mobilePageSize,
                        count(ri!weekCrewData) - local!mobileStartIndex + 1
                      )
                    ) + local!mobileStartIndex,
                    {}
                  ),
                  ri!weekCrewData
                ),
                {
                  a!columnsLayout(
                    columns: a!forEach(
                      items: local!displayWeekData,
                      expression: a!localVariables(
                        local!dayIndex: if(
                          a!isPageWidth("PHONE"),
                          local!mobileStartIndex + fv!index - 1,
                          fv!index
                        ),
                        local!dayDate: index(fv!item, "date", null()),
                        local!weekDayTotal: rule!DCL_RULE_safeSum(
                          {
                            index(
                              index(
                                index(fv!item.woCrewData, "labors", {}),
                                "hourTypes",
                                {}
                              ),
                              "hours",
                              {}
                            ),
                            /*index(*/
                            /*index(fv!item.woCrewData, "equipments", {}),*/
                            /*"hours",*/
                            /*{}*/
                            /*)*/
                            
                          }
                        ),
                        a!columnLayout(
                          contents: {
                            a!cardLayout(
                              contents: {
                                a!columnsLayout(
                                  columns: a!columnLayout(
                                    contents: {
                                      a!richTextDisplayField(
                                        preventWrapping: true(),
                                        value: {
                                          a!richTextItem(
                                            text: left(text(local!dayDate, "dddd"), 3),
                                            style: "STRONG"
                                          )
                                        },
                                        align: "CENTER"
                                      ),
                                      a!richTextDisplayField(
                                        preventWrapping: true(),
                                        value: {
                                          a!richTextItem(
                                            text: text(local!dayDate, "M/d"),
                                            size: "SMALL",
                                            color: "SECONDARY"
                                          )
                                        },
                                        align: "CENTER"
                                      ),
                                      a!richTextDisplayField(
                                        value: {
                                          a!richTextItem(
                                            text: a!defaultValue(local!weekDayTotal, "-"),
                                            style: "STRONG",
                                            color: "SECONDARY"
                                          )
                                        },
                                        align: "CENTER"
                                      )
                                    },
                                    width: "WIDE"
                                  )
                                )
                              },
                              link: a!dynamicLink(
                                saveInto: {
                                  a!save(ri!selectedDay, local!dayIndex),
                                  a!save(local!isManual, false())
                                }
                              ),
                              style: if(
                                local!dayIndex = ri!selectedDay,
                                cons!ROME_TEXT_HEX_ORANGE,
                                if(local!weekDayTotal > 0, "SUCCESS", "NONE")
                              ),
                              shape: "ROUNDED"
                            )
                          },
                          width: "WIDE_PLUS"
                        )
                      )
                    ),
                    stackWhen: "NEVER",
                    spacing: "DENSE"
                  ),
                  /* Mobile pagination */
                  a!columnsLayout(
                    showWhen: and(
                      a!isPageWidth("PHONE"),
                      count(ri!weekCrewData) > local!mobilePageSize
                    ),
                    columns: {
                      a!columnLayout(),
                      a!columnLayout(
                        contents: {
                          a!richTextDisplayField(
                            value: {
                              a!richTextIcon(
                                showWhen: local!mobileStartIndex > 1,
                                icon: "angle-left",
                                caption: "Previous",
                                color: cons!ROME_TEXT_HEX_ORANGE,
                                link: a!dynamicLink(
                                  saveInto: {
                                    a!save(
                                      local!mobileStartIndex,
                                      max(
                                        1,
                                        local!mobileStartIndex - local!mobilePageSize
                                      )
                                    )
                                  }
                                )
                              ),
                              a!richTextItem(
                                text: {
                                  "  ",
                                  local!mobileStartIndex,
                                  "-",
                                  min(
                                    local!mobileStartIndex + local!mobilePageSize - 1,
                                    count(ri!weekCrewData)
                                  ),
                                  " of ",
                                  count(ri!weekCrewData),
                                  "  "
                                },
                                style: "STRONG"
                              ),
                              a!richTextIcon(
                                showWhen: local!mobileStartIndex + local!mobilePageSize <= count(ri!weekCrewData),
                                icon: "angle-right",
                                caption: "Next",
                                color: cons!ROME_TEXT_HEX_ORANGE,
                                link: a!dynamicLink(
                                  saveInto: {
                                    a!save(
                                      local!mobileStartIndex,
                                      local!mobileStartIndex + local!mobilePageSize
                                    )
                                  }
                                )
                              )
                            },
                            align: "CENTER"
                          )
                        },
                        width: "WIDE"
                      ),
                      a!columnLayout()
                    }
                  )
                }
              ),
              a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                value: {
                  a!richTextItem(
                    text: "🟩 Saved daily   🟧 Editing   ⬜ Empty",
                    size: "SMALL",
                    color: "SECONDARY"
                  )
                }
              )
            },
            marginBelow: "LESS",
            style: cons!ATE_TXT_HEX_CARD_STYLE_BASICS,
            shape: "ROUNDED",
            showWhen: local!isWeekly
          ),
          /* ── Crew ribbon ── */
          a!cardLayout(
            showWhen: a!isNotNullOrEmpty(
              index(
                ri!timesheetCustomFieldConf,
                'recordType!{c859c726-925b-479e-9d91-5a281e91de4f}ATE Custom Field Configuration.fields.{d82a783a-5270-4030-a353-0de11a9aa25a}fieldName1En',
                null
              )
            ),
            marginBelow: "STANDARD",
            shape: "ROUNDED",
            contents: {
              /* Custom Field */
              if(
                a!isNotNullOrEmpty(
                  index(
                    ri!timesheetCustomFieldConf,
                    'recordType!{c859c726-925b-479e-9d91-5a281e91de4f}ATE Custom Field Configuration.fields.{d82a783a-5270-4030-a353-0de11a9aa25a}fieldName1En',
                    null
                  )
                ),
                {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    marginBelow: "LESS",
                    value: {
                      a!richTextItem(
                        text: "CUSTOM FIELDS",
                        size: "STANDARD",
                        style: "STRONG"
                      )
                    }
                  ),
                  rule!ATE_SCT_UserDefinedFieldsForMTEOffline(
                    customFieldValue: ri!timesheetCustomFieldValue,
                    customFieldConfiguration: ri!timesheetCustomFieldConf,
                    dropdownChoices: ri!timesheetDropDownChoices
                  )
                },
                {}
              ),
              /* Crew target, Even split | Clear and progress bars: hidden as requested by Priya. Set showWhen to true() to bring them back. */
              a!sectionLayout(
                showWhen: false(),
                contents: {
                  /* Crew */
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    marginBelow: "LESS",
                    value: {
                      a!richTextItem(
                        text: upper(
                          ri!crewDisplayName & "  ·  Target " & touniformstring(ri!target) & "h"
                        ),
                        size: "SMALL",
                        style: "STRONG"
                      ),
                  
                    }
                  ),
                  /* Even split + Clear */
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: {
                      a!richTextItem(
                        text: "Even split",
                        style: "STRONG",
                        color: ri!brandingMap.headingLabelColor,
                        link: a!dynamicLink(
                          saveInto: {
                            a!save(local!isManual, true()),
                            if(
                              local!isWeekly,
                              a!save(
                                ri!weekCrewData,
                                a!update(
                                  data: ri!weekCrewData,
                                  index: ri!selectedDay,
                                  value: a!update(
                                    data: ri!weekCrewData[ri!selectedDay],
                                    index: "woCrewData",
                                    value: a!update(
                                      data: ri!woCrewData,
                                      index: local!selectedWoIdx,
                                      value: a!forEach(
                                        items: local!selectedWoCrewData,
                                        expression: a!localVariables(
                                          local!woItem: fv!item,
                                          a!map(
                                            workOrderNumber: local!woItem.workOrderNumber,
                                            labors: a!forEach(
                                              items: local!woItem.labors,
                                              expression: a!update(
                                                data: fv!item,
                                                index: "hourTypes",
                                                value: a!forEach(
                                                  items: fv!item.hourTypes,
                                                  expression: if(
                                                    contains(
                                                      local!straightHourTypeId,
                                                      tointeger(index(fv!item, "hourTypeId", 0))
                                                    ),
                                                    a!update(
                                                      data: fv!item,
                                                      index: "hours",
                                                      value: ri!evenSplitHours
                                                    ),
                                                    fv!item
                                                  )
                                                )
                                              )
                                            ),
                                            equipments: a!forEach(
                                              items: local!woItem.equipments,
                                              expression: a!update(
                                                data: fv!item,
                                                index: "hours",
                                                value: ri!evenSplitHours
                                              )
                                            ),
                                            units: local!woItem.units,
                                            woEstimatedUnits: local!woItem.woEstimatedUnits,
                                            locations: local!woItem.locations,
                                            selectedMenu: "",
                                            crewVal: 0,
                                            workAddress: local!woItem.woAddr,
                                            selectedHourTypeId: local!woItem.selectedHourTypeId,
                                            timesheetComments: local!woItem.timesheetComments,
                                            unitsComments: local!woItem.unitsComments,
                                            photoDocId: local!woItem.photoDocId,
                                            woCustomFieldsConf: local!woItem.woCustomFieldsConf,
                                            woDropDownChoices: local!woItem.woDropDownChoices,
                                            woCustomFieldValue: local!woItem.woCustomFieldValue
                                          )
                                        )
                                      )
                                    )
                                  )
                                )
                              ),
                              {
                                a!save(local!isManual, true()),
                                a!save(
                                  ri!woCrewData,
                                  a!update(
                                    data: ri!woCrewData,
                                    index: local!selectedWoIdx,
                                    value: a!forEach(
                                      items: local!selectedWoCrewData,
                                      expression: a!localVariables(
                                        local!woItem: fv!item,
                                        a!map(
                                          workOrderNumber: local!woItem.workOrderNumber,
                                          labors: a!forEach(
                                            items: local!woItem.labors,
                                            expression: a!update(
                                              data: fv!item,
                                              index: "hourTypes",
                                              value: a!forEach(
                                                items: fv!item.hourTypes,
                                                expression: if(
                                                  contains(
                                                    local!straightHourTypeId,
                                                    tointeger(index(fv!item, "hourTypeId", 0))
                                                  ),
                                                  a!update(
                                                    data: fv!item,
                                                    index: "hours",
                                                    value: ri!evenSplitHours
                                                  ),
                                                  fv!item
                                                )
                                              )
                                            )
                                          ),
                                          equipments: a!forEach(
                                            items: local!woItem.equipments,
                                            expression: a!update(
                                              data: fv!item,
                                              index: "hours",
                                              value: ri!evenSplitHours
                                            )
                                          ),
                                          units: local!woItem.units,
                                          woEstimatedUnits: local!woItem.woEstimatedUnits,
                                          locations: local!woItem.locations,
                                          selectedMenu: "",
                                          crewVal: 0,
                                          workAddress: local!woItem.woAddr,
                                          selectedHourTypeId: local!woItem.selectedHourTypeId,
                                          timesheetComments: local!woItem.timesheetComments,
                                          unitsComments: local!woItem.unitsComments,
                                          photoDocId: local!woItem.photoDocId,
                                          woCustomFieldsConf: local!woItem.woCustomFieldsConf,
                                          woDropDownChoices: local!woItem.woDropDownChoices,
                                          woCustomFieldValue: local!woItem.woCustomFieldValue
                                        )
                                      )
                                    )
                                  )
                                )
                              }
                            )
                          }
                        ),
                    
                      ),
                      a!richTextItem(text: "   |   "),
                      a!richTextItem(
                        text: "Clear",
                        style: "STRONG",
                        color: "SECONDARY",
                        link: a!dynamicLink(
                          saveInto: {
                            a!save(local!isManual, false()),
                            a!save(local!selectedHourTypeId, ""),
                            if(
                              local!isWeekly,
                              a!save(
                                ri!weekCrewData,
                                a!update(
                                  data: ri!weekCrewData,
                                  index: ri!selectedDay,
                                  value: a!update(
                                    data: ri!weekCrewData[ri!selectedDay],
                                    index: "woCrewData",
                                    value: a!update(
                                      data: ri!woCrewData,
                                      index: local!selectedWoIdx,
                                      value: a!forEach(
                                        items: local!selectedWoCrewData,
                                        expression: a!localVariables(
                                          local!woItem: fv!item,
                                          a!map(
                                            workOrderNumber: local!woItem.workOrderNumber,
                                            labors: a!forEach(
                                              items: local!woItem.labors,
                                              expression: a!update(
                                                data: fv!item,
                                                index: "hourTypes",
                                                value: a!update(
                                                  data: fv!item.hourTypes,
                                                  index: "hours",
                                                  value: 0 * tointeger(index(fv!item.hourTypes, "hours", {}))
                                                )
                                              )
                                            ),
                                            equipments: a!update(
                                              data: index(local!woItem, "equipments", {}),
                                              index: "hours",
                                              value: 0 * tointeger(
                                                index(
                                                  index(local!woItem, "equipments", {}),
                                                  "hours",
                                                  {}
                                                )
                                              )
                                            ),
                                            units: fv!item.units,
                                            woEstimatedUnits: fv!item.woEstimatedUnits,
                                            locations: fv!item.locations,
                                            selectedMenu: "",
                                            crewVal: 0,
                                            workAddress: fv!item.woAddr,
                                            selectedHourTypeId: local!woItem.selectedHourTypeId,
                                            timesheetComments: local!woItem.timesheetComments,
                                            unitsComments: local!woItem.unitsComments,
                                            photoDocId: local!woItem.photoDocId,
                                            woCustomFieldsConf: fv!item.woCustomFieldsConf,
                                            woDropDownChoices: fv!item.woDropDownChoices,
                                            woCustomFieldValue: fv!item.woCustomFieldValue
                                          )
                                        )
                                      )
                                    )
                                  )
                                )
                              ),
                              {
                                a!save(local!isManual, false()),
                                a!save(local!selectedHourTypeId, ""),
                                a!save(
                                  ri!woCrewData,
                                  a!update(
                                    data: ri!woCrewData,
                                    index: local!selectedWoIdx,
                                    value: a!forEach(
                                      items: local!selectedWoCrewData,
                                      expression: a!localVariables(
                                        local!woItem: fv!item,
                                        a!map(
                                          workOrderNumber: local!woItem.workOrderNumber,
                                          labors: a!forEach(
                                            items: local!woItem.labors,
                                            expression: a!update(
                                              data: fv!item,
                                              index: "hourTypes",
                                              value: a!update(
                                                data: fv!item.hourTypes,
                                                index: "hours",
                                                value: 0 * tointeger(index(fv!item.hourTypes, "hours", {}))
                                              )
                                            )
                                          ),
                                          equipments: a!update(
                                            data: index(local!woItem, "equipments", {}),
                                            index: "hours",
                                            value: 0 * tointeger(
                                              index(
                                                index(local!woItem, "equipments", {}),
                                                "hours",
                                                {}
                                              )
                                            )
                                          ),
                                          units: fv!item.units,
                                          woEstimatedUnits: fv!item.woEstimatedUnits,
                                          locations: fv!item.locations,
                                          selectedMenu: "",
                                          crewVal: 0,
                                          selectedHourTypeId: local!woItem.selectedHourTypeId,
                                          timesheetComments: local!woItem.timesheetComments,
                                          unitsComments: local!woItem.unitsComments,
                                          photoDocId: local!woItem.photoDocId,
                                          woCustomFieldsConf: fv!item.woCustomFieldsConf,
                                          woDropDownChoices: fv!item.woDropDownChoices,
                                          woCustomFieldValue: fv!item.woCustomFieldValue
                                        )
                                      )
                                    )
                                  )
                                )
                              }
                            )
                          }
                        ),
                    
                      )
                    }
                  ),
                  /* Per-member progress bars */
                  a!localVariables(
                    local!startIndex: 1,
                    local!batchSize: 3,
                    local!startIndexEquip: 1,
                    local!batchSizeEquip: 3,
                    local!laborEmpIds: touniformstring(
                      index(
                        local!allTimesheetLabors,
                        "employeeId",
                        {}
                      )
                    ),
                    local!equipIds: touniformstring(
                      index(
                        local!allTimesheetEquipments,
                        "equipmentId",
                        {}
                      )
                    ),
                    local!templateEmpIds: touniformstring(
                      index(
                        ri!laborCrewTemplateData,
                        'recordType!{b29742d7-7644-4774-a125-5556cd9e0086}ATE Labor Crew Template.fields.{8517bfc8-4e01-438c-b917-59ad30eecfb8}employeeId',
                        {}
                      )
                    ),
                    local!templateEquipIds: touniformstring(
                      index(
                        ri!equipmentCrewTemplateData,
                        'recordType!{39493776-6005-4f99-adc0-4690c2177ef4}ATE Equipment Crew Template.fields.{22247106-0086-4043-a0b9-224ba13c483c}equipmentId',
                        {}
                      )
                    ),
                    local!barEmployeeIds: reject(
                      a!isNullOrEmpty(_),
                      union(local!laborEmpIds, local!laborEmpIds)
                    ),
                    local!barEquipmentIds: reject(
                      a!isNullOrEmpty(_),
                      union(local!equipIds, local!equipIds)
                    ),
                    local!laborBarCount: length(local!barEmployeeIds),
                    local!equipBarCount: length(local!barEquipmentIds),
                    local!pagedEmployeeIds: index(
                      local!barEmployeeIds,
                      enumerate(
                        min(
                          local!batchSize,
                          local!laborBarCount - local!startIndex + 1
                        )
                      ) + local!startIndex,
                      {}
                    ),
                    local!pagedEquipmentIds: index(
                      local!barEquipmentIds,
                      enumerate(
                        min(
                          local!batchSizeEquip,
                          local!equipBarCount - local!startIndexEquip + 1
                        )
                      ) + local!startIndexEquip,
                      {}
                    ),
                    {
                      a!columnsLayout(
                        columns: a!forEach(
                          items: local!pagedEmployeeIds,
                          expression: a!localVariables(
                            local!rEmpId: fv!item,
                            local!laborMatchIdx: wherecontains(local!rEmpId, local!laborEmpIds),
                            local!matchedLabors: index(
                              local!allTimesheetLabors,
                              local!laborMatchIdx,
                              {}
                            ),
                            local!templateName: index(
                              ri!laborCrewTemplateData['recordType!{b29742d7-7644-4774-a125-5556cd9e0086}ATE Labor Crew Template.relationships.{4b28f158-8819-465b-b32c-0fbc93d18a47}syncedEmployeeData.fields.{9c68dd28-51b5-4f24-b275-99b80680bb13}fullName'],
                              wherecontains(local!rEmpId, local!templateEmpIds),
                              null
                            ),
                            local!rowName: index(
                              local!matchedLabors,
                              "employeeName",
                              null
                            ),
                            local!rName: a!defaultValue(
                              index(local!templateName, 1, null),
                              a!defaultValue(
                                index(local!rowName, 1, null),
                                local!rEmpId
                              )
                            ),
                            local!rTotal: sum(
                              todecimal(
                                a!defaultValue(
                                  index(
                                    index(local!matchedLabors, "hourTypes", {}),
                                    "hours",
                                    0
                                  ),
                                  0
                                )
                              )
                            ),
                            a!columnLayout(
                              contents: {
                                a!richTextDisplayField(
                                  value: {
                                    a!richTextItem(
                                      text: if(
                                        len(local!rName) > 10,
                                        left(local!rName, 10) & "...",
                                        local!rName
                                      ),
                                      style: "STRONG"
                                    ),
                                    a!richTextItem(
                                      text: { char(10) },
                                      style: "STRONG",
                                      showWhen: len(local!rName) < 20
                                    )
                                  },
                                  tooltip: local!rName,
                                  marginBelow: "NONE"
                                ),
                                a!progressBarField(
                                  label: "",
                                  labelPosition: "ABOVE",
                                  percentage: min(
                                    100,
                                    tointeger(local!rTotal / max(1, ri!target) * 100)
                                  ),
                                  color: if(
                                    local!rTotal >= ri!target,
                                    "POSITIVE",
                                    ri!brandingMap.headingLabelColor
                                  )
                                ),
                                a!richTextDisplayField(
                                  labelPosition: "COLLAPSED",
                                  value: {
                                    a!richTextItem(
                                      text: touniformstring(local!rTotal) & "h",
                                      style: "STRONG",
                                      size: "SMALL",
                                      color: if(
                                        local!rTotal >= ri!target,
                                        "POSITIVE",
                                        ri!brandingMap.headingLabelColor
                                      )
                                    ),
                                    a!richTextItem(
                                      text: " / " & touniformstring(ri!target) & "h",
                                      color: "SECONDARY",
                                      size: "SMALL"
                                    )
                                  }
                                )
                              }
                            )
                          )
                        ),
                        stackWhen: "NEVER"
                      ),
                      a!richTextDisplayField(
                        value: {
                          a!richTextIcon(
                            icon: "angle-left",
                            color: cons!ROME_TEXT_HEX_ORANGE,
                            showWhen: local!startIndex <> 1,
                            size: "MEDIUM_PLUS",
                            link: a!dynamicLink(
                              saveInto: {
                                a!save(
                                  local!startIndex,
                                  max(1, local!startIndex - local!batchSize)
                                )
                              }
                            ),
                            linkStyle: "STANDALONE"
                          ),
                          a!richTextItem(
                            text: "  " & local!startIndex & " - " & min(
                              local!startIndex + local!batchSize - 1,
                              local!laborBarCount
                            ) & " of " & local!laborBarCount & "  ",
                            style: "STRONG"
                          ),
                          a!richTextIcon(
                            icon: "angle-right",
                            size: "MEDIUM_PLUS",
                            color: cons!ROME_TEXT_HEX_ORANGE,
                            showWhen: local!laborBarCount > local!startIndex + local!batchSize - 1,
                            link: a!dynamicLink(
                              saveInto: {
                                a!save(
                                  local!startIndex,
                                  local!startIndex + local!batchSize
                                )
                              }
                            ),
                            linkStyle: "STANDALONE"
                          )
                        },
                        align: "RIGHT",
                        showWhen: local!laborBarCount > local!batchSize
                      ),
                      a!columnsLayout(
                        columns: a!forEach(
                          items: local!pagedEquipmentIds,
                          expression: a!localVariables(
                            local!rEqpId: fv!item,
                            local!templateName: index(
                              ri!equipmentCrewTemplateData['recordType!{39493776-6005-4f99-adc0-4690c2177ef4}ATE Equipment Crew Template.relationships.{0c56a132-3545-400e-892a-9e2bdd31cd2f}syncedRefEquipment.fields.{96b6ac3b-eed6-4175-bebd-cf2d1eee4d4d}idAndDescription'],
                              wherecontains(local!rEqpId, local!templateEquipIds),
                              null
                            ),
                            local!rowName: index(
                              index(
                                local!allTimesheetEquipments,
                                wherecontains(local!rEqpId, local!equipIds),
                                {}
                              ),
                              "equipmentName",
                              null
                            ),
                            local!rName: a!defaultValue(
                              index(local!templateName, 1, null),
                              a!defaultValue(
                                index(local!rowName, 1, null),
                                local!rEqpId
                              )
                            ),
                            local!rTotal: sum(
                              a!forEach(
                                items: local!selectedWoCrewData,
                                expression: a!localVariables(
                                  local!equipmentIndex: index(
                                    wherecontains(
                                      local!rEqpId,
                                      touniformstring(
                                        index(fv!item.equipments, "equipmentId", {})
                                      )
                                    ),
                                    1,
                                    null
                                  ),
                                  if(
                                    isnull(local!equipmentIndex),
                                    0,
                                    todecimal(
                                      a!defaultValue(
                                        index(
                                          index(
                                            fv!item.equipments,
                                            local!equipmentIndex,
                                            {}
                                          ),
                                          "hours",
                                          0
                                        ),
                                        0
                                      )
                                    )
                                  )
                                )
                              )
                            ),
                            a!columnLayout(
                              contents: {
                                a!richTextDisplayField(
                                  value: {
                                    a!richTextItem(
                                      text: if(
                                        len(local!rName) > 10,
                                        left(local!rName, 10) & "...",
                                        local!rName
                                      ),
                                      style: "STRONG"
                                    ),
                                    a!richTextItem(
                                      text: { char(10) },
                                      style: "STRONG",
                                      showWhen: len(local!rName) < 20
                                    )
                                  },
                                  tooltip: local!rName,
                                  marginBelow: "NONE"
                                ),
                                a!progressBarField(
                                  label: "",
                                  labelPosition: "ABOVE",
                                  percentage: min(
                                    100,
                                    tointeger(local!rTotal / max(1, ri!target) * 100)
                                  ),
                                  color: if(
                                    local!rTotal >= ri!target,
                                    "POSITIVE",
                                    ri!brandingMap.headingLabelColor
                                  )
                                ),
                                a!richTextDisplayField(
                                  labelPosition: "COLLAPSED",
                                  value: {
                                    a!richTextItem(
                                      text: touniformstring(local!rTotal) & "h",
                                      style: "STRONG",
                                      size: "SMALL",
                                      color: if(
                                        local!rTotal >= ri!target,
                                        "POSITIVE",
                                        ri!brandingMap.headingLabelColor
                                      )
                                    ),
                                    a!richTextItem(
                                      text: " / " & touniformstring(ri!target) & "h",
                                      color: "SECONDARY",
                                      size: "SMALL"
                                    )
                                  }
                                )
                              }
                            )
                          )
                        ),
                        stackWhen: "NEVER"
                      ),
                      a!richTextDisplayField(
                        value: {
                          a!richTextIcon(
                            icon: "angle-left",
                            size: "MEDIUM_PLUS",
                            color: cons!ROME_TEXT_HEX_ORANGE,
                            showWhen: local!startIndexEquip <> 1,
                            link: a!dynamicLink(
                              saveInto: {
                                a!save(
                                  local!startIndexEquip,
                                  max(
                                    1,
                                    local!startIndexEquip - local!batchSizeEquip
                                  )
                                )
                              }
                            ),
                            linkStyle: "STANDALONE"
                          ),
                          a!richTextItem(
                            text: "  " & local!startIndexEquip & " - " & min(
                              local!startIndexEquip + local!batchSizeEquip - 1,
                              local!equipBarCount
                            ) & " of " & local!equipBarCount & "  ",
                            style: "STRONG"
                          ),
                          a!richTextIcon(
                            icon: "angle-right",
                            size: "MEDIUM_PLUS",
                            color: cons!ROME_TEXT_HEX_ORANGE,
                            showWhen: local!equipBarCount > local!startIndexEquip + local!batchSizeEquip - 1,
                            link: a!dynamicLink(
                              saveInto: {
                                a!save(
                                  local!startIndexEquip,
                                  local!startIndexEquip + local!batchSizeEquip
                                )
                              }
                            ),
                            linkStyle: "STANDALONE"
                          )
                        },
                        align: "RIGHT",
                        showWhen: local!equipBarCount > local!batchSizeEquip
                      )
                    }
                  )
                }
              )
            }
          ),
          /* ── Stop cards ── */
          a!sectionLayout(
            label: "",
            contents: {
              a!forEach(
                items: ri!woCrewData,
                expression: a!localVariables(
                  local!woIndex: fv!index,
                  local!woItem: fv!item,
                  local!selectedMenu: fv!item.selectedMenu,
                  local!crewVal: fv!item.crewVal,
                  local!woAddr: fv!item.workAddress,
                  local!laborCount: length(index(local!woItem, "labors", {})),
                  local!equipmentCount: length(index(local!woItem, "equipments", {})),
                  local!perWoConfigHourType: index(
                    ri!allSelectedWoConfigHourType,
                    wherecontains(
                      tointeger(
                        index(
                          index(
                            ri!selectedWoDetails,
                            wherecontains(
                              local!woItem.workOrderNumber,
                              local!selectedWoDetailWONumbers
                            ),
                            {}
                          ),
                          'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.fields.{f0a38adf-be75-47bb-808f-104043b69f31}configurationId',
                          {}
                        )
                      ),
                      local!configHourTypeConfigIds
                    ),
                    {}
                  ),
                  local!woConfigId: index(
                    tointeger(
                      index(
                        index(
                          ri!selectedWoDetails,
                          wherecontains(
                            local!woItem.workOrderNumber,
                            local!selectedWoDetailWONumbers
                          ),
                          {}
                        ),
                        'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.fields.{f0a38adf-be75-47bb-808f-104043b69f31}configurationId',
                        {}
                      )
                    ),
                    1,
                    null
                  ),
                  local!checkIsFusionToggleOn: a!isNotNullOrEmpty(
                    index(
                      ri!fusionPrNoModuleData,
                      wherecontains(
                        local!woConfigId,
                        tointeger(
                          index(
                            ri!fusionPrNoModuleData,
                            'recordType!{6d6374a4-d719-4bbe-862d-05c081b6cc38}ATE L Configuration Module.fields.{96a9b7da-ab2d-41d6-a0cb-97dac46435e0}configurationId',
                            null
                          )
                        )
                      ),
                      'recordType!{6d6374a4-d719-4bbe-862d-05c081b6cc38}ATE L Configuration Module.relationships.{297412c1-5111-4641-b49c-ef6b2afa09eb}module.fields.{0212541f-3b43-4719-b46e-95c0417a8bab}configurationModuleId',
                      null
                    )
                  ),
                  local!woPayrollOverride: if(
                    a!isNullOrEmpty(local!woConfigId),
                    a!map(),
                    index(
                      index(
                        ri!payrollOverrideByConfig,
                        wherecontains(
                          local!woConfigId,
                          tointeger(
                            index(
                              ri!payrollOverrideByConfig,
                              "configurationId",
                              {}
                            )
                          )
                        ),
                        {}
                      ),
                      1,
                      a!map()
                    )
                  ),
                  local!perWoHourTypeIds: tointeger(
                    local!perWoConfigHourType['recordType!{0426e3e6-4546-41d3-8b1b-85aebf27b019}ATE L Configuration Hour Type.fields.{e555c2c1-b8bf-48d6-a38a-6ddd061553eb}hourTypeId']
                  ),
                  local!selectedRefHourTypeData: index(
                    ri!allRefHourTypeData,
                    wherecontains(
                      local!perWoHourTypeIds,
                      local!refHourTypeIds
                    ),
                    {}
                  ),
                  local!rejectedStOtWOHourTypeData: index(
                    local!rejectedStOtRefData,
                    wherecontains(
                      local!perWoHourTypeIds,
                      local!rejectedStOtRefHourTypeIds
                    ),
                    {}
                  ),
                  local!hourTypeId: index(
                    local!selectedRefHourTypeData,
                    'recordType!{0ba490b0-1715-4af0-a10a-1c8f99d9f481}ROME Ref Hour Type.fields.{f343f388-81a2-4036-9c0d-c8e692e65cc3}hourTypeId',
                    {}
                  ),
                  local!hourTypeName: index(
                    local!selectedRefHourTypeData,
                    'recordType!{0ba490b0-1715-4af0-a10a-1c8f99d9f481}ROME Ref Hour Type.fields.{b27c18e1-9c0c-4709-8944-9e79b07bb027}name',
                    {}
                  ),
                  local!woTotal: rule!DCL_RULE_safeSum(
                    {
                      todecimal(
                        a!defaultValue(
                          index(
                            index(
                              index(local!woItem, "labors", null),
                              "hourTypes",
                              null
                            ),
                            "hours",
                            null
                          ),
                          0
                        )
                      )
                    }
                  ),
                  local!crewAvg: if(
                    local!laborCount = 0,
                    0,
                    sum(
                      todecimal(
                        a!defaultValue(
                          index(
                            index(
                              index(local!woItem, "labors", {}),
                              "hourTypes",
                              {}
                            ),
                            "hours",
                            0
                          ),
                          0
                        )
                      )
                    ) / local!laborCount
                  ),
                  local!equipmentAvg: if(
                    local!equipmentCount = 0,
                    0,
                    sum(
                      todecimal(
                        a!defaultValue(
                          index(
                            index(local!woItem, "equipments", {}),
                            "hours",
                            0
                          ),
                          0
                        )
                      )
                    ) / local!equipmentCount
                  ),
                  local!isLocationUnique: if(
                    a!isNullOrEmpty(ri!locationUniqueWoNumbers),
                    false,
                    contains(
                      touniformstring(ri!locationUniqueWoNumbers),
                      tostring(local!woItem.workOrderNumber)
                    )
                  ),
                  local!trackLocation: contains(
                    toboolean(
                      a!flatten(
                        index(
                          index(
                            ri!selectedWoDetails,
                            wherecontains(
                              local!woItem.workOrderNumber,
                              local!selectedWoDetailWONumbers
                            ),
                            {}
                          ),
                          'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.relationships.{187d9785-3bf6-45aa-a289-5cb396e4e82f}unitConfiguration.fields.{5f412f47-933a-4938-9123-58578ef4386b}trackLocation',
                          {}
                        )
                      )
                    ),
                    true
                  ),
                  {
                    a!cardLayout(
                      contents: {
                        a!columnsLayout(
                          columns: {
                            a!columnLayout(
                              contents: {
                                a!columnsLayout(
                                  columns: {
                                    a!columnLayout(
                                      contents: {
                                        a!richTextDisplayField(
                                          labelPosition: "COLLAPSED",
                                          value: {
                                            a!richTextItem(
                                              text: rule!ATE_displayWOBasedOnConfigToggle(
                                                showFusionProjectNo: local!checkIsFusionToggleOn,
                                                woNumber: local!woItem.workOrderNumber,
                                                fusionProjectNo: local!woItem.fusionProjectNo
                                              ),
                                              style: "STRONG"
                                            )
                                          },
                                          marginBelow: "NONE"
                                        )
                                      },
                                      width: "5X"
                                    )
                                  },
                                  stackWhen: "NEVER",
                                  marginBelow: "NONE",
                                  alignVertical: "BOTTOM"
                                ),
                                a!columnsLayout(
                                  columns: {
                                    a!columnLayout(
                                      {
                                        a!richTextDisplayField(
                                          labelPosition: "COLLAPSED",
                                          value: {
                                            a!richTextItem(
                                              text: fv!item.workAddress,
                                              size: "SMALL",
                                              color: "SECONDARY"
                                            )
                                          },
                                          preventWrapping: false()
                                        )
                                      }
                                    )
                                  },
                                  stackWhen: "NEVER",
                                  marginAbove: "NONE",
                                  marginBelow: "NONE"
                                )
                              },
                              width: "7X"
                            ),
                            a!columnLayout(
                              contents: {
                                a!richTextDisplayField(
                                  label: "Bulk Entry",
                                  helpTooltip: "Bulk add hours for all employees and equipment.",
                                  align: "CENTER"
                                ),
                                a!dropdownField(
                                  label: "type",
                                  labelPosition: "COLLAPSED",
                                  placeholder: "--- Select hour type ---",
                                  value: fv!item.selectedHourTypeId,
                                  saveInto: {
                                    fv!item.selectedHourTypeId,
                                    a!save(local!selectedHourTypeId, save!value),
                                    a!save(
                                      if(
                                        local!isWeekly,
                                        ri!weekCrewData[ri!selectedDay].woCrewData,
                                        ri!woCrewData
                                      ),
                                      updatearray(
                                        if(
                                          local!isWeekly,
                                          ri!weekCrewData[ri!selectedDay].woCrewData,
                                          ri!woCrewData
                                        ),
                                        local!woIndex,
                                        a!update(
                                          data: a!update(
                                            data: a!update(
                                              data: local!woItem,
                                              index: "selectedHourTypeId",
                                              value: save!value
                                            ),
                                            index: "crewVal",
                                            value: null
                                          ),
                                          index: "labors",
                                          value: a!forEach(
                                            items: local!woItem.labors,
                                            expression: a!update(
                                              data: fv!item,
                                              index: "hourTypes",
                                              value: if(
                                                contains(
                                                  tointeger(
                                                    index(fv!item.hourTypes, "hourTypeId", {})
                                                  ),
                                                  tointeger(save!value)
                                                ),
                                                fv!item.hourTypes,
                                                append(
                                                  fv!item.hourTypes,
                                                  a!map(
                                                    hourTypeId: save!value,
                                                    hours: null,
                                                    payrollOverrideRate: index(
                                                      reject(
                                                        a!isNullOrEmpty(_),
                                                        index(
                                                          index(fv!item, "hourTypes", {}),
                                                          "payrollOverrideRate",
                                                          {}
                                                        )
                                                      ),
                                                      1,
                                                      null
                                                    )
                                                  )
                                                )
                                              )
                                            )
                                          )
                                        )
                                      )
                                    )
                                  },
                                  choiceLabels: local!hourTypeName,
                                  choiceValues: local!hourTypeId
                                )
                              },
                              showWhen: local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[1],
                              width: "4X"
                            )
                          },
                          stackWhen: "NEVER",
                          alignVertical: "MIDDLE",
                          spacing: "DENSE"
                        ),
                        a!columnsLayout(
                          stackWhen: "DESKTOP_NARROW",
                          spacing: "DENSE",
                          columns: {
                            a!columnLayout(
                              contents: {
                                a!richTextDisplayField(
                                  labelPosition: "COLLAPSED",
                                  value: a!richTextItem(
                                    text: "Total crew hours : " & touniformstring(local!woTotal) & "h",
                                    size: "STANDARD",
                                    color: if(
                                      local!woTotal > 0,
                                      ri!brandingMap.headingLabelColor,
                                      "SECONDARY"
                                    )
                                  )
                                )
                              },
                              width: "8X"
                            ),
                            a!columnLayout(
                              contents: a!cardLayout(
                                contents: {
                                  a!richTextDisplayField(
                                    label: "",
                                    labelPosition: "COLLAPSED",
                                    value: {
                                      a!richTextItem(text: "–", style: "STRONG")
                                    },
                                    align: "CENTER"
                                  )
                                },
                                link: a!dynamicLink(
                                  saveInto: {
                                    a!save(
                                      local!selectedWorkOrder,
                                      fv!item.workOrderNumber
                                    ),
                                    if(
                                      local!isWeekly,
                                      {
                                        a!save(
                                          fv!item.crewVal,
                                          max(
                                            0,
                                            a!defaultValue(fv!item.crewVal, 0) - 0.25
                                          )
                                        ),
                                        a!save(
                                          ri!weekCrewData,
                                          a!update(
                                            data: ri!weekCrewData,
                                            index: ri!selectedDay,
                                            value: a!update(
                                              data: ri!weekCrewData[ri!selectedDay],
                                              index: "woCrewData",
                                              value: updatearray(
                                                ri!weekCrewData[ri!selectedDay].woCrewData,
                                                local!woIndex,
                                                a!map(
                                                  workOrderNumber: local!woItem.workOrderNumber,
                                                  labors: a!forEach(
                                                    items: local!woItem.labors,
                                                    expression: a!update(
                                                      data: fv!item,
                                                      index: "hourTypes",
                                                      value: if(
                                                        a!isNullOrEmpty(local!woItem.selectedHourTypeId),
                                                        fv!item.hourTypes,
                                                        if(
                                                          contains(
                                                            tointeger(
                                                              index(fv!item.hourTypes, "hourTypeId", {})
                                                            ),
                                                            tointeger(local!woItem.selectedHourTypeId)
                                                          ),
                                                          a!forEach(
                                                            items: fv!item.hourTypes,
                                                            expression: if(
                                                              tointeger(index(fv!item, "hourTypeId", 0)) = tointeger(local!woItem.selectedHourTypeId),
                                                              a!update(
                                                                data: fv!item,
                                                                index: "hours",
                                                                value: max(
                                                                  0,
                                                                  todecimal(a!defaultValue(fv!item.hours, 0)) - 0.25
                                                                )
                                                              ),
                                                              fv!item
                                                            )
                                                          ),
                                                          append(
                                                            fv!item.hourTypes,
                                                            a!map(
                                                              hourTypeId: local!woItem.selectedHourTypeId,
                                                              hours: 0,
                                                              payrollOverrideRate: index(
                                                                reject(
                                                                  a!isNullOrEmpty(_),
                                                                  index(
                                                                    index(fv!item, "hourTypes", {}),
                                                                    "payrollOverrideRate",
                                                                    {}
                                                                  )
                                                                ),
                                                                1,
                                                                null
                                                              )
                                                            )
                                                          )
                                                        )
                                                      )
                                                    )
                                                  ),
                                                  equipments: if(
                                                    contains(
                                                      local!equipmentSyncHrsTypes,
                                                      tointeger(local!woItem.selectedHourTypeId)
                                                    ),
                                                    a!forEach(
                                                      items: local!woItem.equipments,
                                                      expression: a!update(
                                                        data: fv!item,
                                                        index: "hours",
                                                        value: max(
                                                          0,
                                                          todecimal(
                                                            if(
                                                              or(isnull(fv!item.hours), fv!item.hours = ""),
                                                              0,
                                                              fv!item.hours
                                                            )
                                                          ) - 0.25
                                                        )
                                                      )
                                                    ),
                                                    local!woItem.equipments
                                                  ),
                                                  units: local!woItem.units,
                                                  woEstimatedUnits: local!woItem.woEstimatedUnits,
                                                  locations: local!woItem.locations,
                                                  selectedMenu: local!selectedMenu,
                                                  crewVal: max(
                                                    0,
                                                    todecimal(
                                                      if(
                                                        or(
                                                          isnull(local!woItem.crewVal),
                                                          local!woItem.crewVal = ""
                                                        ),
                                                        0,
                                                        local!woItem.crewVal
                                                      )
                                                    ) - 0.25
                                                  ),
                                                  workAddress: local!woAddr,
                                                  selectedHourTypeId: local!woItem.selectedHourTypeId,
                                                  timesheetComments: local!woItem.timesheetComments,
                                                  unitsComments: local!woItem.unitsComments,
                                                  photoDocId: local!woItem.photoDocId
                                                )
                                              )
                                            )
                                          )
                                        )
                                      },
                                      {
                                        a!save(
                                          fv!item.crewVal,
                                          max(
                                            0,
                                            a!defaultValue(fv!item.crewVal, 0) - 0.25
                                          )
                                        ),
                                        a!save(
                                          ri!woCrewData,
                                          updatearray(
                                            ri!woCrewData,
                                            local!woIndex,
                                            a!map(
                                              workOrderNumber: local!woItem.workOrderNumber,
                                              labors: a!forEach(
                                                items: local!woItem.labors,
                                                expression: a!update(
                                                  data: fv!item,
                                                  index: "hourTypes",
                                                  value: if(
                                                    a!isNullOrEmpty(local!woItem.selectedHourTypeId),
                                                    fv!item.hourTypes,
                                                    if(
                                                      contains(
                                                        tointeger(fv!item.hourTypes["hourTypeId"]),
                                                        tointeger(local!woItem.selectedHourTypeId)
                                                      ),
                                                      a!forEach(
                                                        items: fv!item.hourTypes,
                                                        expression: if(
                                                          tointeger(index(fv!item, "hourTypeId", 0)) = tointeger(local!woItem.selectedHourTypeId),
                                                          a!update(
                                                            data: fv!item,
                                                            index: "hours",
                                                            value: max(
                                                              0,
                                                              todecimal(
                                                                if(
                                                                  or(isnull(fv!item.hours), fv!item.hours = ""),
                                                                  0,
                                                                  fv!item.hours
                                                                )
                                                              ) - 0.25
                                                            )
                                                          ),
                                                          fv!item
                                                        )
                                                      ),
                                                      append(
                                                        fv!item.hourTypes,
                                                        a!map(
                                                          hourTypeId: local!woItem.selectedHourTypeId,
                                                          hours: 0,
                                                          payrollOverrideRate: index(
                                                            reject(
                                                              a!isNullOrEmpty(_),
                                                              index(
                                                                index(fv!item, "hourTypes", {}),
                                                                "payrollOverrideRate",
                                                                {}
                                                              )
                                                            ),
                                                            1,
                                                            null
                                                          )
                                                        )
                                                      )
                                                    )
                                                  )
                                                )
                                              ),
                                              equipments: if(
                                                contains(
                                                  local!equipmentSyncHrsTypes,
                                                  tointeger(local!woItem.selectedHourTypeId)
                                                ),
                                                a!forEach(
                                                  items: local!woItem.equipments,
                                                  expression: a!update(
                                                    data: fv!item,
                                                    index: "hours",
                                                    value: max(
                                                      0,
                                                      todecimal(
                                                        if(
                                                          or(isnull(fv!item.hours), fv!item.hours = ""),
                                                          0,
                                                          fv!item.hours
                                                        )
                                                      ) - 0.25
                                                    )
                                                  )
                                                ),
                                                local!woItem.equipments
                                              ),
                                              units: fv!item.units,
                                              woEstimatedUnits: fv!item.woEstimatedUnits,
                                              locations: fv!item.locations,
                                              selectedMenu: local!selectedMenu,
                                              crewVal: fv!item.crewVal,
                                              workAddress: local!woAddr,
                                              selectedHourTypeId: local!woItem.selectedHourTypeId,
                                              timesheetComments: local!woItem.timesheetComments,
                                              unitsComments: local!woItem.unitsComments,
                                              photoDocId: local!woItem.photoDocId,
                                              woCustomFieldsConf: fv!item.woCustomFieldsConf,
                                              woDropDownChoices: fv!item.woDropDownChoices,
                                              woCustomFieldValue: fv!item.woCustomFieldValue
                                            )
                                          )
                                        )
                                      }
                                    )
                                  }
                                ),
                                padding: "EVEN_LESS",
                                shape: "ROUNDED"
                              ),
                              width: "1X",
                              showWhen: local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[1]
                            ),
                            a!columnLayout(
                              contents: {
                                a!floatingPointField(
                                  labelPosition: "COLLAPSED",
                                  align: "CENTER",
                                  value: local!crewVal,
                                  saveInto: {
                                    a!save(
                                      if(
                                        local!isWeekly,
                                        ri!weekCrewData,
                                        ri!woCrewData
                                      ),
                                      if(
                                        local!isWeekly,
                                        a!update(
                                          data: ri!weekCrewData,
                                          index: ri!selectedDay,
                                          value: a!update(
                                            data: ri!weekCrewData[ri!selectedDay],
                                            index: "woCrewData",
                                            value: updatearray(
                                              ri!weekCrewData[ri!selectedDay].woCrewData,
                                              local!woIndex,
                                              a!map(
                                                workOrderNumber: local!woItem.workOrderNumber,
                                                labors: a!forEach(
                                                  items: local!woItem.labors,
                                                  expression: a!update(
                                                    data: fv!item,
                                                    index: "hourTypes",
                                                    value: a!forEach(
                                                      items: fv!item.hourTypes,
                                                      expression: if(
                                                        tointeger(fv!item.hourTypeId) = tointeger(local!woItem.selectedHourTypeId),
                                                        a!update(
                                                          data: fv!item,
                                                          index: "hours",
                                                          value: todecimal(save!value)
                                                        ),
                                                        fv!item
                                                      )
                                                    )
                                                  )
                                                ),
                                                equipments: if(
                                                  contains(
                                                    local!equipmentSyncHrsTypes,
                                                    tointeger(local!woItem.selectedHourTypeId)
                                                  ),
                                                  a!localVariables(
                                                    local!updatedHourTypes: a!forEach(
                                                      items: local!woItem.labors[1].hourTypes,
                                                      expression: if(
                                                        fv!item.hourTypeId = local!woItem.selectedHourTypeId,
                                                        a!update(fv!item, "hours", todecimal(save!value)),
                                                        fv!item
                                                      )
                                                    ),
                                                    local!equipmentHours: sum(
                                                      todecimal(
                                                        a!defaultValue(
                                                          index(
                                                            index(
                                                              local!updatedHourTypes,
                                                              wherecontains(
                                                                local!equipmentSyncHrsTypes,
                                                                local!updatedHourTypes.hourTypeId
                                                              ),
                                                              {}
                                                            ),
                                                            "hours",
                                                            0
                                                          ),
                                                          0
                                                        )
                                                      )
                                                    ),
                                                    a!forEach(
                                                      items: local!woItem.equipments,
                                                      expression: a!update(fv!item, "hours", local!equipmentHours)
                                                    )
                                                  ),
                                                  local!woItem.equipments
                                                ),
                                                units: local!woItem.units,
                                                woEstimatedUnits: local!woItem.woEstimatedUnits,
                                                locations: local!woItem.locations,
                                                selectedMenu: local!selectedMenu,
                                                crewVal: todecimal(save!value),
                                                workAddress: local!woAddr,
                                                selectedHourTypeId: local!woItem.selectedHourTypeId,
                                                timesheetComments: local!woItem.timesheetComments,
                                                unitsComments: local!woItem.unitsComments,
                                                photoDocId: local!woItem.photoDocId
                                              )
                                            )
                                          )
                                        ),
                                        updatearray(
                                          ri!woCrewData,
                                          local!woIndex,
                                          a!map(
                                            workOrderNumber: local!woItem.workOrderNumber,
                                            labors: a!forEach(
                                              items: local!woItem.labors,
                                              expression: a!update(
                                                data: fv!item,
                                                index: "hourTypes",
                                                value: if(
                                                  a!isNullOrEmpty(local!woItem.selectedHourTypeId),
                                                  fv!item.hourTypes,
                                                  if(
                                                    contains(
                                                      tointeger(fv!item.hourTypes["hourTypeId"]),
                                                      tointeger(local!woItem.selectedHourTypeId)
                                                    ),
                                                    a!forEach(
                                                      items: fv!item.hourTypes,
                                                      expression: if(
                                                        tointeger(index(fv!item, "hourTypeId", 0)) = tointeger(local!woItem.selectedHourTypeId),
                                                        a!update(
                                                          data: fv!item,
                                                          index: "hours",
                                                          value: max(0, todecimal(save!value))
                                                        ),
                                                        fv!item
                                                      )
                                                    ),
                                                    append(
                                                      fv!item.hourTypes,
                                                      a!map(
                                                        hourTypeId: local!woItem.selectedHourTypeId,
                                                        hours: max(0, todecimal(save!value)),
                                                        payrollOverrideRate: index(
                                                          reject(
                                                            a!isNullOrEmpty(_),
                                                            index(
                                                              index(fv!item, "hourTypes", {}),
                                                              "payrollOverrideRate",
                                                              {}
                                                            )
                                                          ),
                                                          1,
                                                          null
                                                        )
                                                      )
                                                    )
                                                  )
                                                )
                                              )
                                            ),
                                            equipments: if(
                                              contains(
                                                local!equipmentSyncHrsTypes,
                                                tointeger(local!selectedHourTypeId)
                                              ),
                                              a!localVariables(
                                                local!updatedHourTypes: a!forEach(
                                                  items: local!woItem.labors[1].hourTypes,
                                                  expression: if(
                                                    fv!item.hourTypeId = local!selectedHourTypeId,
                                                    a!update(fv!item, "hours", todecimal(save!value)),
                                                    fv!item
                                                  )
                                                ),
                                                local!equipmentHours: sum(
                                                  todecimal(
                                                    a!defaultValue(
                                                      index(
                                                        index(
                                                          local!updatedHourTypes,
                                                          wherecontains(
                                                            local!equipmentSyncHrsTypes,
                                                            local!updatedHourTypes.hourTypeId
                                                          ),
                                                          {}
                                                        ),
                                                        "hours",
                                                        0
                                                      ),
                                                      0
                                                    )
                                                  )
                                                ),
                                                a!forEach(
                                                  items: local!woItem.equipments,
                                                  expression: a!update(fv!item, "hours", local!equipmentHours)
                                                )
                                              ),
                                              local!woItem.equipments
                                            ),
                                            units: local!woItem.units,
                                            woEstimatedUnits: local!woItem.woEstimatedUnits,
                                            locations: local!woItem.locations,
                                            selectedMenu: local!selectedMenu,
                                            crewVal: todecimal(save!value),
                                            workAddress: local!woAddr,
                                            selectedHourTypeId: local!woItem.selectedHourTypeId,
                                            timesheetComments: local!woItem.timesheetComments,
                                            unitsComments: local!woItem.unitsComments,
                                            photoDocId: local!woItem.photoDocId,
                                            woCustomFieldsConf: local!woItem.woCustomFieldsConf,
                                            woDropDownChoices: local!woItem.woDropDownChoices,
                                            woCustomFieldValue: local!woItem.woCustomFieldValue
                                          )
                                        )
                                      )
                                    )
                                  },
                                  placeholder: "0",
                                  showWhen: not(local!isManual),
                                  marginAbove: "NONE",
                                  marginBelow: "NONE"
                                ),
                                a!cardLayout(
                                  contents: {
                                    a!richTextDisplayField(
                                      label: "",
                                      labelPosition: "COLLAPSED",
                                      value: {
                                        a!richTextItem(
                                          text: if(local!isManual, "Mix", local!crewVal),
                                          link: a!dynamicLink(
                                            saveInto: { a!save(local!isManual, false()) }
                                          )
                                        )
                                      },
                                      showWhen: local!isManual,
                                      align: "CENTER",
                                      preventWrapping: true
                                    )
                                  },
                                  showWhen: local!isManual,
                                  style: "STANDARD",
                                  borderColor: "STANDARD",
                                  padding: "EVEN_LESS",
                                  shape: "ROUNDED"
                                )
                              },
                              showWhen: local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[1],
                              width: "2X"
                            ),
                            a!columnLayout(
                              contents: a!cardLayout(
                                contents: {
                                  a!richTextDisplayField(
                                    label: "",
                                    labelPosition: "COLLAPSED",
                                    value: {
                                      a!richTextItem(text: "+", style: "STRONG")
                                    },
                                    align: "CENTER"
                                  )
                                },
                                link: a!dynamicLink(
                                  saveInto: {
                                    a!save(
                                      local!selectedWorkOrder,
                                      fv!item.workOrderNumber
                                    ),
                                    if(
                                      local!isWeekly,
                                      {
                                        a!save(
                                          fv!item.crewVal,
                                          max(
                                            0,
                                            a!defaultValue(fv!item.crewVal, 0) + 0.25
                                          )
                                        ),
                                        a!save(
                                          ri!weekCrewData,
                                          a!update(
                                            data: ri!weekCrewData,
                                            index: ri!selectedDay,
                                            value: a!update(
                                              data: ri!weekCrewData[ri!selectedDay],
                                              index: "woCrewData",
                                              value: updatearray(
                                                ri!weekCrewData[ri!selectedDay].woCrewData,
                                                local!woIndex,
                                                a!map(
                                                  workOrderNumber: local!woItem.workOrderNumber,
                                                  labors: a!forEach(
                                                    items: local!woItem.labors,
                                                    expression: a!update(
                                                      data: fv!item,
                                                      index: "hourTypes",
                                                      value: if(
                                                        a!isNullOrEmpty(local!woItem.selectedHourTypeId),
                                                        fv!item.hourTypes,
                                                        if(
                                                          contains(
                                                            tointeger(fv!item.hourTypes.hourTypeId),
                                                            tointeger(local!woItem.selectedHourTypeId)
                                                          ),
                                                          a!forEach(
                                                            items: fv!item.hourTypes,
                                                            expression: if(
                                                              tointeger(index(fv!item, "hourTypeId", 0)) = tointeger(local!woItem.selectedHourTypeId),
                                                              a!update(
                                                                data: fv!item,
                                                                index: "hours",
                                                                value: max(
                                                                  0,
                                                                  todecimal(
                                                                    if(
                                                                      or(isnull(fv!item.hours), fv!item.hours = ""),
                                                                      0,
                                                                      fv!item.hours
                                                                    )
                                                                  ) + 0.25
                                                                )
                                                              ),
                                                              fv!item
                                                            )
                                                          ),
                                                          append(
                                                            fv!item.hourTypes,
                                                            a!map(
                                                              hourTypeId: local!woItem.selectedHourTypeId,
                                                              hours: 0,
                                                              payrollOverrideRate: index(
                                                                reject(
                                                                  a!isNullOrEmpty(_),
                                                                  index(
                                                                    index(fv!item, "hourTypes", {}),
                                                                    "payrollOverrideRate",
                                                                    {}
                                                                  )
                                                                ),
                                                                1,
                                                                null
                                                              )
                                                            )
                                                          )
                                                        )
                                                      )
                                                    )
                                                  ),
                                                  equipments: if(
                                                    contains(
                                                      local!equipmentSyncHrsTypes,
                                                      tointeger(local!woItem.selectedHourTypeId)
                                                    ),
                                                    a!forEach(
                                                      items: local!woItem.equipments,
                                                      expression: a!update(
                                                        data: fv!item,
                                                        index: "hours",
                                                        value: max(
                                                          0,
                                                          todecimal(
                                                            if(
                                                              or(isnull(fv!item.hours), fv!item.hours = ""),
                                                              0,
                                                              fv!item.hours
                                                            )
                                                          ) + 0.25
                                                        )
                                                      )
                                                    ),
                                                    local!woItem.equipments
                                                  ),
                                                  units: local!woItem.units,
                                                  woEstimatedUnits: local!woItem.woEstimatedUnits,
                                                  locations: local!woItem.locations,
                                                  selectedMenu: local!selectedMenu,
                                                  crewVal: max(
                                                    0,
                                                    todecimal(
                                                      if(
                                                        or(
                                                          isnull(local!woItem.crewVal),
                                                          local!woItem.crewVal = ""
                                                        ),
                                                        0,
                                                        local!woItem.crewVal
                                                      )
                                                    ) + 0.25
                                                  ),
                                                  workAddress: local!woAddr,
                                                  selectedHourTypeId: local!woItem.selectedHourTypeId,
                                                  timesheetComments: local!woItem.timesheetComments,
                                                  unitsComments: local!woItem.unitsComments,
                                                  photoDocId: local!woItem.photoDocId
                                                )
                                              )
                                            )
                                          )
                                        )
                                      },
                                      {
                                        a!save(
                                          fv!item.crewVal,
                                          max(
                                            0,
                                            a!defaultValue(fv!item.crewVal, 0) + 0.25
                                          )
                                        ),
                                        a!save(
                                          ri!woCrewData,
                                          updatearray(
                                            ri!woCrewData,
                                            local!woIndex,
                                            a!map(
                                              workOrderNumber: local!woItem.workOrderNumber,
                                              labors: a!forEach(
                                                items: local!woItem.labors,
                                                expression: a!update(
                                                  data: fv!item,
                                                  index: "hourTypes",
                                                  value: if(
                                                    a!isNullOrEmpty(local!woItem.selectedHourTypeId),
                                                    fv!item.hourTypes,
                                                    if(
                                                      contains(
                                                        tointeger(fv!item.hourTypes["hourTypeId"]),
                                                        tointeger(local!woItem.selectedHourTypeId)
                                                      ),
                                                      a!forEach(
                                                        items: fv!item.hourTypes,
                                                        expression: if(
                                                          tointeger(index(fv!item, "hourTypeId", 0)) = tointeger(local!woItem.selectedHourTypeId),
                                                          a!update(
                                                            data: fv!item,
                                                            index: "hours",
                                                            value: max(
                                                              0,
                                                              todecimal(
                                                                if(
                                                                  or(isnull(fv!item.hours), fv!item.hours = ""),
                                                                  0,
                                                                  fv!item.hours
                                                                )
                                                              ) + 0.25
                                                            )
                                                          ),
                                                          fv!item
                                                        )
                                                      ),
                                                      append(
                                                        fv!item.hourTypes,
                                                        a!map(
                                                          hourTypeId: local!woItem.selectedHourTypeId,
                                                          hours: 0,
                                                          payrollOverrideRate: index(
                                                            reject(
                                                              a!isNullOrEmpty(_),
                                                              index(
                                                                index(fv!item, "hourTypes", {}),
                                                                "payrollOverrideRate",
                                                                {}
                                                              )
                                                            ),
                                                            1,
                                                            null
                                                          )
                                                        )
                                                      )
                                                    )
                                                  )
                                                )
                                              ),
                                              equipments: if(
                                                contains(
                                                  local!equipmentSyncHrsTypes,
                                                  tointeger(local!woItem.selectedHourTypeId)
                                                ),
                                                a!forEach(
                                                  items: local!woItem.equipments,
                                                  expression: a!update(
                                                    data: fv!item,
                                                    index: "hours",
                                                    value: max(
                                                      0,
                                                      todecimal(
                                                        if(
                                                          or(isnull(fv!item.hours), fv!item.hours = ""),
                                                          0,
                                                          fv!item.hours
                                                        )
                                                      ) + 0.25
                                                    )
                                                  )
                                                ),
                                                local!woItem.equipments
                                              ),
                                              units: fv!item.units,
                                              woEstimatedUnits: fv!item.woEstimatedUnits,
                                              locations: fv!item.locations,
                                              selectedMenu: local!selectedMenu,
                                              crewVal: todecimal(index(local!woItem, "crewVal", 0)) + 0.25,
                                              workAddress: local!woAddr,
                                              selectedHourTypeId: local!woItem.selectedHourTypeId,
                                              timesheetComments: fv!item.timesheetComments,
                                              unitsComments: fv!item.unitsComments,
                                              photoDocId: fv!item.photoDocId,
                                              woCustomFieldsConf: fv!item.woCustomFieldsConf,
                                              woDropDownChoices: fv!item.woDropDownChoices,
                                              woCustomFieldValue: fv!item.woCustomFieldValue
                                            )
                                          )
                                        )
                                      }
                                    )
                                  }
                                ),
                                padding: "EVEN_LESS",
                                shape: "ROUNDED"
                              ),
                              width: "1X",
                              showWhen: local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[1]
                            )
                          }
                        ),
                        a!tagField(
                          tags: {
                            a!tagItem(
                              text: "People",
                              link: a!dynamicLink(
                                saveInto: {
                                  if(
                                    local!isWeekly,
                                    a!save(
                                      ri!weekCrewData,
                                      a!update(
                                        data: ri!weekCrewData,
                                        index: ri!selectedDay,
                                        value: a!update(
                                          data: ri!weekCrewData[ri!selectedDay],
                                          index: "woCrewData",
                                          value: updatearray(
                                            ri!weekCrewData[ri!selectedDay].woCrewData,
                                            local!woIndex,
                                            a!update(
                                              data: local!woItem,
                                              index: "selectedMenu",
                                              value: if(
                                                local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[1],
                                                null,
                                                cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[1]
                                              )
                                            )
                                          )
                                        )
                                      )
                                    ),
                                    a!save(
                                      ri!woCrewData,
                                      updatearray(
                                        ri!woCrewData,
                                        local!woIndex,
                                        a!update(
                                          data: local!woItem,
                                          index: "selectedMenu",
                                          value: if(
                                            local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[1],
                                            null,
                                            cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[1]
                                          )
                                        )
                                      )
                                    )
                                  )
                                }
                              ),
                              backgroundColor: if(
                                local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[1],
                                cons!ATE_TXT_HEX_CARD_BORDER_SELECTED,
                                cons!ATE_TXT_HEX_CARD_STYLE_SHADED
                              ),
                              textColor: if(
                                local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[1],
                                cons!ATE_TXT_HEX_CARD_STYLE_BASICS,
                                null
                              )
                            ),
                            a!tagItem(
                              text: "Units",
                              link: a!dynamicLink(
                                saveInto: {
                                  if(
                                    local!isWeekly,
                                    a!save(
                                      ri!weekCrewData,
                                      a!update(
                                        data: ri!weekCrewData,
                                        index: ri!selectedDay,
                                        value: a!update(
                                          data: ri!weekCrewData[ri!selectedDay],
                                          index: "woCrewData",
                                          value: updatearray(
                                            ri!weekCrewData[ri!selectedDay].woCrewData,
                                            local!woIndex,
                                            a!update(
                                              data: local!woItem,
                                              index: "selectedMenu",
                                              value: if(
                                                local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[2],
                                                null,
                                                cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[2]
                                              )
                                            )
                                          )
                                        )
                                      )
                                    ),
                                    a!save(
                                      ri!woCrewData,
                                      updatearray(
                                        ri!woCrewData,
                                        local!woIndex,
                                        a!update(
                                          data: local!woItem,
                                          index: "selectedMenu",
                                          value: if(
                                            local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[2],
                                            null,
                                            cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[2]
                                          )
                                        )
                                      )
                                    )
                                  )
                                }
                              ),
                              backgroundColor: if(
                                local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[2],
                                cons!ATE_TXT_HEX_CARD_BORDER_SELECTED,
                                cons!ATE_TXT_HEX_CARD_STYLE_SHADED
                              ),
                              textColor: if(
                                local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[2],
                                cons!ATE_TXT_HEX_CARD_STYLE_BASICS,
                                null
                              )
                            ),
                            a!tagItem(
                              text: "File Upload",
                              link: a!dynamicLink(
                                saveInto: {
                                  if(
                                    local!isWeekly,
                                    a!save(
                                      ri!weekCrewData,
                                      a!update(
                                        data: ri!weekCrewData,
                                        index: ri!selectedDay,
                                        value: a!update(
                                          data: ri!weekCrewData[ri!selectedDay],
                                          index: "woCrewData",
                                          value: updatearray(
                                            ri!weekCrewData[ri!selectedDay].woCrewData,
                                            local!woIndex,
                                            a!update(
                                              data: local!woItem,
                                              index: "selectedMenu",
                                              value: if(
                                                local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[3],
                                                null,
                                                cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[3]
                                              )
                                            )
                                          )
                                        )
                                      )
                                    ),
                                    a!save(
                                      ri!woCrewData,
                                      updatearray(
                                        ri!woCrewData,
                                        local!woIndex,
                                        a!update(
                                          data: local!woItem,
                                          index: "selectedMenu",
                                          value: if(
                                            local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[3],
                                            null,
                                            cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[3]
                                          )
                                        )
                                      )
                                    )
                                  )
                                }
                              ),
                              backgroundColor: if(
                                local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[3],
                                cons!ATE_TXT_HEX_CARD_BORDER_SELECTED,
                                cons!ATE_TXT_HEX_CARD_STYLE_SHADED
                              ),
                              textColor: if(
                                local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[3],
                                cons!ATE_TXT_HEX_CARD_STYLE_BASICS,
                                null
                              )
                            ),
                            a!tagItem(
                              showWhen: not(rule!ATE_checkIsNullOrEmptyArray(
                                index(
                                  fv!item.woCustomFieldsConf,
                                  'recordType!{c859c726-925b-479e-9d91-5a281e91de4f}ATE Custom Field Configuration.fields.{d82a783a-5270-4030-a353-0de11a9aa25a}fieldName1En',
                                  null
                                )
                              )),
                              text: cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[4],
                              link: a!dynamicLink(
                                saveInto: {
                                  if(
                                    local!isWeekly,
                                    a!save(
                                      ri!weekCrewData,
                                      a!update(
                                        data: ri!weekCrewData,
                                        index: ri!selectedDay,
                                        value: a!update(
                                          data: ri!weekCrewData[ri!selectedDay],
                                          index: "woCrewData",
                                          value: updatearray(
                                            ri!weekCrewData[ri!selectedDay].woCrewData,
                                            local!woIndex,
                                            a!update(
                                              data: local!woItem,
                                              index: "selectedMenu",
                                              value: if(
                                                local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[4],
                                                null,
                                                cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[4]
                                              )
                                            )
                                          )
                                        )
                                      )
                                    ),
                                    a!save(
                                      ri!woCrewData,
                                      updatearray(
                                        ri!woCrewData,
                                        local!woIndex,
                                        a!update(
                                          data: local!woItem,
                                          index: "selectedMenu",
                                          value: if(
                                            local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[4],
                                            null,
                                            cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[4]
                                          )
                                        )
                                      )
                                    )
                                  )
                                }
                              ),
                              backgroundColor: if(
                                local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[4],
                                cons!ATE_TXT_HEX_CARD_BORDER_SELECTED,
                                cons!ATE_TXT_HEX_CARD_STYLE_SHADED
                              ),
                              textColor: if(
                                local!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[4],
                                cons!ATE_TXT_HEX_CARD_STYLE_BASICS,
                                null
                              )
                            ),
                            
                          }
                        ),
                        rule!ATE_SEC_peopleTabForMteOfflineAppPage3(
                          selectedMenu: local!selectedMenu,
                          today: if(
                            local!isWeekly,
                            ri!selectedDay - 1,
                            ri!today
                          ),
                          woItem: local!woItem,
                          laborCrewTemplateData: ri!laborCrewTemplateData,
                          woCrewData: ri!woCrewData,
                          woIndex: local!woIndex,
                          equipmentCrewTemplateData: ri!equipmentCrewTemplateData,
                          isManual: local!isManual,
                          brandingMap: ri!brandingMap,
                          perWOhourTypeData: local!perWoConfigHourType,
                          rejStOtRefHourData: local!rejectedStOtWOHourTypeData,
                          selectedWoDetails: ri!selectedWoDetails,
                          weekCrewData: ri!weekCrewData,
                          selectedDay: ri!selectedDay,
                          isWeekly: local!isWeekly,
                          payrollOverride: local!woPayrollOverride
                        ),
                        rule!ATE_SEC_unitsTabForMteOfflineAppPage3(
                          selectedMenu: local!selectedMenu,
                          units: fv!item.units,
                          woEstimatedUnits: local!woItem.woEstimatedUnits,
                          brandingMap: ri!brandingMap,
                          locations: reject(
                            fn!isnull,
                            a!defaultValue(index(fv!item, "locations", {}), {})
                          ),
                          selectedWoDetails: ri!selectedWoDetails,
                          woCrewData: ri!woCrewData,
                          selectedDay: ri!selectedDay,
                          woIndex: local!woIndex,
                          weekCrewData: ri!weekCrewData,
                          isWeekly: local!isWeekly,
                          trackLocation: local!trackLocation,
                          isLocationUnique: local!isLocationUnique
                        ),
                        rule!ATE_SEC_fileUploadTabForMteOfflineAppPage3(
                          selectedMenu: local!selectedMenu,
                          woItem: local!woItem,
                          weekCrewData: ri!weekCrewData,
                          selectedDay: ri!selectedDay,
                          isWeekly: local!isWeekly,
                          woCrewData: ri!woCrewData,
                          woIndex: local!woIndex,
                          woAddr: local!woAddr
                        ),
                        rule!ATE_SEC_customFieldsTabForMteOfflineAppPage3(
                          selectedWoCrewData: fv!item,
                          woCrewData: ri!woCrewData,
                          selectedMenu: local!selectedMenu
                        ),
                        if(
                          round(local!crewAvg, 2) <> round(local!equipmentAvg, 2),
                          a!cardLayout(
                            marginBelow: "STANDARD",
                            shape: "SQUARED",
                            style: "ERROR",
                            borderColor: "STANDARD",
                            contents: {
                              a!columnsLayout(
                                columns: {
                                  a!columnLayout(
                                    contents: {
                                      a!richTextDisplayField(
                                        preventWrapping: true(),
                                        labelPosition: "COLLAPSED",
                                        value: {
                                          a!richTextIcon(
                                            icon: "exclamation-triangle",
                                            color: "NEGATIVE",
                                            size: "SMALL"
                                          ),
                                          a!richTextItem(text: "  "),
                                          a!richTextItem(
                                            text: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{a05e6c1d-162e-40ab-9ef1-750d2a5de2ce}Mismatch crew / equipment tally hours..',
                                            color: "NEGATIVE",
                                            style: "STRONG",
                                            size: "SMALL"
                                          )
                                        }
                                      )
                                    }
                                  ),
                                  a!columnLayout(width: "NARROW", contents: {})
                                }
                              )
                            }
                          ),
                          {}
                        )
                      },
                      showWhen: contains(
                        local!selectedWOIdsText,
                        a!flatten(local!woItem.workOrderNumber)
                      ),
                      marginBelow: "STANDARD",
                      style: cons!ATE_TXT_HEX_CARD_STYLE_BASICS,
                      borderColor: cons!ATE_TXT_HEX_CARD_BORDER_SELECTED,
                      shape: "ROUNDED"
                    )
                  }
                )
              )
            }
          ),
          /* Day total */
          a!cardLayout(
            shape: "ROUNDED",
            style: cons!ATE_TXT_HEX_CARD_STYLE_BASICS,
            borderColor: "STANDARD",
            contents: {
              a!columnsLayout(
                columns: {
                  a!columnLayout(
                    contents: {
                      a!richTextDisplayField(
                        labelPosition: "COLLAPSED",
                        value: {
                          a!richTextIcon(
                            icon: "clock-o",
                            color: ri!brandingMap.headingLabelColor
                          ),
                          a!richTextItem(
                            text: "  Day total  ·  " & touniformstring(ri!selectedCount) & " Work Orders  ·  " & touniformstring(length(ri!laborCrewTemplateData)) & " crew members",
                            color: "SECONDARY",
                            size: "SMALL"
                          )
                        }
                      )
                    }
                  ),
                  a!columnLayout(
                    width: "NARROW",
                    contents: {
                      a!richTextDisplayField(
                        labelPosition: "COLLAPSED",
                        value: a!richTextItem(
                          text: touniformstring(ri!dayTotal) & "h",
                          style: "STRONG",
                          size: "MEDIUM_PLUS",
                          color: if(
                            ri!dayTotal >= ri!target,
                            "POSITIVE",
                            if(ri!dayTotal > 0, "ACCENT", "SECONDARY")
                          )
                        )
                      )
                    }
                  )
                }
              )
            }
          )
        }
      )
    }
  )
)

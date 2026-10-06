a!localVariables(
  /* Read the WO row from the same place the Previous/Next buttons save to */
  local!woRow: if(
    ri!isWeekly,
    index(index(index(ri!weekCrewData, ri!selectedDay, {}), "woCrewData", {}), ri!woIndex, {}),
    index(ri!woCrewData, ri!woIndex, {})
  ),
  /* ---------- LABOR ---------- */
  /* Labor pagination */
  local!laborCount: length(index(ri!woItem, "labors", {})),
  /* Page is kept on the WO row (like selectedMenu) so it is not lost when a save rebuilds this tab */
  local!laborStartIndex: a!defaultValue(index(local!woRow, "laborStartIndex", 1), 1),
  local!laborPagingInfo: a!pagingInfo(
    startIndex: if(local!laborStartIndex > local!laborCount, 1, local!laborStartIndex),
    batchSize: 5
  ),
  local!laborDataSubset: a!dataSubset(
    startIndex: local!laborPagingInfo.startIndex,
    batchSize: local!laborPagingInfo.batchSize,
    totalCount: length(index(ri!woItem, "labors", "")),
    data: index(
      ri!woItem.labors,
      enumerate(
        min(
          local!laborPagingInfo.batchSize,
          length(index(ri!woItem, "labors", "")) - local!laborPagingInfo.startIndex + 1
        )
      ) + local!laborPagingInfo.startIndex,
      {}
    )
  ),

  /* ---------- EQUIPMENT ---------- */
  /* Equipment pagination */
  local!equipmentCount: length(index(ri!woItem, "equipments", {})),
  /* Page is kept on the WO row (like selectedMenu) so it is not lost when a save rebuilds this tab */
  local!equipmentStartIndex: a!defaultValue(index(local!woRow, "equipmentStartIndex", 1), 1),
  local!equipmentPagingInfo: a!pagingInfo(
    startIndex: if(local!equipmentStartIndex > local!equipmentCount, 1, local!equipmentStartIndex),
    batchSize: 5
  ),
  local!equipmentDataSubset: a!dataSubset(
    startIndex: local!equipmentPagingInfo.startIndex,
    batchSize: local!equipmentPagingInfo.batchSize,
    totalCount: length(index(ri!woItem, "equipments", "")),
    data: index(
      ri!woItem.equipments,
      enumerate(
        min(
          local!equipmentPagingInfo.batchSize,
          length(index(ri!woItem, "equipments", "")) - local!equipmentPagingInfo.startIndex + 1
        )
      ) + local!equipmentPagingInfo.startIndex,
      {}
    )
  ),

  {
    /*SECTION  */
    a!sectionLayout(
    label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{388c7775-5202-4e98-b794-8b35d64f0f69}People',
    labelSize: "SMALL",
    labelColor: ri!brandingMap.headingLabelColor,
    showWhen: ri!selectedMenu = cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[1],
    contents: {
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: a!richTextItem(
          text: "LABOR · " & upper(text(ri!today, "DDDD")),
          color: "SECONDARY",
          size: "SMALL",
          style: "STRONG"
        )
      ),
      a!sideBySideLayout(
        marginBelow: "STANDARD",
        items: {
          a!sideBySideItem(
            item: a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              value: {
                a!richTextIcon(
                  icon: "info-circle",
                  color: cons!ROME_TEXT_HEX_ORANGE,
                  size: "SMALL"
                ),
                a!richTextItem(
                  text: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{0803f673-1031-4a47-a811-f08cb6a0b505}Employee ID (last 4 of ID, last name) must be entered exactly, or hours won''t be saved..',
                  color: cons!ROME_TEXT_HEX_ORANGE,
                  size: "SMALL",
                  style: "EMPHASIS"
                )
              }
            ),
            width: "8X",
            showWhen: or(
              a!forEach(
                items: if(
                  ri!isWeekly,
                  ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors,
                  ri!woCrewData[ri!woIndex].labors
                ),
                expression: a!defaultValue(
                  index(fv!item, "isAdhoc", false()),
                  false()
                )
              )
            )
          ),
          a!sideBySideItem(
            item: a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              align: "RIGHT",
              value: {
                a!richTextIcon(
                  icon: "plus-circle",
                  size: "STANDARD",
                  color: cons!ROME_TEXT_HEX_ORANGE
                ),
                a!richTextItem(
                  text: " Add Employee",
                  style: "STRONG",
                  color: cons!ROME_TEXT_HEX_ORANGE,
                  linkStyle: "STANDALONE",
                  link: a!dynamicLink(
                    saveInto: {
                      if(
                        ri!isWeekly,
                        /* WEEKLY */
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
                                ri!woIndex,
                                a!update(
                                  data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                  index: "labors",
                                  value: insert(
                                    ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors,
                                    a!map(
                                      workOrderNumber: ri!woItem.workOrderNumber,
                                      employeeId: "",
                                      employeeName: null,
                                      jobDescription: null,
                                      isAdhoc: true(),
                                      addToCrewTemplate: false(),
                                      payrollConfigOverrideId: null,
                                      hourTypes: {
                                        a!map(
                                          hourTypeId: tointeger(
                                            cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[1]
                                          ),
                                          hours: null,
                                          payrollOverrideRate: null
                                        ),
                                        a!map(
                                          hourTypeId: tointeger(
                                            cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[2]
                                          ),
                                          hours: null,
                                          payrollOverrideRate: null
                                        )
                                      }
                                    ),
                                    1
                                  )
                                )
                              )
                            )
                          )
                        ),
                        /* DAILY */
                        a!save(
                          ri!woCrewData,
                          updatearray(
                            ri!woCrewData,
                            ri!woIndex,
                            a!update(
                              data: ri!woCrewData[ri!woIndex],
                              index: "labors",
                              value: insert(
                                ri!woCrewData[ri!woIndex].labors,
                                a!map(
                                  workOrderNumber: ri!woItem.workOrderNumber,
                                  employeeId: "",
                                  employeeName: null,
                                  jobDescription: null,
                                  isAdhoc: true(),
                                  addToCrewTemplate: false(),
                                  payrollConfigOverrideId: null,
                                  hourTypes: {
                                    a!map(
                                      hourTypeId: tointeger(
                                        cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[1]
                                      ),
                                      hours: null,
                                      payrollOverrideRate: null
                                    ),
                                    a!map(
                                      hourTypeId: tointeger(
                                        cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[2]
                                      ),
                                      hours: null,
                                      payrollOverrideRate: null
                                    )
                                  }
                                ),
                                1
                              )
                            )
                          )
                        )
                      )
                    }
                  ),
                  size: "STANDARD",

                )
              }
            ),
            width: "4X"
          )
        }
      ),
      a!forEach(
        items: local!laborDatasubset,
        expression: a!localVariables(
          local!lIndex: fv!index + local!laborPagingInfo.startIndex - 1,
          local!isAdhoc: index(fv!item, "isAdhoc", false()),
          local!addToCrewTemplate: a!defaultValue(
            index(fv!item, "addToCrewTemplate", false()),
            false()
          ),
          local!employeeName: index(fv!item, "employeeName", ""),
          local!jobDescription: index(fv!item, "jobDescription", ""),
          local!laborId: index(fv!item, "employeeId", ""),
          local!initials: if(
            or(
              local!isAdhoc,
              isnull(local!employeeName),
              local!employeeName = ""
            ),
            "?",
            upper(left(local!employeeName, 1)) & upper(
              left(
                right(
                  local!employeeName,
                  len(local!employeeName) - search(" ", local!employeeName & " ", 1)
                ),
                1
              )
            )
          ),
          local!hourTypes: if(
            ri!isWeekly,
            ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex].hourTypes,
            ri!woCrewData[ri!woIndex].labors[local!lIndex].hourTypes
          ),
          local!straight: index(
            local!hourTypes,
            wherecontains(
              cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[1],
              tointeger(index(local!hourTypes, "hourTypeId", {}))
            ),
            {}
          ),
          local!overtime: index(
            local!hourTypes,
            wherecontains(
              cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[2],
              tointeger(index(local!hourTypes, "hourTypeId", {}))
            ),
            {}
          ),
          local!straightHours: if(
            length(local!straight) = 0,
            0,
            index(local!straight[1], "hours", 0)
          ),
          local!overtimeHours: if(
            length(local!overtime) = 0,
            0,
            index(local!overtime[1], "hours", 0)
          ),
          local!straightIndex: wherecontains(
            cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[1],
            tointeger(index(local!hourTypes, "hourTypeId", {}))
          ),
          local!overtimeIndex: wherecontains(
            cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[2],
            tointeger(index(local!hourTypes, "hourTypeId", {}))
          ),
          a!cardLayout(
            shape: "ROUNDED",
            marginBelow: "STANDARD",
            style: cons!ATE_TXT_HEX_CARD_STYLE_SHADED & "50",
            contents: {
              a!columnsLayout(
                stackWhen: "NEVER",
                columns: {
                  /* Employee Initials */
                  a!columnLayout(
                    width: "1X",
                    contents: {
                      a!cardLayout(
                        contents: a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          preventWrapping: true,
                          align: "CENTER",
                          value: a!richTextItem(
                            text: local!initials,
                            style: "STRONG",
                            size: "SMALL"
                          )
                        ),
                        shape: "ROUNDED",
                        padding: "EVEN_LESS",
                        height: "AUTO",
                        style: cons!ATE_TXT_HEX_CARD_STYLE_SHADED & "FF"
                      )
                    },
                    showWhen: not(
                      or(
                        local!isAdhoc,
                        isnull(local!employeeName),
                        local!employeeName = ""
                      )
                    )
                  ),
                  a!columnLayout(
                    width: "7X",
                    contents: if(
                      local!isAdhoc,
                      {
                        a!sideBySideLayout(
                          alignVertical: "MIDDLE",
                          spacing: "DENSE",
                          marginBelow: "EVEN_LESS",
                          items: {
                            a!sideBySideItem(
                              width: "5X",
                              item: a!richTextDisplayField(
                                labelPosition: "COLLAPSED",
                                marginBelow: "NONE",
                                value: a!richTextItem(
                                  text: { "Employee ID, Last Name " },
                                  style: "STRONG"
                                )
                              )
                            ),
                            a!sideBySideItem(
                              width: "3X",
                              item: a!checkboxField(
                                choicePosition: "START",
                                choiceLabels: { " Add to crew template   " },
                                choiceValues: { true() },
                                labelPosition: "COLLAPSED",
                                value: if(
                                  a!defaultValue(
                                    toboolean(
                                      index(fv!item, "addToCrewTemplate", false())
                                    ),
                                    false()
                                  ),
                                  { true() },
                                  {}
                                ),
                                saveInto: {
                                  if(
                                    ri!isWeekly,
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
                                            ri!woIndex,
                                            a!update(
                                              data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                              index: "labors",
                                              value: updatearray(
                                                ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors,
                                                local!lIndex,
                                                a!update(
                                                  data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex],
                                                  index: "addToCrewTemplate",
                                                  value: a!defaultValue(
                                                    toboolean(a!isNotNullOrEmpty(save!value)),
                                                    false()
                                                  )
                                                )
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
                                        ri!woIndex,
                                        a!update(
                                          data: ri!woCrewData[ri!woIndex],
                                          index: "labors",
                                          value: updatearray(
                                            ri!woCrewData[ri!woIndex].labors,
                                            local!lIndex,
                                            a!update(
                                              data: ri!woCrewData[ri!woIndex].labors[local!lIndex],
                                              index: "addToCrewTemplate",
                                              value: a!defaultValue(
                                                toboolean(a!isNotNullOrEmpty(save!value)),
                                                false()
                                              )
                                            )
                                          )
                                        )
                                      )
                                    )
                                  )
                                }
                              )
                            ),
                            a!sideBySideItem(
                              /*width: "1X",*/
                              showWhen: local!isAdhoc,
                              item: a!richTextDisplayField(
                                labelPosition: "COLLAPSED",
                                marginBelow: "NONE",
                                align: "CENTER",
                                value: a!richTextIcon(
                                  icon: "TRASH",
                                  size: "MEDIUM",
                                  color: "NEGATIVE",
                                  linkStyle: "STANDALONE",
                                  link: a!dynamicLink(
                                    saveInto: {
                                      if(
                                        ri!isWeekly,
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
                                                ri!woIndex,
                                                a!update(
                                                  data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                                  index: "labors",
                                                  value: remove(
                                                    ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors,
                                                    local!lIndex
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
                                            ri!woIndex,
                                            a!update(
                                              data: ri!woCrewData[ri!woIndex],
                                              index: "labors",
                                              value: remove(
                                                ri!woCrewData[ri!woIndex].labors,
                                                local!lIndex
                                              )
                                            )
                                          )
                                        )
                                      )
                                    }
                                  )
                                )
                              )
                            )
                          }
                        ),
                        /* Employee ID Input */
                        a!textField(
                          label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{0b055582-4137-4067-b8a1-9221b5c157fe}Employee ID, Last Name',
                          labelPosition: "COLLAPSED",
                          placeholder: "Eg:1234, Doe",
                          value: local!laborId,
                          refreshAfter: "UNFOCUS",
                          required: true,
                          instructions: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{351a5cc9-0220-4155-b994-313b482cc903}Employee ID is required before entering hours..',
                          saveInto: {
                            if(
                              ri!isWeekly,
                              /* WEEKLY */
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
                                      ri!woIndex,
                                      a!update(
                                        data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                        index: "labors",
                                        value: updatearray(
                                          ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors,
                                          local!lIndex,
                                          a!update(
                                            data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex],
                                            index: "employeeId",
                                            value: save!value
                                          )
                                        )
                                      )
                                    )
                                  )
                                )
                              ),
                              /* DAILY */
                              a!save(
                                ri!woCrewData,
                                updatearray(
                                  ri!woCrewData,
                                  ri!woIndex,
                                  a!update(
                                    data: ri!woCrewData[ri!woIndex],
                                    index: "labors",
                                    value: updatearray(
                                      ri!woCrewData[ri!woIndex].labors,
                                      local!lIndex,
                                      a!update(
                                        data: ri!woCrewData[ri!woIndex].labors[local!lIndex],
                                        index: "employeeId",
                                        value: save!value
                                      )
                                    )
                                  )
                                )
                              )
                            )
                          },
                          validations: rule!ATE_RULE_offlineValidationForPeopleLastName(value: local!laborId)
                        )
                      },
                      {
                        a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          marginBelow: "NONE",
                          value: a!richTextItem(
                            text: local!employeeName,
                            style: "STRONG",
                            size: "MEDIUM"
                          )
                        ),
                        a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          preventWrapping: true,
                          value: {
                            a!richTextItem(
                              text: right(local!laborId, 4),
                              color: "SECONDARY",
                              size: "SMALL"
                            ),
                            a!richTextItem(
                              text: " · ",
                              color: "SECONDARY",
                              size: "SMALL"
                            ),
                            a!richTextItem(
                              text: local!jobDescription,
                              color: "SECONDARY",
                              size: "SMALL"
                            )
                          }
                        )
                      }
                    )
                  )
                }
              ),
              a!sideBySideLayout(
                items: {
                  /* STRAIGHT */
                  a!sideBySideItem(
                    a!textField(
                      label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{357eaa30-3c51-43d3-9203-6770f1fb3e70}Straight',
                      value: index(local!straight, "hours", ""),
                      refreshAfter: "UNFOCUS",
                      placeholder: "0",
                      saveInto: {
                        a!save(ri!isManual, true()),
                        if(
                          ri!isWeekly,
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
                                  ri!woIndex,
                                  a!update(
                                    data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                    index: "labors",
                                    value: updatearray(
                                      ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors,
                                      local!lIndex,
                                      a!update(
                                        data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex],
                                        index: "hourTypes",
                                        value: updatearray(
                                          ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex].hourTypes,
                                          local!straightIndex,
                                          a!update(
                                            data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex].hourTypes[local!straightIndex],
                                            index: "hours",
                                            value: if(
                                              a!isNotNullOrEmpty(save!value),
                                              todecimal(save!value),
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
                          ),
                          a!save(
                            ri!woCrewData,
                            updatearray(
                              ri!woCrewData,
                              ri!woIndex,
                              a!update(
                                data: ri!woCrewData[ri!woIndex],
                                index: "labors",
                                value: updatearray(
                                  ri!woCrewData[ri!woIndex].labors,
                                  local!lIndex,
                                  a!update(
                                    data: ri!woCrewData[ri!woIndex].labors[local!lIndex],
                                    index: "hourTypes",
                                    value: updatearray(
                                      ri!woCrewData[ri!woIndex].labors[local!lIndex].hourTypes,
                                      local!straightIndex,
                                      a!update(
                                        data: ri!woCrewData[ri!woIndex].labors[local!lIndex].hourTypes[local!straightIndex],
                                        index: "hours",
                                        value: if(
                                          a!isNotNullOrEmpty(save!value),
                                          todecimal(save!value),
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
                      validations: {
                        rule!ATE_UTIL_validateHour(
                          hourTypeId: cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[1],
                          hours: index(local!straight, "hours", 0)
                        )
                      }
                    )
                  ),
                  /* OVERTIME */
                  a!sideBySideItem(
                    a!textField(
                      label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{ded7768f-481f-4fad-a4f9-0e48bfbc0bc4}Overtime',
                      value: index(local!overtime, "hours", ""),
                      placeholder: "0",
                      refreshAfter: "UNFOCUS",
                      saveInto: {
                        a!save(ri!isManual, true()),
                        if(
                          ri!isWeekly,
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
                                  ri!woIndex,
                                  a!update(
                                    data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                    index: "labors",
                                    value: updatearray(
                                      ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors,
                                      local!lIndex,
                                      a!update(
                                        data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex],
                                        index: "hourTypes",
                                        value: updatearray(
                                          ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex].hourTypes,
                                          local!overtimeIndex,
                                          a!update(
                                            data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex].hourTypes[local!overtimeIndex],
                                            index: "hours",
                                            value: if(
                                              a!isNotNullOrEmpty(save!value),
                                              todecimal(save!value),
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
                          ),
                          a!save(
                            ri!woCrewData,
                            updatearray(
                              ri!woCrewData,
                              ri!woIndex,
                              a!update(
                                data: ri!woCrewData[ri!woIndex],
                                index: "labors",
                                value: updatearray(
                                  ri!woCrewData[ri!woIndex].labors,
                                  local!lIndex,
                                  a!update(
                                    data: ri!woCrewData[ri!woIndex].labors[local!lIndex],
                                    index: "hourTypes",
                                    value: updatearray(
                                      ri!woCrewData[ri!woIndex].labors[local!lIndex].hourTypes,
                                      local!overtimeIndex,
                                      a!update(
                                        data: ri!woCrewData[ri!woIndex].labors[local!lIndex].hourTypes[local!overtimeIndex],
                                        index: "hours",
                                        value: if(
                                          a!isNotNullOrEmpty(save!value),
                                          todecimal(save!value),
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
                      validations: {
                        rule!ATE_UTIL_validateHour(
                          hourTypeId: {},
                          hours: index(local!overtime, "hours", 0)
                        )
                      }
                    )
                  ),
                  a!sideBySideItem(
                    width: "MINIMIZE",
                    item: {
                      a!richTextDisplayField(
                        marginAbove: "MORE",
                        align: "CENTER",
                        value: {
                          a!richTextIcon(
                            icon: "plus",
                            size: "MEDIUM",
                            link: {
                              a!dynamicLink(
                                saveInto: {
                                  if(
                                    /* WEEKLY */
                                    ri!isWeekly,
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
                                            ri!woIndex,
                                            a!update(
                                              data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                              index: "labors",
                                              value: updatearray(
                                                ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors,
                                                local!lIndex,
                                                a!update(
                                                  data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex],
                                                  index: "hourTypes",
                                                  value: append(
                                                    ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex].hourTypes,
                                                    a!map(
                                                      hourTypeId: null,
                                                      hours: null,
                                                      payrollOverrideRate: index(
                                                        reject(
                                                          a!isNullOrEmpty(_),
                                                          index(
                                                            local!hourTypes,
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
                                    ),
                                    /* DAILY */
                                    a!save(
                                      ri!woCrewData,
                                      updatearray(
                                        ri!woCrewData,
                                        ri!woIndex,
                                        a!update(
                                          data: ri!woCrewData[ri!woIndex],
                                          index: "labors",
                                          value: updatearray(
                                            ri!woCrewData[ri!woIndex].labors,
                                            local!lIndex,
                                            a!update(
                                              data: ri!woCrewData[ri!woIndex].labors[local!lIndex],
                                              index: "hourTypes",
                                              value: append(
                                                ri!woCrewData[ri!woIndex].labors[local!lIndex].hourTypes,
                                                a!map(
                                                  hourTypeId: null,
                                                  hours: null,
                                                  payrollOverrideRate: index(
                                                    reject(
                                                      a!isNullOrEmpty(_),
                                                      index(
                                                        local!hourTypes,
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
                                }
                              )
                            },
                            linkStyle: "STANDALONE",
                            color: cons!ROME_TEXT_HEX_ORANGE
                          )
                        }
                      )
                    }
                  )
                }
              ),
              a!forEach(
                items: reject(
                  fn!isnull,
                  a!forEach(
                    items: local!hourTypes,
                    expression: if(
                      contains(
                        {
                          cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[1],
                          cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[2]
                        },
                        tointeger(fv!item.hourTypeId)
                      ),
                      null(),
                      a!map(originalIndex: fv!index, data: fv!item)
                    )
                  )
                ),
                expression: a!localVariables(
                  local!hourIndex: fv!item.originalIndex,
                  local!hour: fv!item.data,
                  local!rejectedStOtWOHourTypeData: index(
                    ri!rejStOtRefHourData,
                    wherecontains(
                      tointeger(
                        ri!perWOhourTypeData['recordType!{0426e3e6-4546-41d3-8b1b-85aebf27b019}ATE L Configuration Hour Type.fields.{e555c2c1-b8bf-48d6-a38a-6ddd061553eb}hourTypeId']
                      ),
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
                  a!sideBySideLayout(
                    marginAbove: "NONE",
                    items: {
                      /* Hour Type Dropdown */
                      a!sideBySideItem(
                        width: "6X",
                        item: a!dropdownField(
                          placeholder: "--- Select Hour Type ---",
                          choiceLabels: index(
                            local!rejectedStOtWOHourTypeData,
                            'recordType!{0ba490b0-1715-4af0-a10a-1c8f99d9f481}ROME Ref Hour Type.fields.{b27c18e1-9c0c-4709-8944-9e79b07bb027}name',
                            {}
                          ),
                          choiceValues: index(
                            local!rejectedStOtWOHourTypeData,
                            'recordType!{0ba490b0-1715-4af0-a10a-1c8f99d9f481}ROME Ref Hour Type.fields.{f343f388-81a2-4036-9c0d-c8e692e65cc3}hourTypeId',
                            {}
                          ),
                          value: local!hour.hourTypeId,
                          saveInto: {
                            if(
                              ri!isWeekly,
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
                                      ri!woIndex,
                                      a!update(
                                        data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                        index: "labors",
                                        value: updatearray(
                                          ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors,
                                          local!lIndex,
                                          a!update(
                                            data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex],
                                            index: "hourTypes",
                                            value: updatearray(
                                              ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex].hourTypes,
                                              local!hourIndex,
                                              a!update(
                                                data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex].hourTypes[local!hourIndex],
                                                index: "hourTypeId",
                                                value: save!value
                                              )
                                            )
                                          )
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
                                  ri!woIndex,
                                  a!update(
                                    data: ri!woCrewData[ri!woIndex],
                                    index: "labors",
                                    value: updatearray(
                                      ri!woCrewData[ri!woIndex].labors,
                                      local!lIndex,
                                      a!update(
                                        data: ri!woCrewData[ri!woIndex].labors[local!lIndex],
                                        index: "hourTypes",
                                        value: updatearray(
                                          ri!woCrewData[ri!woIndex].labors[local!lIndex].hourTypes,
                                          local!hourIndex,
                                          a!update(
                                            data: ri!woCrewData[ri!woIndex].labors[local!lIndex].hourTypes[local!hourIndex],
                                            index: "hourTypeId",
                                            value: save!value
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
                      ),
                      /* Hours */
                      a!sideBySideItem(
                        width: "1X",
                        item: a!textField(
                          value: local!hour.hours,
                          refreshAfter: "UNFOCUS",
                          placeholder: "0",
                          saveInto: {
                            a!save(ri!isManual, true),
                            if(
                              ri!isWeekly,
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
                                      ri!woIndex,
                                      a!update(
                                        data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                        index: "labors",
                                        value: updatearray(
                                          ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors,
                                          local!lIndex,
                                          a!update(
                                            data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex],
                                            index: "hourTypes",
                                            value: updatearray(
                                              ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex].hourTypes,
                                              local!hourIndex,
                                              a!update(
                                                data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex].hourTypes[local!hourIndex],
                                                index: "hours",
                                                value: if(
                                                  a!isNotNullOrEmpty(save!value),
                                                  todecimal(save!value),
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
                              ),
                              a!save(
                                ri!woCrewData,
                                updatearray(
                                  ri!woCrewData,
                                  ri!woIndex,
                                  a!update(
                                    data: ri!woCrewData[ri!woIndex],
                                    index: "labors",
                                    value: updatearray(
                                      ri!woCrewData[ri!woIndex].labors,
                                      local!lIndex,
                                      a!update(
                                        data: ri!woCrewData[ri!woIndex].labors[local!lIndex],
                                        index: "hourTypes",
                                        value: updatearray(
                                          ri!woCrewData[ri!woIndex].labors[local!lIndex].hourTypes,
                                          local!hourIndex,
                                          a!update(
                                            data: ri!woCrewData[ri!woIndex].labors[local!lIndex].hourTypes[local!hourIndex],
                                            index: "hours",
                                            value: if(
                                              a!isNotNullOrEmpty(save!value),
                                              todecimal(save!value),
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
                          }
                        )
                      ),
                      a!sideBySideItem(
                        width: "MINIMIZE",
                        item: a!richTextDisplayField(
                          value: a!richTextIcon(
                            icon: "TRASH",
                            color: "NEGATIVE",
                            linkStyle: "STANDALONE",
                            link: a!dynamicLink(
                              saveInto: {
                                if(
                                  ri!isWeekly,
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
                                          ri!woIndex,
                                          a!update(
                                            data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                            index: "labors",
                                            value: updatearray(
                                              ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors,
                                              local!lIndex,
                                              a!update(
                                                data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex],
                                                index: "hourTypes",
                                                value: remove(
                                                  ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex].hourTypes,
                                                  local!hourIndex
                                                )
                                              )
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
                                      ri!woIndex,
                                      a!update(
                                        data: ri!woCrewData[ri!woIndex],
                                        index: "labors",
                                        value: updatearray(
                                          ri!woCrewData[ri!woIndex].labors,
                                          local!lIndex,
                                          a!update(
                                            data: ri!woCrewData[ri!woIndex].labors[local!lIndex],
                                            index: "hourTypes",
                                            value: remove(
                                              ri!woCrewData[ri!woIndex].labors[local!lIndex].hourTypes,
                                              local!hourIndex
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
                        )
                      )
                    }
                  )
                )
              ),
              /* ---------- LABOR PAYROLL OVERRIDE ---------- */
              rule!ATE_SEC_offlineLaborPayrollOverride(
                payrollOverride: ri!payrollOverride,
                brandingMap: ri!brandingMap,
                isWeekly: ri!isWeekly,
                selectedDay: ri!selectedDay,
                weekCrewData: ri!weekCrewData,
                woCrewData: ri!woCrewData,
                woIndex: ri!woIndex,
                laborIndex: local!lIndex,
                woItem: ri!woItem,
                rejStOtRefHourData: ri!rejStOtRefHourData
              )
            }
          )
        )
      ),
      a!sideBySideLayout(
        items: {
          a!sideBySideItem(
            item: a!buttonArrayLayout(
              buttons: {
                a!buttonWidget(
                  label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{4b63321a-0d49-4443-86e2-7fc3a1735ac6}Previous',
                  style: "LINK",
                  color: cons!ROME_TEXT_HEX_ORANGE,
                  disabled: local!laborPagingInfo.startIndex = 1,
                  saveInto: {
                    if(
                      ri!isWeekly,
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
                              ri!woIndex,
                              a!update(
                                data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                index: "laborStartIndex",
                                value: max(1, local!laborPagingInfo.startIndex - local!laborPagingInfo.batchSize)
                              )
                            )
                          )
                        )
                      ),
                      a!save(
                        ri!woCrewData,
                        updatearray(
                          ri!woCrewData,
                          ri!woIndex,
                          a!update(
                            data: ri!woCrewData[ri!woIndex],
                            index: "laborStartIndex",
                            value: max(1, local!laborPagingInfo.startIndex - local!laborPagingInfo.batchSize)
                          )
                        )
                      )
                    )
                  }
                )
              },
              align: "END"
            ),
            width: "3X"
          ),
          a!sideBySideItem(
            item: a!richTextDisplayField(
              align: "CENTER",
              value: {
                a!richTextItem(
                  text: "Page " & ceiling(
                    local!laborPagingInfo.startIndex / local!laborPagingInfo.batchSize
                  ) & " of " & ceiling(
                    local!laborDataSubset.totalCount / local!laborPagingInfo.batchSize
                  ),
                  style: "STRONG"
                )
              }
            ),
            width: "2X"
          ),
          a!sideBySideItem(
            item: a!buttonArrayLayout(
              buttons: {
                a!buttonWidget(
                  label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{27bb4ba6-87e1-4f07-bc09-5fc7f95fe30f}Next',
                  style: "LINK",
                  color: cons!ROME_TEXT_HEX_ORANGE,
                  disabled: local!laborPagingInfo.startIndex + local!laborPagingInfo.batchSize > local!laborDataSubset.totalCount,
                  saveInto: {
                    if(
                      ri!isWeekly,
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
                              ri!woIndex,
                              a!update(
                                data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                index: "laborStartIndex",
                                value: local!laborPagingInfo.startIndex + local!laborPagingInfo.batchSize
                              )
                            )
                          )
                        )
                      ),
                      a!save(
                        ri!woCrewData,
                        updatearray(
                          ri!woCrewData,
                          ri!woIndex,
                          a!update(
                            data: ri!woCrewData[ri!woIndex],
                            index: "laborStartIndex",
                            value: local!laborPagingInfo.startIndex + local!laborPagingInfo.batchSize
                          )
                        )
                      )
                    )
                  },

                )
              },
              align: "START"
            ),
            width: "3X"
          )
        }
      ),
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: a!richTextItem(
          text: "EQUIPMENT · " & upper(text(ri!today, "DDDD")),
          color: "SECONDARY",
          size: "SMALL",
          style: "STRONG"
        )
      ),
      a!sideBySideLayout(
        marginBelow: "STANDARD",
        items: {
          a!sideBySideItem(
            item: a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              value: {
                a!richTextIcon(
                  icon: "info-circle",
                  color: cons!ROME_TEXT_HEX_ORANGE
                ),
                a!richTextItem(
                  text: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{c0853e5d-f093-45ea-89cf-92db8e175884}Equipment ID must be entered exactly, or hours won''t be saved..',
                  color: cons!ROME_TEXT_HEX_ORANGE,
                  size: "SMALL",
                  style: "EMPHASIS"
                )
              }
            ),
            width: "8X",
            showWhen: or(
              a!forEach(
                items: if(
                  ri!isWeekly,
                  ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].equipments,
                  ri!woCrewData[ri!woIndex].equipments
                ),
                expression: a!defaultValue(
                  index(fv!item, "isAdhoc", false()),
                  false()
                )
              )
            )
          ),
          a!sideBySideItem(
            item: a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              align: "RIGHT",
              value: {
                a!richTextIcon(
                  icon: "plus-circle",
                  size: "STANDARD",
                  color: cons!ROME_TEXT_HEX_ORANGE,

                ),
                a!richTextItem(
                  text: " Add Equipment",
                  style: "STRONG",
                  size: "STANDARD",
                  color: cons!ROME_TEXT_HEX_ORANGE,
                  linkStyle: "STANDALONE",
                  link: a!dynamicLink(
                    saveInto: {
                      if(
                        ri!isWeekly,
                        /* WEEKLY */
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
                                ri!woIndex,
                                a!update(
                                  data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                  index: "equipments",
                                  value: insert(
                                    ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].equipments,
                                    a!map(
                                      workOrderNumber: ri!woItem.workOrderNumber,
                                      equipmentId: "",
                                      equipmentName: null,
                                      isAdhoc: true(),
                                      addToCrewTemplate: false(),
                                      hours: null,
                                      payrollConfigOverrideId: null,
                                      payrollOverrideRate: null
                                    ),
                                    1
                                  )
                                )
                              )
                            )
                          )
                        ),
                        /* DAILY */
                        a!save(
                          ri!woCrewData,
                          updatearray(
                            ri!woCrewData,
                            ri!woIndex,
                            a!update(
                              data: ri!woCrewData[ri!woIndex],
                              index: "equipments",
                              value: insert(
                                ri!woCrewData[ri!woIndex].equipments,
                                a!map(
                                  workOrderNumber: ri!woItem.workOrderNumber,
                                  equipmentId: "",
                                  equipmentName: null,
                                  isAdhoc: true(),
                                  addToCrewTemplate: false(),
                                  hours: null,
                                  payrollConfigOverrideId: null,
                                  payrollOverrideRate: null
                                ),
                                1
                              )
                            )
                          )
                        )
                      )
                    }
                  )
                )
              }
            ),
            width: "4X"
          )
        }
      ),
      a!forEach(
        items: local!equipmentDataSubset,
        expression: a!localVariables(
          local!eIndex: fv!index + local!equipmentPagingInfo.startIndex - 1,
          local!isAdhoc: index(fv!item, "isAdhoc", false()),
          local!addToCrewTemplate: a!defaultValue(
            index(fv!item, "addToCrewTemplate", false()),
            false()
          ),
          local!equipmentId: if(
            local!isAdhoc,
            index(fv!item, "equipmentId", ""),
            index(
              ri!equipmentCrewTemplateData['recordType!{39493776-6005-4f99-adc0-4690c2177ef4}ATE Equipment Crew Template.fields.{22247106-0086-4043-a0b9-224ba13c483c}equipmentId'],
              local!eIndex,
              {}
            )
          ),
          local!equipmentName: tostring(index(fv!item, "equipmentName", "")),
          local!equipNameTrim: trim(split(local!equipmentName, "-")),
          local!displayName: if(
            length(local!equipNameTrim) >= 2,
            local!equipNameTrim[2],
            index(local!equipNameTrim, 1, "")
          ),
          local!initials: if(
            or(
              local!isAdhoc,
              isnull(local!displayName),
              local!displayName = ""
            ),
            "?",
            upper(left(local!displayName, 1)) & upper(
              left(
                right(
                  local!displayName,
                  max(
                    len(local!displayName) - search(" ", local!displayName & " ", 1),
                    0
                  )
                ),
                1
              )
            )
          ),
          a!cardLayout(
            shape: "ROUNDED",
            marginBelow: "STANDARD",
            style: cons!ATE_TXT_HEX_CARD_STYLE_SHADED & "50",
            borderColor: "STANDARD",
            contents: {
              /* Equipment Header */
              a!columnsLayout(
                stackWhen: "NEVER",
                columns: {
                  a!columnLayout(
                    width: "2X",
                    showWhen: not(
                      or(
                        local!isAdhoc,
                        isnull(local!displayName),
                        local!displayName = ""
                      )
                    ),
                    contents: {
                      a!cardLayout(
                        contents: a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          align: "CENTER",
                          value: a!richTextItem(
                            text: local!initials,
                            style: "STRONG",
                            size: "SMALL"
                          )
                        ),
                        shape: "ROUNDED",
                        padding: "EVEN_LESS",
                        style: cons!ATE_TXT_HEX_CARD_STYLE_SHADED & "FF"
                      )
                    }
                  ),
                  a!columnLayout(
                    width: "7X",
                    contents: if(
                      local!isAdhoc,
                      {
                        a!textField(
                          label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{27f065b6-abf1-402c-b91f-00038d72bca5}Enter Equipment ID:',
                          marginAbove: "NONE",
                          labelPosition: "ABOVE",
                          placeholder: "Eg:00000000",
                          value: tostring(local!equipmentId),
                          refreshAfter: "UNFOCUS",
                          instructions: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{dd960c69-b972-4fd0-b093-5288a5f69b2d}Equipment ID is required before entering hours..',
                          /*required: true,*/
                          saveInto: {
                            if(
                              ri!isWeekly,
                              /* WEEKLY */
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
                                      ri!woIndex,
                                      a!update(
                                        data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                        index: "equipments",
                                        value: updatearray(
                                          ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].equipments,
                                          local!eIndex,
                                          a!update(
                                            data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].equipments[local!eIndex],
                                            index: "equipmentId",
                                            value: save!value
                                          )
                                        )
                                      )
                                    )
                                  )
                                )
                              ),
                              /* DAILY */
                              a!save(
                                ri!woCrewData,
                                updatearray(
                                  ri!woCrewData,
                                  ri!woIndex,
                                  a!update(
                                    data: ri!woCrewData[ri!woIndex],
                                    index: "equipments",
                                    value: updatearray(
                                      ri!woCrewData[ri!woIndex].equipments,
                                      local!eIndex,
                                      a!update(
                                        data: ri!woCrewData[ri!woIndex].equipments[local!eIndex],
                                        index: "equipmentId",
                                        value: save!value
                                      )
                                    )
                                  )
                                )
                              )
                            )
                          },
                          validations: {}
                        ),
                        a!checkboxField(
                          label: "",
                          labelPosition: "COLLAPSED",
                          marginAbove: "NONE",
                          marginBelow: "NONE",
                          choiceLabels: { "Add to crew template" },
                          choiceValues: { true() },
                          value: if(local!addToCrewTemplate, { true() }, {}),
                          saveInto: {
                            if(
                              ri!isWeekly,
                              /* WEEKLY */
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
                                      ri!woIndex,
                                      a!update(
                                        data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                        index: "equipments",
                                        value: updatearray(
                                          ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].equipments,
                                          local!eIndex,
                                          a!update(
                                            data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].equipments[local!eIndex],
                                            index: "addToCrewTemplate",
                                            value: a!isNotNullOrEmpty(save!value)
                                          )
                                        )
                                      )
                                    )
                                  )
                                )
                              ),
                              /* DAILY */
                              a!save(
                                ri!woCrewData,
                                updatearray(
                                  ri!woCrewData,
                                  ri!woIndex,
                                  a!update(
                                    data: ri!woCrewData[ri!woIndex],
                                    index: "equipments",
                                    value: updatearray(
                                      ri!woCrewData[ri!woIndex].equipments,
                                      local!eIndex,
                                      a!update(
                                        data: ri!woCrewData[ri!woIndex].equipments[local!eIndex],
                                        index: "addToCrewTemplate",
                                        value: a!isNotNullOrEmpty(save!value)
                                      )
                                    )
                                  )
                                )
                              )
                            )
                          }
                        )
                      },
                      {
                        a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          value: a!richTextItem(
                            text: local!equipmentName,
                            style: "STRONG",
                            size: "MEDIUM"
                          )
                        ),
                        a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          value: a!richTextItem(
                            text: local!equipmentId,
                            color: "SECONDARY",
                            size: "SMALL"
                          )
                        )
                      }
                    )
                  ),
                  a!columnLayout(
                    width: "2X",
                    contents: {
                      a!textField(
                        label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{0adb707e-f380-4157-a1db-2d790adf31d8}Hours',
                        refreshAfter: "UNFOCUS",
                        labelPosition: if(
                          or(
                            local!isAdhoc,
                            isnull(local!displayName),
                            local!displayName = ""
                          ),
                          {},
                          "COLLAPSED"
                        ),
                        placeholder: "0",
                        align: "CENTER",
                        value: index(fv!item, "hours", {}),
                        saveInto: {
                          a!save(ri!isManual, true),
                          if(
                            ri!isWeekly,
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
                                    ri!woIndex,
                                    a!update(
                                      data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                      index: "equipments",
                                      value: updatearray(
                                        ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].equipments,
                                        local!eIndex,
                                        a!update(
                                          data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].equipments[local!eIndex],
                                          index: "hours",
                                          value: if(
                                            a!isNotNullOrEmpty(save!value),
                                            todecimal(save!value),
                                            null
                                          )
                                        )
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
                                ri!woIndex,
                                a!update(
                                  data: ri!woCrewData[ri!woIndex],
                                  index: "equipments",
                                  value: updatearray(
                                    ri!woCrewData[ri!woIndex].equipments,
                                    local!eIndex,
                                    a!update(
                                      data: ri!woCrewData[ri!woIndex].equipments[local!eIndex],
                                      index: "hours",
                                      value: if(
                                        a!isNotNullOrEmpty(save!value),
                                        todecimal(save!value),
                                        null
                                      )
                                    )
                                  )
                                )
                              )
                            )
                          )
                        },
                        validations: {
                          rule!ATE_UTIL_validateHour(
                            hourTypeId: {},
                            hours: index(fv!item, "hours", 0)
                          )
                        }
                      )
                    }
                  ),
                  a!columnLayout(
                    width: "1X",
                    showWhen: local!isAdhoc,
                    contents: {
                      a!richTextDisplayField(
                        marginAbove: "MORE",
                        align: "CENTER",
                        value: a!richTextIcon(
                          icon: "TRASH",
                          size: "MEDIUM",
                          linkStyle: "STANDALONE",
                          color: "NEGATIVE",
                          link: a!dynamicLink(
                            saveInto: {
                              if(
                                ri!isWeekly,
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
                                        ri!woIndex,
                                        a!update(
                                          data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                          index: "equipments",
                                          value: remove(
                                            ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].equipments,
                                            local!eIndex
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
                                    ri!woIndex,
                                    a!update(
                                      data: ri!woCrewData[ri!woIndex],
                                      index: "equipments",
                                      value: remove(
                                        ri!woCrewData[ri!woIndex].equipments,
                                        local!eIndex
                                      )
                                    )
                                  )
                                )
                              )
                            }
                          )
                        )
                      )
                    }
                  )
                }
              ),
              /* ---------- EQUIPMENT PAYROLL OVERRIDE ---------- */
              rule!ATE_SEC_offlineEquipmentPayrollOverride(
                payrollOverride: ri!payrollOverride,
                brandingMap: ri!brandingMap,
                isWeekly: ri!isWeekly,
                selectedDay: ri!selectedDay,
                weekCrewData: ri!weekCrewData,
                woCrewData: ri!woCrewData,
                woIndex: ri!woIndex,
                equipmentIndex: local!eIndex,
                woItem: ri!woItem
              )
            }
          )
        )
      ),
      a!sideBySideLayout(
        items: {
          a!sideBySideItem(
            item: a!buttonArrayLayout(
              buttons: {
                a!buttonWidget(
                  label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{4b63321a-0d49-4443-86e2-7fc3a1735ac6}Previous',
                  style: "LINK",
                  color: cons!ROME_TEXT_HEX_ORANGE,
                  disabled: local!equipmentPagingInfo.startIndex = 1,
                  saveInto: {
                    if(
                      ri!isWeekly,
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
                              ri!woIndex,
                              a!update(
                                data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                index: "equipmentStartIndex",
                                value: max(1, local!equipmentPagingInfo.startIndex - local!equipmentPagingInfo.batchSize)
                              )
                            )
                          )
                        )
                      ),
                      a!save(
                        ri!woCrewData,
                        updatearray(
                          ri!woCrewData,
                          ri!woIndex,
                          a!update(
                            data: ri!woCrewData[ri!woIndex],
                            index: "equipmentStartIndex",
                            value: max(1, local!equipmentPagingInfo.startIndex - local!equipmentPagingInfo.batchSize)
                          )
                        )
                      )
                    )
                  }
                )
              },
              align: "END"
            ),
            width: "3X"
          ),
          a!sideBySideItem(
            item: a!richTextDisplayField(
              align: "CENTER",
              value: {
                a!richTextItem(
                  text: "Page " & ceiling(
                    local!equipmentPagingInfo.startIndex / local!equipmentPagingInfo.batchSize
                  ) & " of " & ceiling(
                    local!equipmentDataSubset.totalCount / local!equipmentPagingInfo.batchSize
                  ),
                  style: "STRONG"
                )
              }
            ),
            width: "2X"
          ),
          a!sideBySideItem(
            item: a!buttonArrayLayout(
              buttons: {
                a!buttonWidget(
                  label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{27bb4ba6-87e1-4f07-bc09-5fc7f95fe30f}Next',
                  style: "LINK",
                  color: cons!ROME_TEXT_HEX_ORANGE,
                  disabled: local!equipmentPagingInfo.startIndex + local!equipmentPagingInfo.batchSize > local!equipmentDataSubset.totalCount,
                  saveInto: {
                    if(
                      ri!isWeekly,
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
                              ri!woIndex,
                              a!update(
                                data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                                index: "equipmentStartIndex",
                                value: local!equipmentPagingInfo.startIndex + local!equipmentPagingInfo.batchSize
                              )
                            )
                          )
                        )
                      ),
                      a!save(
                        ri!woCrewData,
                        updatearray(
                          ri!woCrewData,
                          ri!woIndex,
                          a!update(
                            data: ri!woCrewData[ri!woIndex],
                            index: "equipmentStartIndex",
                            value: local!equipmentPagingInfo.startIndex + local!equipmentPagingInfo.batchSize
                          )
                        )
                      )
                    )
                  }
                )
              },
              align: "START"
            ),
            width: "3X"
          )
        }
      ),
      /* Custom Field */
      /*if(*/
        /*a!isNotNullOrEmpty(*/
          /*index(*/
            /*ri!woCustomFieldConf,*/
            /*'recordType!{c859c726-925b-479e-9d91-5a281e91de4f}ATE Custom Field Configuration.fields.{d82a783a-5270-4030-a353-0de11a9aa25a}fieldName1En',*/
            /*null*/
          /*)*/
        /*),*/
        /*{*/
          /*a!richTextDisplayField(*/
            /*labelPosition: "COLLAPSED",*/
            /*value: {*/
              /*a!richTextItem(*/
                /*text: "CUSTOM FIELDS",*/
                /*size: "SMALL",*/
                /*style: "STRONG",*/
                /*color: "SECONDARY",*/
/*                */
              /*)*/
            /*}*/
          /*),*/
          /*a!cardLayout(*/
            /*shape: "ROUNDED",*/
            /*marginBelow: "STANDARD",*/
            /*style: cons!ATE_TXT_HEX_CARD_STYLE_SHADED & "50",*/
            /*contents: rule!ATE_SCT_UserDefinedFieldsForMTEOffline(*/
              /*customFieldValue: ri!woCustomFieldValue,*/
              /*customFieldConfiguration: ri!woCustomFieldConf,*/
              /*dropdownChoices: ri!woDropDownChoices*/
            /*)*/
          /*)*/
        /*},*/
        /*{}*/
      /*),*/
      a!paragraphField(
        label: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{29f90b8a-6113-4893-91ff-4841d376acbf}TIMESHEET COMMENTS',
        labelPosition: "ABOVE",
        placeholder: "Enter comments here...",
        value: ri!woCrewData[ri!woIndex].timesheetComments,
        saveInto: {
          if(
            /* WEEKLY */
            ri!isWeekly,
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
                    ri!woIndex,
                    a!update(
                      data: ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex],
                      index: "timesheetComments",
                      value: save!value
                    )
                  )
                )
              )
            ),
            /* DAILY */
            a!save(
              ri!woCrewData,
              updatearray(
                ri!woCrewData,
                ri!woIndex,
                a!update(
                  data: ri!woCrewData[ri!woIndex],
                  index: "timesheetComments",
                  value: save!value
                )
              )
            )
          )
        },
        refreshAfter: "UNFOCUS",
        validations: {},
        characterLimit: 4000,
        height: "MEDIUM"
      )
    }
  )
  }
)

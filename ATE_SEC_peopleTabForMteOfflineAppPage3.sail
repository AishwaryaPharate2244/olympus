a!localVariables(
  /* ---------- LABOR ---------- */
  /* Labor pagination */
  local!laborPagingInfo: a!pagingInfo(startIndex: 1, batchSize: 5),
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
  /* Labor payroll override settings (same for every labor row) */
  local!poShow: a!defaultValue(
    index(ri!payrollOverride, "showFields", false()),
    false()
  ),
  local!poCanCustomize: a!defaultValue(
    index(ri!payrollOverride, "canCustomizeRate", false()),
    false()
  ),
  local!poHourTypeLevel: a!defaultValue(
    index(ri!payrollOverride, "isHourTypeLevel", false()),
    false()
  ),
  local!poOptions: a!defaultValue(
    index(ri!payrollOverride, "options", {}),
    {}
  ),
  local!poOptionIds: tointeger(index(local!poOptions, "id", {})),

  /* ---------- EQUIPMENT ---------- */
  /* Equipment pagination */
  local!equipmentPagingInfo: a!pagingInfo(startIndex: 1, batchSize: 5),
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
  /* Equipment payroll override settings (same for every equipment row) */
  local!epShow: a!defaultValue(
    index(ri!payrollOverride, "equipShowFields", false()),
    false()
  ),
  local!epCanCustomize: a!defaultValue(
    index(ri!payrollOverride, "equipCanCustomizeRate", false()),
    false()
  ),
  local!epOptions: a!defaultValue(
    index(ri!payrollOverride, "equipOptions", {}),
    {}
  ),
  local!epOptionIds: tointeger(index(local!epOptions, "id", {})),

  /* ---------- WEEKLY: DAYS THAT PAYROLL OVERRIDE EDITS APPLY TO ---------- */
  /* Stored on this work order in weekCrewData (key "payrollOverrideDays") so saves never reset it */
  /* Assumes weekCrewData is ordered Sun (1) .. Sat (7) */
  local!dayLabels: { "Sun", "Mon", "Tues", "Wed", "Thurs", "Fri", "Sat" },
  local!dayIdxs: enumerate(count(ri!weekCrewData)) + 1,
  local!thisWoNumber: tostring(index(ri!woItem, "workOrderNumber", "")),
  local!savedDays: if(
    a!defaultValue(ri!isWeekly, false()),
    index(
      index(
        index(index(ri!weekCrewData, ri!selectedDay, {}), "woCrewData", {}),
        ri!woIndex,
        {}
      ),
      "payrollOverrideDays",
      null
    ),
    null
  ),
  /* Default = whole week (same as online) */
  local!overrideDays: if(
    a!isNullOrEmpty(local!savedDays),
    local!dayIdxs,
    tointeger(local!savedDays)
  ),
  /* The day being edited is always included */
  local!appliedDays: union(
    tointeger(ri!selectedDay),
    tointeger(local!overrideDays)
  ),
  local!appliedDaysText: if(
    length(local!appliedDays) >= count(local!dayIdxs),
    "Whole week",
    joinarray(
      reject(
        fn!isnull,
        a!forEach(
          items: local!dayIdxs,
          expression: if(
            contains(local!appliedDays, fv!item),
            index(local!dayLabels, fv!item, "Day " & fv!item),
            null
          )
        )
      ),
      ", "
    )
  ),
  /* UI only: whether the day checkboxes are open */
  local!showDayPicker: false(),

  {
    /* ---------- WEEKLY: PAYROLL OVERRIDE DAYS (visible on every tab) ---------- */
    a!cardLayout(
      shape: "ROUNDED",
      padding: "LESS",
      marginBelow: "STANDARD",
      style: cons!ATE_TXT_HEX_CARD_STYLE_SHADED & "50",
      showWhen: and(
        a!defaultValue(ri!isWeekly, false()),
        or(local!poShow, local!epShow)
      ),
      contents: {
        a!sideBySideLayout(
          alignVertical: "MIDDLE",
          items: {
            a!sideBySideItem(
              item: a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                value: {
                  a!richTextItem(
                    text: "Payroll override applies to: ",
                    style: "STRONG",
                    size: "SMALL"
                  ),
                  a!richTextItem(
                    text: if(local!showDayPicker, "", local!appliedDaysText),
                    size: "SMALL"
                  )
                }
              )
            ),
            a!sideBySideItem(
              width: "MINIMIZE",
              item: a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                value: a!richTextItem(
                  text: if(local!showDayPicker, "Done", "Change"),
                  style: "STRONG",
                  size: "SMALL",
                  color: cons!ROME_TEXT_HEX_ORANGE,
                  linkStyle: "STANDALONE",
                  link: a!dynamicLink(
                    value: not(local!showDayPicker),
                    saveInto: local!showDayPicker
                  )
                )
              )
            )
          }
        ),
        a!checkboxField(
          labelPosition: "COLLAPSED",
          helpTooltip: "Category and rate changes are applied to the selected days for the same employee or equipment on this work order. The current day is always included.",
          choiceLabels: a!forEach(
            items: local!dayIdxs,
            expression: index(local!dayLabels, fv!item, "Day " & fv!item)
          ),
          choiceValues: local!dayIdxs,
          choiceLayout: "COMPACT",
          value: local!appliedDays,
          /* store the selection on this work order for every day of the week */
          saveInto: a!save(
            ri!weekCrewData,
            a!forEach(
              items: ri!weekCrewData,
              expression: a!update(
                data: fv!item,
                index: "woCrewData",
                value: a!forEach(
                  items: index(fv!item, "woCrewData", {}),
                  expression: if(
                    tostring(index(fv!item, "workOrderNumber", "")) = local!thisWoNumber,
                    a!update(
                      data: fv!item,
                      index: "payrollOverrideDays",
                      value: tointeger(save!value)
                    ),
                    fv!item
                  )
                )
              )
            )
          ),
          showWhen: local!showDayPicker
        )
      }
    ),
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
              a!localVariables(
                local!poRow: if(
                  ri!isWeekly,
                  ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].labors[local!lIndex],
                  ri!woCrewData[ri!woIndex].labors[local!lIndex]
                ),
                local!poCategoryId: tointeger(
                  index(local!poRow, "payrollConfigOverrideId", null)
                ),
                local!poEmployeeRate: index(
                  reject(
                    a!isNullOrEmpty(_),
                    index(local!hourTypes, "payrollOverrideRate", {})
                  ),
                  1,
                  null
                ),
                a!sectionLayout(
                  label: "Payroll Override",
                  labelSize: "SMALL",
                  labelColor: ri!brandingMap.headingLabelColor,
                  isCollapsible: true,
                  isInitiallyCollapsed: a!isNullOrEmpty(local!poCategoryId),
                  marginAbove: "STANDARD",
                  showWhen: local!poShow,
                  contents: {
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
                      saveInto: {
                        if(
                          ri!isWeekly,
                          a!save(
                            ri!weekCrewData,
                            rule!ATE_UTIL_offlineSetPayrollOverride(
                              isWeekly: true(),
                              weekCrewData: ri!weekCrewData,
                              selectedDay: ri!selectedDay,
                              woIndex: ri!woIndex,
                              laborIndex: local!lIndex,
                              action: "CATEGORY",
                              value: save!value,
                              options: local!poOptions,
                              canCustomizeRate: local!poCanCustomize,
                              targetDays: local!overrideDays
                            )
                          ),
                          a!save(
                            ri!woCrewData,
                            rule!ATE_UTIL_offlineSetPayrollOverride(
                              isWeekly: false(),
                              woCrewData: ri!woCrewData,
                              woIndex: ri!woIndex,
                              laborIndex: local!lIndex,
                              action: "CATEGORY",
                              value: save!value,
                              options: local!poOptions,
                              canCustomizeRate: local!poCanCustomize
                            )
                          )
                        ),
                        if(
                          local!poHourTypeLevel,
                          a!forEach(
                            items: local!hourTypes,
                            expression: if(
                              a!isNullOrEmpty(fv!item.hourTypeId),
                              {},
                              if(
                                ri!isWeekly,
                                a!save(
                                  ri!weekCrewData,
                                  rule!ATE_UTIL_offlineSetPayrollOverride(
                                    isWeekly: true(),
                                    weekCrewData: ri!weekCrewData,
                                    selectedDay: ri!selectedDay,
                                    woIndex: ri!woIndex,
                                    laborIndex: local!lIndex,
                                    action: "HOURTYPE_RATE",
                                    hourTypeId: tointeger(fv!item.hourTypeId),
                                    value: index(
                                      index(
                                        index(local!poOptions, "rate", {}),
                                        wherecontains(
                                          tointeger(save!value),
                                          local!poOptionIds
                                        ),
                                        {}
                                      ),
                                      1,
                                      null
                                    ),
                                    targetDays: local!overrideDays
                                  )
                                ),
                                a!save(
                                  ri!woCrewData,
                                  rule!ATE_UTIL_offlineSetPayrollOverride(
                                    isWeekly: false(),
                                    woCrewData: ri!woCrewData,
                                    woIndex: ri!woIndex,
                                    laborIndex: local!lIndex,
                                    action: "HOURTYPE_RATE",
                                    hourTypeId: tointeger(fv!item.hourTypeId),
                                    value: index(
                                      index(
                                        index(local!poOptions, "rate", {}),
                                        wherecontains(
                                          tointeger(save!value),
                                          local!poOptionIds
                                        ),
                                        {}
                                      ),
                                      1,
                                      null
                                    )
                                  )
                                )
                              )
                            )
                          ),
                          if(
                            ri!isWeekly,
                            a!save(
                              ri!weekCrewData,
                              rule!ATE_UTIL_offlineSetPayrollOverride(
                                isWeekly: true(),
                                weekCrewData: ri!weekCrewData,
                                selectedDay: ri!selectedDay,
                                woIndex: ri!woIndex,
                                laborIndex: local!lIndex,
                                action: "EMPLOYEE_RATE",
                                value: index(
                                  index(
                                    index(local!poOptions, "rate", {}),
                                    wherecontains(
                                      tointeger(save!value),
                                      local!poOptionIds
                                    ),
                                    {}
                                  ),
                                  1,
                                  null
                                ),
                                targetDays: local!overrideDays
                              )
                            ),
                            a!save(
                              ri!woCrewData,
                              rule!ATE_UTIL_offlineSetPayrollOverride(
                                isWeekly: false(),
                                woCrewData: ri!woCrewData,
                                woIndex: ri!woIndex,
                                laborIndex: local!lIndex,
                                action: "EMPLOYEE_RATE",
                                value: index(
                                  index(
                                    index(local!poOptions, "rate", {}),
                                    wherecontains(
                                      tointeger(save!value),
                                      local!poOptionIds
                                    ),
                                    {}
                                  ),
                                  1,
                                  null
                                )
                              )
                            )
                          )
                        )
                      },
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
                            rule!ATE_UTIL_offlineSetPayrollOverride(
                              isWeekly: true(),
                              weekCrewData: ri!weekCrewData,
                              selectedDay: ri!selectedDay,
                              woIndex: ri!woIndex,
                              laborIndex: local!lIndex,
                              action: "EMPLOYEE_RATE",
                              value: save!value,
                              targetDays: local!overrideDays
                            )
                          ),
                          a!save(
                            ri!woCrewData,
                            rule!ATE_UTIL_offlineSetPayrollOverride(
                              isWeekly: false(),
                              woCrewData: ri!woCrewData,
                              woIndex: ri!woIndex,
                              laborIndex: local!lIndex,
                              action: "EMPLOYEE_RATE",
                              value: save!value
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
                                            rule!ATE_UTIL_offlineSetPayrollOverride(
                                              isWeekly: true(),
                                              weekCrewData: ri!weekCrewData,
                                              selectedDay: ri!selectedDay,
                                              woIndex: ri!woIndex,
                                              laborIndex: local!lIndex,
                                              action: "HOURTYPE_RATE",
                                              value: save!value,
                                              hourTypeId: local!htId,
                                              targetDays: local!overrideDays
                                            )
                                          ),
                                          a!save(
                                            ri!woCrewData,
                                            rule!ATE_UTIL_offlineSetPayrollOverride(
                                              isWeekly: false(),
                                              woCrewData: ri!woCrewData,
                                              woIndex: ri!woIndex,
                                              laborIndex: local!lIndex,
                                              action: "HOURTYPE_RATE",
                                              value: save!value,
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
                    )
                  }
                )
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
                    a!save(
                      local!laborPagingInfo,
                      a!pagingInfo(
                        startIndex: max(
                          1,
                          local!laborPagingInfo.startIndex - local!laborPagingInfo.batchSize
                        ),
                        batchSize: local!laborPagingInfo.batchSize
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
                    a!save(
                      local!laborPagingInfo,
                      a!pagingInfo(
                        startIndex: local!laborPagingInfo.startIndex + local!laborPagingInfo.batchSize,
                        batchSize: local!laborPagingInfo.batchSize
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
              a!localVariables(
                local!epRow: if(
                  ri!isWeekly,
                  ri!weekCrewData[ri!selectedDay].woCrewData[ri!woIndex].equipments[local!eIndex],
                  ri!woCrewData[ri!woIndex].equipments[local!eIndex]
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
                              equipmentIndex: local!eIndex,
                              action: "CATEGORY",
                              value: save!value,
                              options: local!epOptions,
                              targetDays: local!overrideDays
                            )
                          ),
                          a!save(
                            ri!woCrewData,
                            rule!ATE_UTIL_offlineSetEquipmentPayrollOverrides(
                              isWeekly: false(),
                              woCrewData: ri!woCrewData,
                              woIndex: ri!woIndex,
                              equipmentIndex: local!eIndex,
                              action: "CATEGORY",
                              value: save!value,
                              options: local!epOptions
                            )
                          )
                        ),
                        if(
                          ri!isWeekly,
                          a!save(
                            ri!weekCrewData,
                            rule!ATE_UTIL_offlineSetEquipmentPayrollOverrides(
                              isWeekly: true(),
                              weekCrewData: ri!weekCrewData,
                              selectedDay: ri!selectedDay,
                              woIndex: ri!woIndex,
                              equipmentIndex: local!eIndex,
                              action: "RATE",
                              value: index(
                                index(
                                  index(local!epOptions, "rate", {}),
                                  wherecontains(
                                    tointeger(save!value),
                                    local!epOptionIds
                                  ),
                                  {}
                                ),
                                1,
                                null
                              ),
                              targetDays: local!overrideDays
                            )
                          ),
                          a!save(
                            ri!woCrewData,
                            rule!ATE_UTIL_offlineSetEquipmentPayrollOverrides(
                              isWeekly: false(),
                              woCrewData: ri!woCrewData,
                              woIndex: ri!woIndex,
                              equipmentIndex: local!eIndex,
                              action: "RATE",
                              value: index(
                                index(
                                  index(local!epOptions, "rate", {}),
                                  wherecontains(
                                    tointeger(save!value),
                                    local!epOptionIds
                                  ),
                                  {}
                                ),
                                1,
                                null
                              )
                            )
                          )
                        )
                      },
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
                              equipmentIndex: local!eIndex,
                              action: "RATE",
                              value: save!value,
                              targetDays: local!overrideDays
                            )
                          ),
                          a!save(
                            ri!woCrewData,
                            rule!ATE_UTIL_offlineSetEquipmentPayrollOverrides(
                              isWeekly: false(),
                              woCrewData: ri!woCrewData,
                              woIndex: ri!woIndex,
                              equipmentIndex: local!eIndex,
                              action: "RATE",
                              value: save!value
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
                  }
                )
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
                    a!save(
                      local!equipmentPagingInfo,
                      a!pagingInfo(
                        startIndex: max(
                          1,
                          local!equipmentPagingInfo.startIndex - local!equipmentPagingInfo.batchSize
                        ),
                        batchSize: local!equipmentPagingInfo.batchSize
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
                    a!save(
                      local!equipmentPagingInfo,
                      a!pagingInfo(
                        startIndex: local!equipmentPagingInfo.startIndex + local!equipmentPagingInfo.batchSize,
                        batchSize: local!equipmentPagingInfo.batchSize
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

/*
  ATE_SEC_offlinePayrollOverrideDays
  Weekly view only: "Payroll override applies to: Whole week  Change" for one work order.
  Lives in the work order card (outside the People tab) so it is visible whichever tab is selected.
  The selected days are stored in the PARENT (ri!overrideDaysByWo) so they are not reset by saves.

  Rule inputs:
    overrideDaysByWo  (Any Type)  parent local, saved into: list of a!map(woNumber, days)
    woNumber          (Text)
    dayCount          (Integer)   count(weekCrewData)
    selectedDay       (Integer)   day currently being edited (always included)
    brandingMap       (Any Type)  optional, not required
*/
a!localVariables(
  /* Assumes weekCrewData is ordered Sun (1) .. Sat (7) */
  local!dayLabels: { "Sun", "Mon", "Tues", "Wed", "Thurs", "Fri", "Sat" },
  local!dayIdxs: enumerate(a!defaultValue(ri!dayCount, 0)) + 1,
  /* UI only: whether the day checkboxes are open */
  local!showDayPicker: false(),
  /* Days for this work order, current day always included */
  local!appliedDays: union(
    tointeger(ri!selectedDay),
    rule!ATE_UTIL_offlineGetPayrollOverrideDays(
      overrideDaysByWo: ri!overrideDaysByWo,
      woNumber: ri!woNumber,
      dayCount: ri!dayCount
    )
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
  a!cardLayout(
    shape: "ROUNDED",
    padding: "LESS",
    marginBelow: "STANDARD",
    style: cons!ATE_TXT_HEX_CARD_STYLE_SHADED & "50",
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
        saveInto: a!save(
          ri!overrideDaysByWo,
          append(
            /* keep the other work orders' selections */
            reject(
              fn!isnull,
              a!forEach(
                items: a!defaultValue(ri!overrideDaysByWo, {}),
                expression: if(
                  tostring(index(fv!item, "woNumber", "")) = tostring(ri!woNumber),
                  null,
                  fv!item
                )
              )
            ),
            /* replace this work order's selection */
            a!map(
              woNumber: tostring(ri!woNumber),
              days: tointeger(save!value)
            )
          )
        ),
        showWhen: local!showDayPicker
      )
    }
  )
)

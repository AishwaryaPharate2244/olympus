/*
  ATE_SEC_offlinePayrollOverrideDays
  Weekly view: "Payroll override applies to" card with one tappable chip per day.
  Filled = included, outlined = excluded, locked = day being edited (always included).

  Rule inputs:
    weekCrewData  (Any Type)  saved into
    woNumber      (Text)
    selectedDay   (Integer)
*/
a!localVariables(
  local!dayIdxs: enumerate(count(a!defaultValue(ri!weekCrewData, {}))) + 1,
  /* Assumes weekCrewData is ordered Sun (1) .. Sat (7) */
  local!dayLabels: { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" },
  local!days: rule!ATE_UTIL_offlineGetPayrollOverrideDays(
    weekCrewData: ri!weekCrewData,
    woNumber: ri!woNumber
  ),
  local!isWholeWeek: length(union(tointeger(local!days), tointeger(local!days))) >= count(local!dayIdxs),
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
                a!richTextIcon(
                  icon: "calendar",
                  color: cons!ROME_TEXT_HEX_ORANGE,
                  size: "SMALL"
                ),
                a!richTextItem(
                  text: " Payroll override applies to",
                  style: "STRONG",
                  size: "SMALL"
                ),
                char(10),
                a!richTextItem(
                  text: "Category and rate changes apply to the highlighted days.",
                  color: "SECONDARY",
                  size: "SMALL"
                )
              }
            )
          ),
          a!sideBySideItem(
            width: "MINIMIZE",
            item: a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              value: if(
                local!isWholeWeek,
                a!richTextItem(text: "Whole week", color: "SECONDARY", size: "SMALL"),
                a!richTextItem(
                  text: "Reset to week",
                  style: "STRONG",
                  size: "SMALL",
                  color: cons!ROME_TEXT_HEX_ORANGE,
                  linkStyle: "STANDALONE",
                  link: a!dynamicLink(
                    saveInto: a!save(
                      ri!weekCrewData,
                      rule!ATE_UTIL_offlineSetPayrollOverrideDays(
                        weekCrewData: ri!weekCrewData,
                        woNumber: ri!woNumber,
                        days: local!dayIdxs
                      )
                    )
                  )
                )
              )
            )
          )
        }
      ),
      a!buttonArrayLayout(
        align: "START",
        marginBelow: "NONE",
        buttons: a!forEach(
          items: local!dayIdxs,
          expression: a!localVariables(
            local!day: fv!item,
            local!isCurrent: fv!item = ri!selectedDay,
            local!isOn: or(fv!item = ri!selectedDay, contains(local!days, fv!item)),
            a!buttonWidget(
              label: index(local!dayLabels, fv!item, "Day " & fv!item),
              size: "SMALL",
              style: if(local!isOn, "SOLID", "OUTLINE"),
              color: cons!ROME_TEXT_HEX_ORANGE,
              disabled: local!isCurrent,
              tooltip: if(
                local!isCurrent,
                "Day you are editing – always included",
                if(local!isOn, "Tap to exclude", "Tap to include")
              ),
              saveInto: a!save(
                ri!weekCrewData,
                rule!ATE_UTIL_offlineSetPayrollOverrideDays(
                  weekCrewData: ri!weekCrewData,
                  woNumber: ri!woNumber,
                  days: a!localVariables(
                    local!newDays: if(
                      contains(local!days, local!day),
                      difference(tointeger(local!days), tointeger(local!day)),
                      append(tointeger(local!days), tointeger(local!day))
                    ),
                    /* nothing left = only the day being edited (never "empty", which would mean whole week) */
                    if(
                      a!isNullOrEmpty(local!newDays),
                      tointeger(ri!selectedDay),
                      local!newDays
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

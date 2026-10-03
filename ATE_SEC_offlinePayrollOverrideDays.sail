/*
  ATE_SEC_offlinePayrollOverrideDays
  Weekly view: "Payroll override applies to" card with one tappable chip per day.
  Filled = included, outlined = excluded. The chips always show the saved selection;
  the day being viewed is only marked, never forced on.

  How edits behave (applied in ATE_SEC_peopleTabForMteOfflineAppPage3):
    viewed day is highlighted     -> change applies to all highlighted days
    viewed day is not highlighted -> change applies to the viewed day only

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
  local!isWholeWeek: length(intersection(tointeger(local!days), local!dayIdxs)) >= count(local!dayIdxs),
  local!currentLabel: index(local!dayLabels, ri!selectedDay, "this day"),
  local!currentIsIncluded: contains(tointeger(local!days), tointeger(ri!selectedDay)),
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
                  text: if(
                    local!currentIsIncluded,
                    "Changes made on " & local!currentLabel & " apply to all highlighted days.",
                    local!currentLabel & " is not highlighted – changes made on " & local!currentLabel & " apply to " & local!currentLabel & " only."
                  ),
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
            local!isOn: contains(tointeger(local!days), fv!item),
            a!buttonWidget(
              /* the day being viewed is marked with a dot */
              label: index(local!dayLabels, fv!item, "Day " & fv!item) & if(local!isCurrent, " •", ""),
              size: "SMALL",
              style: if(local!isOn, "SOLID", "OUTLINE"),
              color: cons!ROME_TEXT_HEX_ORANGE,
              tooltip: if(local!isCurrent, "Day you are viewing. ", "") & if(local!isOn, "Tap to exclude", "Tap to include"),
              saveInto: a!save(
                ri!weekCrewData,
                rule!ATE_UTIL_offlineSetPayrollOverrideDays(
                  weekCrewData: ri!weekCrewData,
                  woNumber: ri!woNumber,
                  days: a!localVariables(
                    local!newDays: if(
                      local!isOn,
                      difference(tointeger(local!days), tointeger(local!day)),
                      append(tointeger(local!days), tointeger(local!day))
                    ),
                    /* nothing highlighted is stored as {0} ("no days"); an empty list would mean "whole week" */
                    if(a!isNullOrEmpty(local!newDays), { 0 }, local!newDays)
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

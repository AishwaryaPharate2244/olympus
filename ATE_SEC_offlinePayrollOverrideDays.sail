/*
  ATE_SEC_offlinePayrollOverrideDays
  Weekly view: "Payroll override applies to" card with one tappable chip per day.
  Shown inside each employee's / equipment's Payroll Override section, so every
  row has its own days (same as online: override is per employee / per equipment).
  Checked box = included, empty box = excluded. The days always show the saved selection;
  the day being viewed is only marked, never forced on.

  How it behaves:
    highlighted days     -> this row's category / rate edits apply to all highlighted days
    not highlighted days -> no payroll override for this row (cleared, fields hidden on that day)

  Rule inputs:
    weekCrewData  (Any Type)  saved into
    woNumber      (Text)
    rowKey        (Text)     "labors" or "equipments"
    rowId         (Text)     employeeId or equipmentId
    selectedDay   (Integer)
*/
a!localVariables(
  local!dayIdxs: enumerate(count(a!defaultValue(ri!weekCrewData, {}))) + 1,
  /* Assumes weekCrewData is ordered Sun (1) .. Sat (7) */
  local!dayLabels: { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" },
  local!days: rule!ATE_UTIL_offlineGetPayrollOverrideDays(
    weekCrewData: ri!weekCrewData,
    woNumber: ri!woNumber,
    rowKey: ri!rowKey,
    rowId: ri!rowId
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
                    "Category and rate below apply to the highlighted days only.",
                    "No payroll override on " & local!currentLabel & ". Tap " & local!currentLabel & " to include it."
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
                        rowKey: ri!rowKey,
                        rowId: ri!rowId,
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
      /* One small line of day links: checked box = included, empty box = excluded */
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        marginAbove: "LESS",
        value: a!forEach(
          items: local!dayIdxs,
          expression: a!localVariables(
            local!day: fv!item,
            local!isCurrent: fv!item = ri!selectedDay,
            local!isOn: contains(tointeger(local!days), fv!item),
            /* the selection after tapping this day: remove the day if it is on, add it if it is off */
            local!daysAfterTap: if(
              local!isOn,
              difference(tointeger(local!days), tointeger(local!day)),
              append(tointeger(local!days), tointeger(local!day))
            ),
            {
              a!richTextItem(
                text: {
                  a!richTextIcon(icon: if(local!isOn, "check-square", "square-o")),
                  " " & index(local!dayLabels, fv!item, "Day " & fv!item)
                },
                size: "SMALL",
                color: if(local!isOn, cons!ROME_TEXT_HEX_ORANGE, "SECONDARY"),
                /* the day being viewed is underlined */
                style: if(local!isCurrent, { "STRONG", "UNDERLINE" }, "PLAIN"),
                linkStyle: "STANDALONE",
                link: a!dynamicLink(
                  saveInto: a!save(
                    ri!weekCrewData,
                    rule!ATE_UTIL_offlineSetPayrollOverrideDays(
                      weekCrewData: ri!weekCrewData,
                      woNumber: ri!woNumber,
                      rowKey: ri!rowKey,
                      rowId: ri!rowId,
                      /* nothing selected is saved as {0}; an empty list would mean "whole week" */
                      days: if(a!isNullOrEmpty(local!daysAfterTap), { 0 }, local!daysAfterTap)
                    )
                  )
                )
              ),
              "     "
            }
          )
        )
      )
    }
  )
)

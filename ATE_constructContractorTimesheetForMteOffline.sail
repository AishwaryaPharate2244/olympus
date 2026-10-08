if(
  rule!ATE_checkIsNullOrEmptyArray(ri!finalMap),
  null,
  a!localVariables(
    local!loggedInUser: ri!user,
    local!currentDateTime: now(),
    local!weekInfo: index(ri!finalMap, 1, {}),
    local!allWorkOrders: a!flatten(
      a!forEach(
        items: ri!finalMap,
        expression: index(fv!item, "workOrderData", {})
      )
    ),
    local!crewTemplateId: index(
      index(ri!finalMap, 1, {}),
      "crewTemplateId",
      null
    ),
    local!laborEntries: a!forEach(
      items: a!flatten(index(local!allWorkOrders, "labors", {})),
      expression: a!localVariables(
        local!isAdhoc: a!defaultValue(
          index(fv!item, "isAdhoc", false()),
          false()
        ),
        a!map(
          id: tostring(index(fv!item, "employeeId", "")),
          isAdhoc: local!isAdhoc,
          templateAdd: and(
            local!isAdhoc,
            a!defaultValue(
              index(fv!item, "addToCrewTemplate", false()),
              false()
            )
          )
        )
      )
    ),
    local!equipmentEntries: a!forEach(
      items: a!flatten(
        index(local!allWorkOrders, "equipments", {})
      ),
      expression: a!localVariables(
        local!isAdhoc: a!defaultValue(
          index(fv!item, "isAdhoc", false()),
          false()
        ),
        a!map(
          id: tostring(index(fv!item, "equipmentId", "")),
          isAdhoc: local!isAdhoc,
          templateAdd: and(
            local!isAdhoc,
            a!defaultValue(
              index(fv!item, "addToCrewTemplate", false()),
              false()
            )
          )
        )
      )
    ),
    local!laborIds: touniformstring(index(local!laborEntries, "id", {})),
    local!equipmentIds: touniformstring(index(local!equipmentEntries, "id", {})),
    local!adhocLaborsForTemplate: reject(
      a!isNullOrEmpty(_),
      index(
        local!laborIds,
        wherecontains(
          true,
          toboolean(index(local!laborEntries, "templateAdd", {}))
        ),
        {}
      )
    ),
    local!adhocEquipmentsForTemplate: reject(
      a!isNullOrEmpty(_),
      index(
        local!equipmentIds,
        wherecontains(
          true,
          toboolean(
            index(
              local!equipmentEntries,
              "templateAdd",
              {}
            )
          )
        ),
        {}
      )
    ),
    local!submittedLaborIds: reject(
      a!isNullOrEmpty(_),
      index(
        local!laborIds,
        wherecontains(
          false,
          toboolean(index(local!laborEntries, "isAdhoc", {}))
        ),
        {}
      )
    ),
    local!submittedEquipmentIds: reject(
      a!isNullOrEmpty(_),
      index(
        local!equipmentIds,
        wherecontains(
          false,
          toboolean(index(local!equipmentEntries, "isAdhoc", {}))
        ),
        {}
      )
    ),
    local!existingCrewTemplate: if(
      a!isNullOrEmpty(local!crewTemplateId),
      null,
      index(
        rule!ATE_QRY_crewTemplate(
          fields: {
            'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.fields.{613eebb7-b28e-4805-b12c-42c7f5396694}id',
            'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.fields.{31d19529-415f-463c-9721-d92f5baad441}name',
            'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.fields.{c9a61a95-0d27-45a2-a6ff-353f21a3631c}crew',
            'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.fields.{c98e6171-f511-4002-a536-35dce2d2dfd2}targetHours',
            'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{ed8405a0-530c-4a91-aa6c-e890db20a06b}laborCrewTemplate.fields.{8517bfc8-4e01-438c-b917-59ad30eecfb8}employeeId',
            'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{ed8405a0-530c-4a91-aa6c-e890db20a06b}laborCrewTemplate.fields.{6c09d1c1-248f-42c3-8340-8beca5f650af}isActive',
            'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{264b1308-dfb4-4db0-b8f2-270cba088a31}equipmentCrewTemplate.fields.{22247106-0086-4043-a0b9-224ba13c483c}equipmentId',
            'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{264b1308-dfb4-4db0-b8f2-270cba088a31}equipmentCrewTemplate.fields.{bf857f8c-3ac1-4a05-a81a-8607de640fdd}isActive'
          },
          relatedRecordData: {
            a!relatedRecordData(
              relationship: 'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{ed8405a0-530c-4a91-aa6c-e890db20a06b}laborCrewTemplate',
              limit: 100,
              filters: {
                a!queryFilter(
                  field: 'recordType!{b29742d7-7644-4774-a125-5556cd9e0086}ATE Labor Crew Template.fields.{6c09d1c1-248f-42c3-8340-8beca5f650af}isActive',
                  operator: "=",
                  value: true()
                )
              }
            ),
            a!relatedRecordData(
              relationship: 'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{264b1308-dfb4-4db0-b8f2-270cba088a31}equipmentCrewTemplate',
              limit: 100,
              filters: {
                a!queryFilter(
                  field: 'recordType!{39493776-6005-4f99-adc0-4690c2177ef4}ATE Equipment Crew Template.fields.{bf857f8c-3ac1-4a05-a81a-8607de640fdd}isActive',
                  operator: "=",
                  value: true()
                )
              }
            )
          },
          templateID: local!crewTemplateId
        ),
        1,
        null
      )
    ),
    local!existingLaborCrewTemp: index(
      local!existingCrewTemplate,
      'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{ed8405a0-530c-4a91-aa6c-e890db20a06b}laborCrewTemplate',
      {}
    ),
    local!existingEquipmentCrewTemp: index(
      local!existingCrewTemplate,
      'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{264b1308-dfb4-4db0-b8f2-270cba088a31}equipmentCrewTemplate',
      {}
    ),
    local!updatedCrewTemplate: if(
      a!isNullOrEmpty(local!existingCrewTemplate),
      null,
      a!update(
        data: a!update(
          data: local!existingCrewTemplate,
          index: 'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{ed8405a0-530c-4a91-aa6c-e890db20a06b}laborCrewTemplate',
          value: rule!ATE_RULE_saveLaborDetailsForCrewTemplate(
            isCreate: false(),
            currentLaborEnteries: append(
              local!submittedLaborIds,
              local!adhocLaborsForTemplate
            ),
            existingLaborEnteries: local!existingLaborCrewTemp
          )
        ),
        index: 'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{264b1308-dfb4-4db0-b8f2-270cba088a31}equipmentCrewTemplate',
        value: rule!ATE_RULE_saveEquipmentDetailsForCrewTemplate(
          isCreate: false(),
          currentEquipmentList: append(
            local!submittedEquipmentIds,
            local!adhocEquipmentsForTemplate
          ),
          existingEquipmentEnteries: local!existingEquipmentCrewTemp
        )
      )
    ),
    local!uniqueWoNumbers: union(
      index(
        local!allWorkOrders,
        "workOrderNumber",
        {}
      ),
      index(
        local!allWorkOrders,
        "workOrderNumber",
        {}
      )
    ),
    local!allDates: todate(index(ri!finalMap, "date", {})),
    local!earliestDate: min(local!allDates),
    local!weekStartDate: local!earliestDate - (weekday(local!earliestDate) - 1),
    local!productionUnitWo: a!queryRecordType(
      recordType: 'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO',
      fields: {
        a!selectionFields(
          selectFields: {
            'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.fields.{463641a3-0f56-44a8-8b12-8018f2724f0c}id',
            'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.fields.{d1110989-7d6c-482b-918e-1168589689bb}contractType',
            'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.fields.{e25b88f2-b2d5-4ce3-883b-596ba699272d}jobNumber',
            'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.fields.{6c28d4fa-2e60-49e4-afa0-073da2721d12}configurationId',
            'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.relationships.{7967dce2-7132-40c2-a3b5-61e33414d314}configurationRegion.fields.{eecc01ce-fba5-4cdd-81b9-18121b9d6fbf}regionId',
            'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.relationships.{d192fa94-4c86-4398-ab5a-990d09a9023a}timesheetConfiguration.fields.{47bb9534-59a3-437d-87a3-27fbba73435f}enableAutoApprove',
            'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.relationships.{d192fa94-4c86-4398-ab5a-990d09a9023a}timesheetConfiguration.fields.{debcf6b7-7be0-4702-a72d-cf7ac74e0530}noApprovalCheck',
            'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{76aa73c1-c637-4b3d-840a-061906d985f8}jobNumber',
            'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{dba57993-6687-4e94-adce-3841f30378ed}workOrderNumber'
          }
        )
      },
      filters: {
        a!queryFilter(
          field: 'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{dba57993-6687-4e94-adce-3841f30378ed}workOrderNumber',
          operator: "in",
          value: touniformstring(local!uniqueWoNumbers)
        )
      },
      pagingInfo: a!pagingInfo(
        startIndex: 1,
        batchSize: cons!ROME_INT_BATCH_SIZE_LARGE,
        sort: a!sortInfo(
          field: 'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{33425852-37b0-4187-a7cf-bc3d799ecd5c}createdOn',
          ascending: false()
        )
      ),

    ).data,
    local!isFAorExp: and(
      a!isUserMemberOfGroup(
        username: local!loggedInUser,
        groups: {
          cons!ATE_GRP_FIELD_ADMIN,
          cons!ATE_GRP_EXPEDITOR
        }
      ),
      not(
        a!isUserMemberOfGroup(
          username: local!loggedInUser,
          groups: { cons!ROME_GRP_ALL_REGION_SUPER_USERS }
        )
      )
    ),
    local!leadershipInfo: rule!ROME_QRY_getAdminGroupLeadership(
      fields: {
        'recordType!{a796974b-99f7-4d74-b0bb-1aec44ea97b1}ROME Ref Admin Group Leadership.fields.{055833a2-21cf-4ebb-a6ba-8fd32ca2581f}id'
      },
      regionIds: a!defaultValue(
        tointeger(
          index(
            local!productionUnitWo,
            'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.relationships.{7967dce2-7132-40c2-a3b5-61e33414d314}configurationRegion.fields.{eecc01ce-fba5-4cdd-81b9-18121b9d6fbf}regionId',
            null
          )
        ),
        0
      ),
      leadUsername: local!loggedInUser,
      employeeIds: local!laborIds,
      pagingInfo: a!pagingInfo(1, 1)
    ),
    local!isAdminLeadership: if(
      local!isFAorExp = true,
      a!isNotNullOrEmpty(local!leadershipInfo),
      false
    ),
    local!canApproveTimesheets: or(
      local!isAdminLeadership = true,
      or(
        a!isUserMemberOfGroup(
          username: local!loggedInUser,
          groups: { cons!ATE_GRP_CAN_APPROVE_TIMESHEETS }
        )
      )
    ),
    local!canReviewTimesheets: or(
      local!isAdminLeadership = true,
      a!isUserMemberOfGroup(
        username: local!loggedInUser,
        groups: { cons!ATE_GRP_CAN_REVIEW_TIMESHEETS }
      )
    ),
    local!rateData: rule!ATE_UTIL_getRateDataForLineItems(
      jobNumber: index(
        local!productionUnitWo,
        'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{76aa73c1-c637-4b3d-840a-061906d985f8}jobNumber',
        0
      ),
      serviceItemId: tointeger(
        reject(
          a!isNullOrEmpty(_),
          index(
            index(local!allWorkOrders, "units", null),
            "serviceItemId",
            {}
          )
        )
      )
    ),
    local!qryVppmData: rule!VPPM_QRY_getTaskOrderDetails(
      logicalExpressions: a!queryLogicalExpression(
        operator: "AND",
        ignoreFiltersWithEmptyValues: true,
        filters: {
          a!queryFilter(
            field: 'recordType!{c7f98593-f635-4263-adee-fdc72b23541a}VPPM Task Order.fields.{5a76a681-9a22-4617-9be3-5d636ab90d29}taskOrderNumber',
            operator: "in",
            value: local!uniqueWoNumbers
          ),
          a!queryFilter(
            field: 'recordType!{c7f98593-f635-4263-adee-fdc72b23541a}VPPM Task Order.fields.{77eed247-7219-465f-9869-14db062ee2da}isActive',
            operator: "=",
            value: true
          )
        }
      ),
      fields: {
        'recordType!{c7f98593-f635-4263-adee-fdc72b23541a}VPPM Task Order.fields.{d12620a2-03cb-44ae-bdfe-383406929cb2}taskOrderId',
        'recordType!{c7f98593-f635-4263-adee-fdc72b23541a}VPPM Task Order.fields.{5a76a681-9a22-4617-9be3-5d636ab90d29}taskOrderNumber',
        'recordType!{c7f98593-f635-4263-adee-fdc72b23541a}VPPM Task Order.relationships.{7e6ef8e4-68dc-42ed-8c42-077902f0f83a}document',
        'recordType!{c7f98593-f635-4263-adee-fdc72b23541a}VPPM Task Order.relationships.{7e6ef8e4-68dc-42ed-8c42-077902f0f83a}document.fields.{0f38cc62-6167-4222-bde4-e15b4a1b6a2b}appDocId'
      }
    ).data,
    local!contractorTimesheet: a!forEach(
      items: local!uniqueWoNumbers,
      expression: a!localVariables(
        local!currentWoNumber: fv!item,
        local!currentWOData: index(
          local!allWorkOrders,
          wherecontains(
            tostring(local!currentWoNumber),
            touniformstring(
              index(
                local!allWorkOrders,
                "workOrderNumber",
                {}
              )
            )
          ),
          {}
        ),
        local!allLabors: a!flatten(index(local!currentWOData, "labors", {})),
        local!uniqueEmployees: union(
          index(local!allLabors, "employeeId", {}),
          index(local!allLabors, "employeeId", {})
        ),
        local!allEquipments: a!flatten(
          index(local!currentWOData, "equipments", {})
        ),
        local!uniqueEquipments: union(
          index(local!allEquipments, "equipmentId", {}),
          index(local!allEquipments, "equipmentId", {})
        ),
        local!currentWoTimesheetConfiguration: index(
          index(
            local!productionUnitWo,
            wherecontains(
              tostring(local!currentWoNumber),
              touniformstring(
                local!productionUnitWo['recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{dba57993-6687-4e94-adce-3841f30378ed}workOrderNumber']
              )
            ),
            null
          ),
          'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.relationships.{d192fa94-4c86-4398-ab5a-990d09a9023a}timesheetConfiguration',
          null
        ),
        local!laborTime: a!forEach(
          items: local!uniqueEmployees,
          expression: a!localVariables(
            local!hourtypes: index(
              index(local!allLabors, "hourTypes", {}),
              wherecontains(
                tostring(fv!item),
                touniformstring(index(local!allLabors, "employeeId", {}))
              ),
              {}
            ),
            local!uniqueHourTypeId: union(
              index(local!hourtypes, "hourTypeId", {}),
              index(local!hourtypes, "hourTypeId", {})
            ),
            local!psuser: fv!item,
            local!laborTime: 'recordType!{f385689d-d73b-4e7c-874d-d460af0bd0a1}ROME Labor Time'(
              'recordType!{f385689d-d73b-4e7c-874d-d460af0bd0a1}ROME Labor Time.fields.{e93231f4-a083-4afb-9ca2-3bbff0815895}psUser': local!psuser,
              'recordType!{f385689d-d73b-4e7c-874d-d460af0bd0a1}ROME Labor Time.fields.{2a80469f-1426-4ba1-abac-7a3c8aa1fbc6}createdBy': local!loggedInUser,
              'recordType!{f385689d-d73b-4e7c-874d-d460af0bd0a1}ROME Labor Time.fields.{c53bb8a4-d3e1-4571-9aaa-56ef7afc5be2}createdOn': local!currentDateTime,
              'recordType!{f385689d-d73b-4e7c-874d-d460af0bd0a1}ROME Labor Time.fields.{cb089710-1da1-49e9-b0b6-29554937381e}modifiedBy': local!loggedInUser,
              'recordType!{f385689d-d73b-4e7c-874d-d460af0bd0a1}ROME Labor Time.fields.{9b16c484-481f-429a-991a-9cbac81934d6}modifiedOn': local!currentDateTime,
              'recordType!{f385689d-d73b-4e7c-874d-d460af0bd0a1}ROME Labor Time.fields.{e9a6070e-ea2c-4b34-ac97-d69767a51587}isActive': true,
              'recordType!{f385689d-d73b-4e7c-874d-d460af0bd0a1}ROME Labor Time.relationships.{3dfd77ed-53f6-48f4-b037-a59577239447}romeLaborTimeWorkOrder': 'recordType!{8634c6ed-4c8b-4405-bd6d-276048ff6b6c}ROME Labor Time Work Order'(
                'recordType!{8634c6ed-4c8b-4405-bd6d-276048ff6b6c}ROME Labor Time Work Order.fields.{86a206fa-3fc4-45b0-872c-949c7e358061}workOrderNumber': local!currentWoNumber,
                'recordType!{8634c6ed-4c8b-4405-bd6d-276048ff6b6c}ROME Labor Time Work Order.fields.{0ee1445b-f4cf-4e30-a3b7-f8972c506b7d}createdBy': local!loggedInUser,
                'recordType!{8634c6ed-4c8b-4405-bd6d-276048ff6b6c}ROME Labor Time Work Order.fields.{715e852b-ea6f-4d38-9b70-b67afe9c4947}createdOn': local!currentDateTime,
                'recordType!{8634c6ed-4c8b-4405-bd6d-276048ff6b6c}ROME Labor Time Work Order.fields.{316972e1-395e-440f-8ffe-cc3d78372803}modifiedBy': local!loggedInUser,
                'recordType!{8634c6ed-4c8b-4405-bd6d-276048ff6b6c}ROME Labor Time Work Order.fields.{c5eaf56d-7266-4d0b-a9a5-77abf4dd65d4}modifiedOn': local!currentDateTime,
                'recordType!{8634c6ed-4c8b-4405-bd6d-276048ff6b6c}ROME Labor Time Work Order.fields.{f914ce96-3db9-46b7-8637-7bc0c09bb903}isActive': true,
                'recordType!{8634c6ed-4c8b-4405-bd6d-276048ff6b6c}ROME Labor Time Work Order.relationships.{973e44e8-5eae-4586-ad73-21e01c3ff08f}romeLaborTimeHourType': a!forEach(
                  items: local!uniqueHourTypeId,
                  expression: a!localVariables(
                    local!hourTypeId: fv!item,
                    'recordType!{6092af5d-4987-4535-8b3f-d890771500a7}ROME Labor Time Hour Type'(
                      'recordType!{6092af5d-4987-4535-8b3f-d890771500a7}ROME Labor Time Hour Type.fields.{52aa084c-8bdb-4bde-a013-ed1e3f8d2096}hourTypeId': local!hourTypeId,
                      'recordType!{6092af5d-4987-4535-8b3f-d890771500a7}ROME Labor Time Hour Type.fields.{eabd54b9-e782-427d-b2d4-0183a6269659}createdBy': local!loggedInUser,
                      'recordType!{6092af5d-4987-4535-8b3f-d890771500a7}ROME Labor Time Hour Type.fields.{de6d50aa-a130-400c-9cfc-f96de8c0b04f}createdOn': local!currentDateTime,
                      'recordType!{6092af5d-4987-4535-8b3f-d890771500a7}ROME Labor Time Hour Type.fields.{377c911a-245c-4d41-a91b-2479d1e6caee}modifiedBy': local!loggedInUser,
                      'recordType!{6092af5d-4987-4535-8b3f-d890771500a7}ROME Labor Time Hour Type.fields.{24bdab06-0cb0-4bf5-b621-992b60baeade}modifiedOn': local!currentDateTime,
                      'recordType!{6092af5d-4987-4535-8b3f-d890771500a7}ROME Labor Time Hour Type.fields.{a5e74821-7f9a-4a72-bccc-75dd53ac4670}isActive': true,
                      'recordType!{6092af5d-4987-4535-8b3f-d890771500a7}ROME Labor Time Hour Type.relationships.{4a0a78bf-e1e6-4435-938e-1bb2ae3384ee}romeLaborTimeEntry': a!forEach(
                        items: local!currentWOData,
                        expression: a!localVariables(
                          local!currentLabor: index(
                            index(fv!item, "labors", {}),
                            wherecontains(
                              tostring(local!psuser),
                              touniformstring(
                                index(
                                  index(fv!item, "labors", {}),
                                  "employeeId",
                                  {}
                                )
                              )
                            ),
                            {}
                          ),
                          local!currentHourTypes: index(local!currentLabor, "hourTypes", {}),
                          local!hours: index(
                            a!flatten(local!currentHourTypes),
                            wherecontains(
                              tointeger(local!hourTypeId),
                              tointeger(
                                index(local!currentHourTypes, "hourTypeId", {})
                              )
                            ),
                            {}
                          ),
                          'recordType!{ce20694f-0d07-4c02-817d-da7b15378ed6}ROME Labor Time Entry'(
                            'recordType!{ce20694f-0d07-4c02-817d-da7b15378ed6}ROME Labor Time Entry.fields.{654b532e-4713-4e98-88f8-609945b987e6}workDate': index(ri!finalMap[fv!index], "date", {}),
                            'recordType!{ce20694f-0d07-4c02-817d-da7b15378ed6}ROME Labor Time Entry.fields.{2ad9b808-33bd-443d-ae59-e6e04db38391}hours': a!defaultValue(
                              value: index(local!hours, "hours", 0),
                              default: 0
                            ),
                            'recordType!{ce20694f-0d07-4c02-817d-da7b15378ed6}ROME Labor Time Entry.fields.{0b251f72-4b8d-4bbd-8dc6-3df618756c28}payrollConfigOverrideId': tointeger(index(index(local!currentLabor, "payrollConfigOverrideId", {}), 1, null)),
                            'recordType!{ce20694f-0d07-4c02-817d-da7b15378ed6}ROME Labor Time Entry.fields.{2121f43d-b931-49a6-af2b-86e69ddc1b26}payrollOverrideRate': todecimal(index(index(local!hours, "payrollOverrideRate", {}), 1, null)),
                            'recordType!{ce20694f-0d07-4c02-817d-da7b15378ed6}ROME Labor Time Entry.fields.{bf7d8364-433d-45d5-9d50-2106c5df5fb2}workOrder': local!currentWoNumber,
                            'recordType!{ce20694f-0d07-4c02-817d-da7b15378ed6}ROME Labor Time Entry.fields.{182dc670-a338-418c-a41a-89adf57b6e56}createdOn': local!currentDateTime,
                            'recordType!{ce20694f-0d07-4c02-817d-da7b15378ed6}ROME Labor Time Entry.fields.{c293f485-337a-4e43-8341-e34aacb1ccb8}createdBy': local!loggedInUser,
                            'recordType!{ce20694f-0d07-4c02-817d-da7b15378ed6}ROME Labor Time Entry.fields.{f57e5c6f-a050-4355-9528-2d007688bf31}modifiedOn': local!currentDateTime,
                            'recordType!{ce20694f-0d07-4c02-817d-da7b15378ed6}ROME Labor Time Entry.fields.{f695ef53-5c9f-4d22-b57d-25a263665851}modifiedBy': local!loggedInUser,
                            'recordType!{ce20694f-0d07-4c02-817d-da7b15378ed6}ROME Labor Time Entry.fields.{ff456610-a185-4e7c-bd17-d03baaa050c9}isActive': true
                          )
                        )
                      )
                    )
                  )
                )
              )
            ),
            local!laborTime
          )
        ),
        local!equipmentTime: a!forEach(
          items: local!uniqueEquipments,
          expression: a!localVariables(
            local!currentEquipmentId: fv!item,
            'recordType!{4add342c-2927-4898-996d-2e6a0f0ec2df}ROME Equipment Time'(
              'recordType!{4add342c-2927-4898-996d-2e6a0f0ec2df}ROME Equipment Time.fields.{b1085ec3-39d3-4b77-b40a-beb328e80900}refEquipmentId': local!currentEquipmentId,
              'recordType!{4add342c-2927-4898-996d-2e6a0f0ec2df}ROME Equipment Time.fields.{88ddf8fd-b363-47cf-86e4-02b0cb60f6b9}createdBy': local!loggedInUser,
              'recordType!{4add342c-2927-4898-996d-2e6a0f0ec2df}ROME Equipment Time.fields.{159e2e76-7078-40ec-bf2a-332edd2885cb}createdOn': local!currentDateTime,
              'recordType!{4add342c-2927-4898-996d-2e6a0f0ec2df}ROME Equipment Time.fields.{77e79ac0-1076-4c3e-aea6-170bcf33268b}modifiedBy': local!loggedInUser,
              'recordType!{4add342c-2927-4898-996d-2e6a0f0ec2df}ROME Equipment Time.fields.{3ca119ed-5ae3-4777-85c7-10f6e9badd47}modifiedOn': local!currentDateTime,
              'recordType!{4add342c-2927-4898-996d-2e6a0f0ec2df}ROME Equipment Time.fields.{59bd87ec-08ae-4d85-9832-cad4dcf024df}isActive': true,
              'recordType!{4add342c-2927-4898-996d-2e6a0f0ec2df}ROME Equipment Time.relationships.{aa8e5010-64b6-4e8e-9277-44e0c448a215}romeEquipmentTimeWorkOrder': 'recordType!{d2cf6acd-6b2d-4aaf-867a-11d484584a30}ROME Equipment Time Work Order'(
                'recordType!{d2cf6acd-6b2d-4aaf-867a-11d484584a30}ROME Equipment Time Work Order.fields.{7281b4be-3efd-4a47-b19b-8b49140602d6}workOrderNumber': local!currentWoNumber,
                'recordType!{d2cf6acd-6b2d-4aaf-867a-11d484584a30}ROME Equipment Time Work Order.fields.{a352a385-21a9-4a5c-9f15-c42de6e14143}createdBy': local!loggedInUser,
                'recordType!{d2cf6acd-6b2d-4aaf-867a-11d484584a30}ROME Equipment Time Work Order.fields.{001e9435-78dc-4127-a33d-aaaa94622bf3}createdOn': local!currentDateTime,
                'recordType!{d2cf6acd-6b2d-4aaf-867a-11d484584a30}ROME Equipment Time Work Order.fields.{1a671d2b-24c4-422b-9554-f4ecaebfdbe6}modifiedBy': local!loggedInUser,
                'recordType!{d2cf6acd-6b2d-4aaf-867a-11d484584a30}ROME Equipment Time Work Order.fields.{011dc1d1-d580-4a6b-8eed-88a7e6b7f529}modifiedOn': local!currentDateTime,
                'recordType!{d2cf6acd-6b2d-4aaf-867a-11d484584a30}ROME Equipment Time Work Order.fields.{176f8a56-4be6-46fd-b2bb-8a1841183bdf}isActive': true,
                'recordType!{d2cf6acd-6b2d-4aaf-867a-11d484584a30}ROME Equipment Time Work Order.relationships.{59e3485b-0b65-4a18-aace-246b38a89d4e}romeEquipmentTimeEntry': a!forEach(
                  items: local!currentWOData,
                  expression: a!localVariables(
                    local!dayEquipments: index(fv!item, "equipments", {}),
                    local!thisEquipment: index(
                      local!dayEquipments,
                      wherecontains(
                        tostring(local!currentEquipmentId),
                        touniformstring(
                          index(local!dayEquipments, "equipmentId", {})
                        )
                      ),
                      {}
                    ),
                    'recordType!{8a3b50a6-b833-4378-b8e9-d35550abfe12}ROME Equipment Time Entry'(
                      'recordType!{8a3b50a6-b833-4378-b8e9-d35550abfe12}ROME Equipment Time Entry.fields.{671284f9-0db6-4a06-8626-c0a71b14cdc5}workDate': index(ri!finalMap[fv!index], "date", {}),
                      'recordType!{8a3b50a6-b833-4378-b8e9-d35550abfe12}ROME Equipment Time Entry.fields.{6a8da257-4ef9-4ca5-b6ef-c637c9e3e648}hours': a!defaultValue(
                        value: index(local!thisEquipment, "hours", 0),
                        default: 0
                      ),
                      'recordType!{8a3b50a6-b833-4378-b8e9-d35550abfe12}ROME Equipment Time Entry.fields.{3ff35a09-9e56-4185-bc6c-8dfe267e29a2}payrollOverrideConfigId': tointeger(index(index(local!thisEquipment, "payrollConfigOverrideId", {}), 1, null)),
                      'recordType!{8a3b50a6-b833-4378-b8e9-d35550abfe12}ROME Equipment Time Entry.fields.{1059d649-13a1-4f2f-8a6c-6ad3f01d6f44}overrideRate': todecimal(index(index(local!thisEquipment, "payrollOverrideRate", {}), 1, null)),
                      'recordType!{8a3b50a6-b833-4378-b8e9-d35550abfe12}ROME Equipment Time Entry.fields.{b671717e-3cd7-40bb-9c9a-2bebda539c3b}createdOn': local!currentDateTime,
                      'recordType!{8a3b50a6-b833-4378-b8e9-d35550abfe12}ROME Equipment Time Entry.fields.{566b0f1e-a96e-4ca7-986a-821bee2be66b}createdBy': local!loggedInUser,
                      'recordType!{8a3b50a6-b833-4378-b8e9-d35550abfe12}ROME Equipment Time Entry.fields.{b531370a-9833-46a9-8fb6-0fa2262de763}modifiedOn': local!currentDateTime,
                      'recordType!{8a3b50a6-b833-4378-b8e9-d35550abfe12}ROME Equipment Time Entry.fields.{fc961970-6b0e-49a5-a527-572b165acbcc}modifiedBy': local!loggedInUser,
                      'recordType!{8a3b50a6-b833-4378-b8e9-d35550abfe12}ROME Equipment Time Entry.fields.{057894a3-2b58-4b4d-8279-5557ca85fe97}isActive': true
                    )
                  )
                )
              )
            )
          )
        ),
        local!documents: a!forEach(
          reject(a!isNullOrEmpty(_), a!flatten(local!currentWOData.photoDocId)),
          'recordType!{327af341-68c8-4de1-aae2-dbe1b07c156c}ROME Document'(
            'recordType!{327af341-68c8-4de1-aae2-dbe1b07c156c}ROME Document.fields.{8ce757bb-2ae5-4731-9e04-7ee608cf4e91}apnDocId': fv!item,
            'recordType!{327af341-68c8-4de1-aae2-dbe1b07c156c}ROME Document.fields.{4ca40acc-8d1c-4bd8-a8a0-1cd9cbaad89b}woNumber': local!currentWoNumber,
            'recordType!{327af341-68c8-4de1-aae2-dbe1b07c156c}ROME Document.fields.{1972bb8f-0712-4fcb-b079-8220a37a4c64}createdOn': local!currentDateTime,
            'recordType!{327af341-68c8-4de1-aae2-dbe1b07c156c}ROME Document.fields.{7722775e-67ee-4e68-ad5c-6488fc4b79b1}createdBy': local!loggedInUser,
            'recordType!{327af341-68c8-4de1-aae2-dbe1b07c156c}ROME Document.fields.{409d9fc4-6c9f-4d03-85ce-ea0eba01b4d5}docCategoryId': cons!ATE_ROME_DOCUMENT_CATEGORY[2],
            'recordType!{327af341-68c8-4de1-aae2-dbe1b07c156c}ROME Document.fields.{d7ee4c4d-2505-4218-ae9c-808dd7f9c618}isActive': true
          )
        ),
        local!comment: a!forEach(
          reject(a!isNullOrEmpty(_), union(touniformstring(a!flatten(local!currentWOData.timesheetComments)), touniformstring({}))),
          'recordType!{7aeeb109-f78e-43c3-b166-6b73791f2df6}ROME Comment'(
            'recordType!{7aeeb109-f78e-43c3-b166-6b73791f2df6}ROME Comment.fields.{aa098d1c-4c81-49b7-addf-98dad0fa141f}comment': fv!item,
            'recordType!{7aeeb109-f78e-43c3-b166-6b73791f2df6}ROME Comment.fields.{b3988865-04ca-43d1-99ca-362c15738c27}createdBy': local!loggedInUser,
            'recordType!{7aeeb109-f78e-43c3-b166-6b73791f2df6}ROME Comment.fields.{351882ce-8c54-4682-91ab-de3d031a9463}createdOn': local!currentDateTime,
            'recordType!{7aeeb109-f78e-43c3-b166-6b73791f2df6}ROME Comment.fields.{f6f95daa-fd4e-47bd-b117-4b47e66ce3da}isActive': true
          )
        ),
        'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet'(
          'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet.fields.{5abda596-55f8-495a-adc5-773d0acca690}endDate': local!weekStartDate + 6,
          'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet.fields.{3a88a48b-5629-4c74-8e0f-a80b1b0a9847}startDate': local!weekStartDate,
          'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet.fields.{90a18c38-deed-48eb-9ae9-a0518f322c5e}contractRegion102Id': index(
            local!productionUnitWo['recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.fields.{463641a3-0f56-44a8-8b12-8018f2724f0c}id'],
            wherecontains(
              tostring(local!currentWoNumber),
              touniformstring(
                local!productionUnitWo['recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{dba57993-6687-4e94-adce-3841f30378ed}workOrderNumber']
              )
            ),
            null
          ),
          'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet.fields.{6d01bade-70b1-4509-837c-57cf57d8fd55}contractType': index(
            local!productionUnitWo['recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.fields.{d1110989-7d6c-482b-918e-1168589689bb}contractType'],
            wherecontains(
              tostring(local!currentWoNumber),
              touniformstring(
                local!productionUnitWo['recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{dba57993-6687-4e94-adce-3841f30378ed}workOrderNumber']
              )
            ),
            null
          ),
          'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet.fields.{d1c3582c-e64f-4c8b-a128-c20efadabc3c}contract': index(
            local!productionUnitWo['recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.fields.{e25b88f2-b2d5-4ce3-883b-596ba699272d}jobNumber'],
            wherecontains(
              tostring(local!currentWoNumber),
              touniformstring(
                local!productionUnitWo['recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{dba57993-6687-4e94-adce-3841f30378ed}workOrderNumber']
              )
            ),
            null
          ),
          'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet.fields.{53d98860-18ae-4cd4-b1ba-a38ee0690082}ulcsCrewNumber': index(local!weekInfo, "crew", null),
          'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet.fields.{692d49d3-064a-4d75-9f62-4bbbb93165e3}foreman': local!loggedInUser,
          'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet.fields.{a4d90ddc-10d3-4fd9-a2ab-70dad0ab9f74}submittedToGFOn': local!currentDateTime,
          'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet.fields.{e779517b-46e4-40c1-a4ff-c3af388a7c9b}createdBy': local!loggedInUser,
          'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet.fields.{7b4b3a87-a49e-494b-9e59-bb2c06a5ab5a}createdOn': local!currentDateTime,
          'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet.fields.{36feefdb-1dcc-452b-9e6e-0b542556c344}modifiedBy': local!loggedInUser,
          'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet.fields.{86182fde-1b4e-4f95-9c81-2a92d7197051}modifiedOn': now(),
          'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet.fields.{5c8f7fc6-d63f-4a76-8f83-528dc6a59028}isActive': true,
          'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet.relationships.{a7636df1-7dc0-411e-88f8-e827b30e594c}romeEquipmentTime': local!equipmentTime,
          'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet.relationships.{56fb979c-7c18-4ccf-833d-678db430c554}romeLaborTime': local!laborTime,
          'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet.fields.{b0b3d2cb-646e-4484-8fda-3a069458a204}timesheetStatusId': a!match(
            value: true,
            whenTrue: or(
              cast(
                26,
                a!defaultValue(
                  index(
                    local!currentWoTimesheetConfiguration,
                    'recordType!{b05a3d8d-9cc2-4189-8e62-bd21325d69d5}ATE Timesheet Configuration.fields.{debcf6b7-7be0-4702-a72d-cf7ac74e0530}noApprovalCheck',
                    null
                  ),
                  false()
                )
              ),
              local!canApproveTimesheets,
              and(
                local!canApproveTimesheets,
                toboolean(
                  index(
                    local!currentWoTimesheetConfiguration,
                    'recordType!{b05a3d8d-9cc2-4189-8e62-bd21325d69d5}ATE Timesheet Configuration.fields.{47bb9534-59a3-437d-87a3-27fbba73435f}enableAutoApprove',
                    null
                  )
                ) = true
              )
            ),
            then: cons!ROME_INT_TIMESHEET_STATUS_APPROVED,
            whenTrue: local!canReviewTimesheets,
            then: cons!ROME_INT_TIMESHEET_STATUS_REVIEWED,
            default: cons!ROME_INT_TIMESHEET_STATUS_UNDER_REVIEW
          ),
          'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet.relationships.{18d36ed2-3708-454e-8418-bb8c58b31a4a}romeDocument': local!documents,
          'recordType!{fc7a9098-c133-40ff-9e0d-836b9f6744ed}ROME Contractor Timesheet.relationships.{632c78bc-5622-416d-a9c7-baa29432b9eb}romeComment': local!comment
        )
      )
    ),
    local!addOnEntries: a!flatten(
      a!forEach(
        items: ri!finalMap,
        expression: a!localVariables(
          local!dayDate: todate(index(fv!item, "date", null)),
          a!forEach(
            items: index(fv!item, "workOrderData", {}),
            expression: a!localVariables(
              local!units: index(fv!item, "units", {}),
              local!woNumber: index(fv!item, "workOrderNumber", null),
              local!unitComments: index(fv!item, "unitsComments", null),
              local!woLocations: reject(
                fn!isnull,
                a!defaultValue(index(fv!item, "locations", {}), {})
              ),
              local!woLocIds: tointeger(
                index(
                  local!woLocations,
                  'recordType!{a0c3b30f-63f4-4cfd-b455-4551d7f088f8}ATE Location.fields.{b84015f5-1b00-4f7c-86b6-8775218a0ced}locationId',
                  {}
                )
              ),
              local!woLocNames: touniformstring(
                index(
                  local!woLocations,
                  'recordType!{a0c3b30f-63f4-4cfd-b455-4551d7f088f8}ATE Location.fields.{91e4030f-9721-453e-83ac-43e7cc409cdf}name',
                  {}
                )
              ),
              a!forEach(
                items: reject(
                  fn!isnull,
                  a!forEach(
                    items: local!units,
                    expression: if(
                      and(
                        a!defaultValue(
                          index(fv!item, "isAdhoc", false()),
                          false()
                        ),
                        todecimal(
                          a!defaultValue(index(fv!item, "quantity", null), 0)
                        ) > 0
                      ),
                      fv!item,
                      null()
                    )
                  )
                ),
                expression: a!localVariables(
                  local!rateIdx: index(
                    wherecontains(
                      tointeger(index(fv!item, "serviceItemId", 0)),
                      tointeger(
                        index(
                          local!rateData,
                          'recordType!{1b5efd17-5248-4798-860e-2aa3ad0b8602}ROME Service Item Rate Table.fields.{0847c18f-9dcd-4cfc-b013-d168ae286103}serviceItemId',
                          {}
                        )
                      )
                    ),
                    1,
                    null
                  ),
                  local!unitLocId: a!defaultValue(tointeger(index(fv!item, "locationId", null)), 0),
                  local!unitLocName: trim(
                    if(
                      a!isNullOrEmpty(index(fv!item, "locationName", null)),
                      index(
                        index(local!woLocNames, wherecontains(tointeger(local!unitLocId), tointeger(local!woLocIds)), {}),
                        1,
                        ""
                      ),
                      tostring(index(fv!item, "locationName", ""))
                    )
                  ),
                  local!isNewLoc: and(local!unitLocId < 0, a!isNotNullOrEmpty(local!unitLocName)),
                  a!map(
                    woNumber: local!woNumber,
                    isNewLoc: local!isNewLoc,
                    locationName: if(and(local!unitLocId < 0, a!isNotNullOrEmpty(local!unitLocName)), local!unitLocName, null),
                    item: 'recordType!{ee06068f-c1b0-4dad-85c6-4ac1ecccce1e}ROME Production Unit WO Add On'(
                      'recordType!{ee06068f-c1b0-4dad-85c6-4ac1ecccce1e}ROME Production Unit WO Add On.fields.{8a04c4b3-aca0-4104-affe-fb12f3aaab35}woNumber': local!woNumber,
                      'recordType!{ee06068f-c1b0-4dad-85c6-4ac1ecccce1e}ROME Production Unit WO Add On.fields.{82ba5ab4-e2b4-47d2-98c7-18941a7abed4}serviceItemId': index(fv!item, "serviceItemId", null),
                      'recordType!{ee06068f-c1b0-4dad-85c6-4ac1ecccce1e}ROME Production Unit WO Add On.fields.{4c4d8e9b-e008-46b3-bf08-19bc8561f925}locationId': if(local!unitLocId < 0, null, index(fv!item, "locationId", null)),
                      'recordType!{ee06068f-c1b0-4dad-85c6-4ac1ecccce1e}ROME Production Unit WO Add On.fields.{8a4b4bcd-ed2a-49c8-b31b-09276977908a}actualQuantity': index(fv!item, "quantity", null),
                      'recordType!{ee06068f-c1b0-4dad-85c6-4ac1ecccce1e}ROME Production Unit WO Add On.fields.{6f1fe486-32cb-411c-8915-c19e1b18d6d8}completionDate': local!dayDate,
                      'recordType!{ee06068f-c1b0-4dad-85c6-4ac1ecccce1e}ROME Production Unit WO Add On.fields.{b9f1d9e6-6287-4fda-91ea-a1f14c69a69e}isActive': true,
                      'recordType!{ee06068f-c1b0-4dad-85c6-4ac1ecccce1e}ROME Production Unit WO Add On.fields.{0fba660c-a6a3-4e74-bfce-8dab7ee69b25}createdBy': local!loggedInUser,
                      'recordType!{ee06068f-c1b0-4dad-85c6-4ac1ecccce1e}ROME Production Unit WO Add On.fields.{22902462-71c7-4c12-b910-1ebf4d0efd55}createdOn': local!currentDateTime,
                      'recordType!{ee06068f-c1b0-4dad-85c6-4ac1ecccce1e}ROME Production Unit WO Add On.fields.{020cda85-37e6-4e57-9265-67dbe3679532}modifiedBy': local!loggedInUser,
                      'recordType!{ee06068f-c1b0-4dad-85c6-4ac1ecccce1e}ROME Production Unit WO Add On.fields.{ee8182d8-c98b-4474-9708-b0e11297cc0b}modifiedOn': local!currentDateTime,
                      'recordType!{ee06068f-c1b0-4dad-85c6-4ac1ecccce1e}ROME Production Unit WO Add On.fields.{a2e6b578-bda5-4d06-9610-70cde2a47e53}rateTableId': if(
                        isnull(local!rateIdx),
                        null,
                        index(
                          index(
                            local!rateData,
                            'recordType!{1b5efd17-5248-4798-860e-2aa3ad0b8602}ROME Service Item Rate Table.fields.{162f2778-4572-4c9e-b9c6-40b033d65325}rateTableId',
                            {}
                          ),
                          local!rateIdx,
                          null
                        )
                      ),
                      'recordType!{ee06068f-c1b0-4dad-85c6-4ac1ecccce1e}ROME Production Unit WO Add On.fields.{b45cfc3b-aae7-4eca-ab9e-7aed7f3229fe}serviceItemRateTableId': if(
                        isnull(local!rateIdx),
                        null,
                        index(
                          index(
                            local!rateData,
                            'recordType!{1b5efd17-5248-4798-860e-2aa3ad0b8602}ROME Service Item Rate Table.fields.{f535a79b-ce52-4cd6-aa06-4fd123ee9120}id',
                            {}
                          ),
                          local!rateIdx,
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
      )
    ),
    local!budgetItemEntries: a!flatten(
      a!forEach(
        items: ri!finalMap,
        expression: a!localVariables(
          local!dayDate: todate(index(fv!item, "date", null)),
          a!forEach(
            items: index(fv!item, "workOrderData", {}),
            expression: a!localVariables(
              local!units: index(fv!item, "units", {}),
              local!woNumber: index(fv!item, "workOrderNumber", null),
              local!rateTableIndex: wherecontains(
                tointeger(
                  index(local!units, "serviceItemId", null)
                ),
                tointeger(
                  index(
                    local!rateData,
                    'recordType!{1b5efd17-5248-4798-860e-2aa3ad0b8602}ROME Service Item Rate Table.fields.{0847c18f-9dcd-4cfc-b013-d168ae286103}serviceItemId',
                    null
                  )
                )
              ),
              local!unitComments: index(fv!item, "unitsComments", null),
              local!woLocations: reject(
                fn!isnull,
                a!defaultValue(index(fv!item, "locations", {}), {})
              ),
              local!woLocIds: tointeger(
                index(
                  local!woLocations,
                  'recordType!{a0c3b30f-63f4-4cfd-b455-4551d7f088f8}ATE Location.fields.{b84015f5-1b00-4f7c-86b6-8775218a0ced}locationId',
                  {}
                )
              ),
              local!woLocNames: touniformstring(
                index(
                  local!woLocations,
                  'recordType!{a0c3b30f-63f4-4cfd-b455-4551d7f088f8}ATE Location.fields.{91e4030f-9721-453e-83ac-43e7cc409cdf}name',
                  {}
                )
              ),
              a!forEach(
                items: reject(
                  fn!isnull,
                  a!forEach(
                    items: local!units,
                    expression: if(
                      and(
                        not(
                          a!defaultValue(
                            index(fv!item, "isAdhoc", false()),
                            false()
                          )
                        ),
                        todecimal(
                          a!defaultValue(index(fv!item, "quantity", null), 0)
                        ) > 0
                      ),
                      fv!item,
                      null()
                    )
                  )
                ),
                expression: a!localVariables(
                  local!unitLocId: a!defaultValue(tointeger(index(fv!item, "locationId", null)), 0),
                  local!unitLocName: trim(
                    if(
                      a!isNullOrEmpty(index(fv!item, "locationName", null)),
                      index(
                        index(local!woLocNames, wherecontains(tointeger(local!unitLocId), tointeger(local!woLocIds)), {}),
                        1,
                        ""
                      ),
                      tostring(index(fv!item, "locationName", ""))
                    )
                  ),
                  local!isNewLoc: and(local!unitLocId < 0, a!isNotNullOrEmpty(local!unitLocName)),
                  a!map(
                    woNumber: local!woNumber,
                    isNewLoc: local!isNewLoc,
                    locationName: if(and(local!unitLocId < 0, a!isNotNullOrEmpty(local!unitLocName)), local!unitLocName, null),
                    item: 'recordType!{3f0e2482-3261-4615-bda1-3ceb8b0f2d84}ROME Production Unit WO Budget Item'(
                      'recordType!{3f0e2482-3261-4615-bda1-3ceb8b0f2d84}ROME Production Unit WO Budget Item.fields.{09d7196d-c04d-4e00-b90d-10d486748985}createdBy': local!loggedInUser,
                      'recordType!{3f0e2482-3261-4615-bda1-3ceb8b0f2d84}ROME Production Unit WO Budget Item.fields.{66deb334-7025-4dde-ae85-31a7818da447}modifiedBy': local!loggedInUser,
                      'recordType!{3f0e2482-3261-4615-bda1-3ceb8b0f2d84}ROME Production Unit WO Budget Item.fields.{7c85ca78-f54a-4cbe-b835-93ef64cd6878}createdOn': local!currentDateTime,
                      'recordType!{3f0e2482-3261-4615-bda1-3ceb8b0f2d84}ROME Production Unit WO Budget Item.fields.{f5e7b965-a2fb-48d0-bea6-22c0e4373ff3}modifiedOn': local!currentDateTime,
                      'recordType!{3f0e2482-3261-4615-bda1-3ceb8b0f2d84}ROME Production Unit WO Budget Item.fields.{126a95d4-bd14-4238-ab64-a2c90fb9097c}isActive': true,
                      'recordType!{3f0e2482-3261-4615-bda1-3ceb8b0f2d84}ROME Production Unit WO Budget Item.fields.{f4ee36bb-12b9-4bff-9aad-9cb047ea96c4}completionDate': local!dayDate,
                      'recordType!{3f0e2482-3261-4615-bda1-3ceb8b0f2d84}ROME Production Unit WO Budget Item.fields.{45a3ab4a-70de-4b19-aca6-c0352557cbd5}woNumber': local!woNumber,
                      'recordType!{3f0e2482-3261-4615-bda1-3ceb8b0f2d84}ROME Production Unit WO Budget Item.fields.{08419b95-62fa-4d00-94c4-e0ca5b53642b}actualQuantity': index(fv!item, "quantity", null),
                      'recordType!{3f0e2482-3261-4615-bda1-3ceb8b0f2d84}ROME Production Unit WO Budget Item.fields.{bc45a76f-0a32-4d81-acfe-fe19ff97ae13}serviceItemNumber': index(fv!item, "serviceItemId", null),
                      'recordType!{3f0e2482-3261-4615-bda1-3ceb8b0f2d84}ROME Production Unit WO Budget Item.fields.{54218133-6b51-47c3-ae8b-bbebe26b09c1}locationId': if(local!unitLocId < 0, null, index(fv!item, "locationId", null)),
                      'recordType!{3f0e2482-3261-4615-bda1-3ceb8b0f2d84}ROME Production Unit WO Budget Item.fields.{1389f194-9064-4bc0-9a50-76750ff14da5}notes': local!unitComments,
                      'recordType!{3f0e2482-3261-4615-bda1-3ceb8b0f2d84}ROME Production Unit WO Budget Item.fields.{28a52782-a181-4cba-b3a4-5838a071842e}isBillable': true(),
                      'recordType!{3f0e2482-3261-4615-bda1-3ceb8b0f2d84}ROME Production Unit WO Budget Item.fields.{5e828018-d828-4b17-be41-233a6034d36e}rateTableId': index(
                        local!rateData['recordType!{1b5efd17-5248-4798-860e-2aa3ad0b8602}ROME Service Item Rate Table.fields.{162f2778-4572-4c9e-b9c6-40b033d65325}rateTableId'],
                        local!rateTableIndex,
                        null
                      ),
                      'recordType!{3f0e2482-3261-4615-bda1-3ceb8b0f2d84}ROME Production Unit WO Budget Item.fields.{0b6eac59-c498-4d3b-9445-2ddd987cd0f3}serviceItemRateTableId': index(
                        local!rateData['recordType!{1b5efd17-5248-4798-860e-2aa3ad0b8602}ROME Service Item Rate Table.fields.{f535a79b-ce52-4cd6-aa06-4fd123ee9120}id'],
                        tointeger(local!rateTableIndex),
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
    local!vppmTaskOrderDocs: a!forEach(
      items: local!uniqueWoNumbers,
      expression: a!localVariables(
        local!currentWoNumber: fv!item,
        local!currentWOData: index(
          local!allWorkOrders,
          wherecontains(
            tostring(local!currentWoNumber),
            touniformstring(
              index(
                local!allWorkOrders,
                "workOrderNumber",
                {}
              )
            )
          ),
          {}
        ),
        local!currentVppmData: index(
          local!qryVppmData,
          wherecontains(
            tostring(local!currentWoNumber),
            touniformstring(
              local!qryVppmData['recordType!{c7f98593-f635-4263-adee-fdc72b23541a}VPPM Task Order.fields.{5a76a681-9a22-4617-9be3-5d636ab90d29}taskOrderNumber']
            )
          ),
          {}
        ),
        local!existingTaskOrderId: index(
          local!currentVppmData,
          'recordType!{c7f98593-f635-4263-adee-fdc72b23541a}VPPM Task Order.fields.{d12620a2-03cb-44ae-bdfe-383406929cb2}taskOrderId',
          null
        ),
        local!photoDocIds: reject(
          a!isNullOrEmpty(_),
          a!flatten(
            index(local!currentWOData, "photoDocId", {})
          )
        ),
        local!vppmDocuments: a!forEach(
          items: local!photoDocIds,
          expression: 'recordType!{084f2fa6-2369-4f0e-b5c7-614aa614cb7d}VPPM Document'(
            'recordType!{084f2fa6-2369-4f0e-b5c7-614aa614cb7d}VPPM Document.fields.{2f135fd0-dabc-4d3c-b720-ce9d95b2abb9}taskOrderId': local!existingTaskOrderId,
            'recordType!{084f2fa6-2369-4f0e-b5c7-614aa614cb7d}VPPM Document.fields.{0f38cc62-6167-4222-bde4-e15b4a1b6a2b}appDocId': fv!item,
            'recordType!{084f2fa6-2369-4f0e-b5c7-614aa614cb7d}VPPM Document.fields.{97ad9b9b-06ab-475e-860e-d9c92e7b9241}typesId': cons!ATE_ROME_DOCUMENT_CATEGORY[1],
            'recordType!{084f2fa6-2369-4f0e-b5c7-614aa614cb7d}VPPM Document.fields.{d91dc245-dbd4-43ed-999a-ebe790ea0083}uploadedBy': local!loggedInUser,
            'recordType!{084f2fa6-2369-4f0e-b5c7-614aa614cb7d}VPPM Document.fields.{69ef1a40-a118-43c4-9595-f444a9e021af}uploadedOn': local!currentDateTime,
            'recordType!{084f2fa6-2369-4f0e-b5c7-614aa614cb7d}VPPM Document.fields.{7e64e16d-afc3-4cc2-b8db-c73783719689}isInternal': true(),
            'recordType!{084f2fa6-2369-4f0e-b5c7-614aa614cb7d}VPPM Document.fields.{9304bc79-b567-483a-ac95-96d2a3c851f2}isActive': true()
          )
        ),
        local!vppmDocuments
      )
    ),
    local!budgetEntryIsNewLoc: toboolean(index(local!budgetItemEntries, "isNewLoc", {})),
    local!addOnEntryIsNewLoc: toboolean(index(local!addOnEntries, "isNewLoc", {})),
    local!budgetItems: index(
      index(local!budgetItemEntries, "item", {}),
      wherecontains(false, toboolean(local!budgetEntryIsNewLoc)),
      {}
    ),
    local!adhocUnitAddOns: index(
      index(local!addOnEntries, "item", {}),
      wherecontains(false, toboolean(local!addOnEntryIsNewLoc)),
      {}
    ),
    local!newLocBudgetEntries: index(
      local!budgetItemEntries,
      wherecontains(true, toboolean(local!budgetEntryIsNewLoc)),
      {}
    ),
    local!newLocAddOnEntries: index(
      local!addOnEntries,
      wherecontains(true, toboolean(local!addOnEntryIsNewLoc)),
      {}
    ),
    local!adhocLocations: if(
      and(
        a!isNullOrEmpty(local!newLocBudgetEntries),
        a!isNullOrEmpty(local!newLocAddOnEntries)
      ),
      {},
      rule!ATE_UTIL_constructadhoclocations(
        workOrderNumbers: touniformstring(
          index(
            local!productionUnitWo,
            'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{dba57993-6687-4e94-adce-3841f30378ed}workOrderNumber',
            {}
          )
        ),
        configurationIds: tointeger(
          index(
            local!productionUnitWo,
            'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.fields.{6c28d4fa-2e60-49e4-afa0-073da2721d12}configurationId',
            {}
          )
        ),
        adhocBudgetItems: local!newLocBudgetEntries,
        adhocAddOns: local!newLocAddOnEntries,
        user: local!loggedInUser,
        currentDateTime: local!currentDateTime
      )
    ),
    a!map(
      contractorTimesheet: local!contractorTimesheet,
      budgetItems: local!budgetItems,
      vppmDocuments: local!vppmTaskOrderDocs,
      crewTemplate: local!updatedCrewTemplate,
      productionUnitWoAddOns: local!adhocUnitAddOns,
      adhocLocations: local!adhocLocations
    )
  )
)

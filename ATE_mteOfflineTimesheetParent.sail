a!localVariables(
  local!brandingMap: {
    headingLabelColor: cons!ROME_TEXT_HEX_ORANGE,
    cardStyleColor: "#FFFFFF",
    selectedCard: "#FBEEE2",
    cardBorderBasic: "STANDARD",
    cardBorderSelected: cons!ROME_TEXT_HEX_ORANGE,
    crewTemplateNameColor: cons!ROME_TEXT_HEX_ORANGE
  },
  local!loggedInUser: loggedInUser(),
  local!userCrews: reject(
    rule!ATE_checkIsNullOrEmptyArray,
    rule!ATE_UTIL_returnSyncedUserCrews(user: local!loggedInUser)/*index(*/
    /*rule!ROME_QRY_getUserCrewMapping(userName: { local!loggedInUser }).data,*/
    /*'recordType!{f1f2e9bc-e8e2-4910-bba7-b0b9b638c15a}ROME Ref User Crew.fields.{99b0416b-b336-46e1-80d2-e1e88e37ae36}crew',*/
    /*null*/
    /*)*/
    
  ),
  local!ulcsCrewNumbers: reject(a!isNullOrEmpty, local!userCrews),
  local!allCrewTemplates: rule!ATE_QRY_crewTemplate(
    additionalFilter: {
      a!queryFilter(
        field: 'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.fields.{c9a61a95-0d27-45a2-a6ff-353f21a3631c}crew',
        operator: "in",
        value: a!defaultValue(local!ulcsCrewNumbers, { "0" }),
        
      ),
      a!queryFilter(
        field: 'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.fields.{5ba71855-0909-4fc9-a2a6-51a91182fdc4}isActive',
        operator: "=",
        value: true
      )
    },
    fields: {
      'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.fields.{c9a61a95-0d27-45a2-a6ff-353f21a3631c}crew',
      'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.fields.{613eebb7-b28e-4805-b12c-42c7f5396694}id',
      'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.fields.{31d19529-415f-463c-9721-d92f5baad441}name',
      'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.fields.{c98e6171-f511-4002-a536-35dce2d2dfd2}targetHours',
      'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{ed8405a0-530c-4a91-aa6c-e890db20a06b}laborCrewTemplate.fields.{8517bfc8-4e01-438c-b917-59ad30eecfb8}employeeId',
      'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{ed8405a0-530c-4a91-aa6c-e890db20a06b}laborCrewTemplate.relationships.{4b28f158-8819-465b-b32c-0fbc93d18a47}syncedEmployeeData.fields.{9c68dd28-51b5-4f24-b275-99b80680bb13}fullName',
      'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{ed8405a0-530c-4a91-aa6c-e890db20a06b}laborCrewTemplate.relationships.{4b28f158-8819-465b-b32c-0fbc93d18a47}syncedEmployeeData.fields.{ac02686f-f95c-4eea-9a7e-e38d825a3ce8}jobDescription',
      'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{264b1308-dfb4-4db0-b8f2-270cba088a31}equipmentCrewTemplate.fields.{22247106-0086-4043-a0b9-224ba13c483c}equipmentId',
      'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{264b1308-dfb4-4db0-b8f2-270cba088a31}equipmentCrewTemplate.relationships.{0c56a132-3545-400e-892a-9e2bdd31cd2f}syncedRefEquipment.fields.{96b6ac3b-eed6-4175-bebd-cf2d1eee4d4d}idAndDescription',
      'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{264b1308-dfb4-4db0-b8f2-270cba088a31}equipmentCrewTemplate.relationships.{0c56a132-3545-400e-892a-9e2bdd31cd2f}syncedRefEquipment.fields.{7130ca36-a7b5-49e5-917e-f2818c8cec9b}regionEqDescription'
    },
    relatedRecordData: {
      a!relatedRecordData(
        relationship: 'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{ed8405a0-530c-4a91-aa6c-e890db20a06b}laborCrewTemplate',
        limit: 100,
        filters: a!queryFilter(
          field: 'recordType!{b29742d7-7644-4774-a125-5556cd9e0086}ATE Labor Crew Template.fields.{6c09d1c1-248f-42c3-8340-8beca5f650af}isActive',
          operator: "=",
          value: true
        )
      ),
      a!relatedRecordData(
        relationship: 'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{264b1308-dfb4-4db0-b8f2-270cba088a31}equipmentCrewTemplate',
        limit: 100,
        filters: a!queryFilter(
          field: 'recordType!{39493776-6005-4f99-adc0-4690c2177ef4}ATE Equipment Crew Template.fields.{bf857f8c-3ac1-4a05-a81a-8607de640fdd}isActive',
          operator: "=",
          value: true
        )
      )
    }
  ),
  local!allCrewWo: a!queryRecordType(
    recordType: 'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO',
    fields: {
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{dba57993-6687-4e94-adce-3841f30378ed}workOrderNumber',
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{e9b80a47-a6e1-49c9-b7ce-5397d606a098}ulcsCrewNumber',
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{22e23d4d-3430-477c-aef4-feab90926d5e}combinedWOAddress',
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{f108eaec-47ee-4785-88b4-a66c0a745096}productionUnitWoCrew.fields.{d551081f-1ce1-47ee-844a-04380f93ed10}ulcsCrewNumber',
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{f108eaec-47ee-4785-88b4-a66c0a745096}productionUnitWoCrew.fields.{df914951-7e7e-4a5c-8828-9c406056203a}workOrderNumber',
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.fields.{e25b88f2-b2d5-4ce3-883b-596ba699272d}jobNumber',
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.fields.{463641a3-0f56-44a8-8b12-8018f2724f0c}id',
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.fields.{6c28d4fa-2e60-49e4-afa0-073da2721d12}configurationId',
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.fields.{d1110989-7d6c-482b-918e-1168589689bb}contractType',
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{855c5c2d-5946-4e9c-8c84-eda5fd484f54}vppmTaskOrder.fields.{00ed1f58-45af-4ca4-a327-81402044b736}descriptionServicesRequested',
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{9de912bc-cb4a-4061-ac25-cb279443a748}contractList.fields.{66548d1e-7fca-4b67-994e-875197d87ee1}customerId',
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.relationships.{187d9785-3bf6-45aa-a289-5cb396e4e82f}unitConfiguration.fields.{5f412f47-933a-4938-9123-58578ef4386b}trackLocation',
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.fields.{6c28d4fa-2e60-49e4-afa0-073da2721d12}configurationId',
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.fields.{f0a38adf-be75-47bb-808f-104043b69f31}configurationId',
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.relationships.{d192fa94-4c86-4398-ab5a-990d09a9023a}timesheetConfiguration.fields.{a536ef85-ccf1-48f4-b11c-427e6a158e02}hidePayrollOverrideForForeperson',
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.relationships.{d192fa94-4c86-4398-ab5a-990d09a9023a}timesheetConfiguration.fields.{5f32d849-70b5-4f63-ba50-cb639f610d53}customizeOverrideRate',
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.relationships.{d192fa94-4c86-4398-ab5a-990d09a9023a}timesheetConfiguration.fields.{f577ed41-d35c-4de7-b12e-aa5295009187}enableOverrideRateHourType',
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.relationships.{d192fa94-4c86-4398-ab5a-990d09a9023a}timesheetConfiguration.fields.{61a7d9b2-a1ee-4dec-96a7-0f445df48201}customizeEquipmentOverrideRate',
      'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{2e705ca2-38e4-42f6-9895-98bc75a3d59c}oracleProjectNumber'
    },
    filters: a!queryLogicalExpression(
      operator: "AND",
      ignoreFiltersWithEmptyValues: true,
      logicalExpressions: {
        a!queryLogicalExpression(
          operator: "OR",
          filters: {
            a!queryFilter(
              field: 'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{e9b80a47-a6e1-49c9-b7ce-5397d606a098}ulcsCrewNumber',
              operator: "in",
              value: {
                a!defaultValue(local!ulcsCrewNumbers, "0")
              }
            ),
            a!queryFilter(
              field: 'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{f108eaec-47ee-4785-88b4-a66c0a745096}productionUnitWoCrew.fields.{d551081f-1ce1-47ee-844a-04380f93ed10}ulcsCrewNumber',
              operator: "in",
              value: {
                a!defaultValue(local!ulcsCrewNumbers, "0")
              }
            )
          }
        )
      },
      filters: {
        a!queryFilter(
          field: 'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{dbbb585e-0d64-483d-a703-165e38b8a987}romeRefProductionUnitWoStatus.fields.{1c8e8135-c904-4b55-905e-29dc1445577b}corporateStatusId',
          operator: "=",
          value: cons!ATE_INT_CORPORATE_STATUS_INPROGRESS
        )
      }
    ),
    relatedRecordData: {
      a!relatedRecordData(
        relationship: 'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{f108eaec-47ee-4785-88b4-a66c0a745096}productionUnitWoCrew',
        limit: 100,
        filters: a!queryFilter(
          field: 'recordType!{fbe9bd23-2077-49ee-8325-54e50aaecd49}ROME Production Unit WO Crew.fields.{fdbb9587-d73f-4f79-af2b-97b5b451415b}isActive',
          value: true,
          operator: "="
        )
      ),
      a!relatedRecordData(
        relationship: 'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{855c5c2d-5946-4e9c-8c84-eda5fd484f54}vppmTaskOrder',
        limit: 1,
        filters: a!queryFilter(
          field: 'recordType!{c7f98593-f635-4263-adee-fdc72b23541a}VPPM Task Order.fields.{77eed247-7219-465f-9869-14db062ee2da}isActive',
          value: true,
          operator: "="
        )
      ),
      a!relatedRecordData(
        relationship: 'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.relationships.{d192fa94-4c86-4398-ab5a-990d09a9023a}timesheetConfiguration',
        limit: 1,
        filters: a!queryFilter(
          field: 'recordType!{b05a3d8d-9cc2-4189-8e62-bd21325d69d5}ATE Timesheet Configuration.fields.{1d43004c-3017-4b64-9069-c2fbd2f27d2e}isActive',
          operator: "=",
          value: true
        )
      )
    },
    pagingInfo: a!pagingInfo(
      startIndex: 1,
      batchSize: cons!ATE_INT_BATCH_SIZE_MAX_RECORD_BATCH_SIZE,
      sort: a!sortInfo(
        field: 'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{33425852-37b0-4187-a7cf-bc3d799ecd5c}createdOn',
        ascending: false()
      )
    )
  ).data,
  local!locationUniqueConfigIds: tointeger(
    a!queryRecordType(
      recordType: 'recordType!{2d75157d-1f5c-405c-9280-f5d8c74c48f5}ATE Location Configuration',
      fields: {
        'recordType!{2d75157d-1f5c-405c-9280-f5d8c74c48f5}ATE Location Configuration.fields.{78c1c246-0c0f-4bcf-b3e3-265609cdd72e}configurationId'
      },
      filters: {
        a!queryFilter(
          field: 'recordType!{2d75157d-1f5c-405c-9280-f5d8c74c48f5}ATE Location Configuration.fields.{78c1c246-0c0f-4bcf-b3e3-265609cdd72e}configurationId',
          operator: "in",
          value: a!defaultValue(
            tointeger(
              local!allCrewWo['recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.fields.{6c28d4fa-2e60-49e4-afa0-073da2721d12}configurationId']
            ),
            { 0 }
          )
        ),
        a!queryFilter(
          field: 'recordType!{2d75157d-1f5c-405c-9280-f5d8c74c48f5}ATE Location Configuration.fields.{d29ea862-7336-40d9-bcff-385f5c9ade89}isLocationUniqueToWorkorder',
          operator: "=",
          value: true
        )
      },
      pagingInfo: a!pagingInfo(
        startIndex: 1,
        batchSize: cons!ATE_INT_BATCH_SIZE_MAX_RECORD_BATCH_SIZE
      )
    ).data['recordType!{2d75157d-1f5c-405c-9280-f5d8c74c48f5}ATE Location Configuration.fields.{78c1c246-0c0f-4bcf-b3e3-265609cdd72e}configurationId']
  ),
  local!locationUniqueWoNumbers: if(
    a!isNullOrEmpty(local!locationUniqueConfigIds),
    {},
    touniformstring(
      index(
        local!allCrewWo['recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{dba57993-6687-4e94-adce-3841f30378ed}workOrderNumber'],
        wherecontains(
          local!locationUniqueConfigIds,
          tointeger(
            local!allCrewWo['recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.fields.{6c28d4fa-2e60-49e4-afa0-073da2721d12}configurationId']
          )
        ),
        {}
      )
    )
  ),
  local!allCustomFieldConfiguration: rule!ATE_QRY_getCustomFieldConfig(
    configurationId: union(
      tointeger(
        index(
          local!allCrewWo,
          'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.fields.{f0a38adf-be75-47bb-808f-104043b69f31}configurationId',
          {}
        )
      ),
      tointeger({})
    ),
    fetchTotalCount: false,
    filters: a!queryFilter(
      field: 'recordType!{c859c726-925b-479e-9d91-5a281e91de4f}ATE Custom Field Configuration.fields.{e1744731-ca2d-48f7-9165-3bbb945f828e}moduleId',
      operator: "in",
      value: {
        cons!ATE_INT_CONFIGURATION_MODULE_VEG_TIMESHEET,
        cons!ATE_INT_CONFIGURATION_MODULE_CONS_TIMESHEET
      }
    ),
    pagingInfo: a!pagingInfo(
      startIndex: 1,
      batchSize: cons!ATE_INT_BATCH_SIZE_MAX_RECORD_BATCH_SIZE
    )
  ).data,
  local!allTimesheetConfiguration: index(
    local!allCustomFieldConfiguration,
    wherecontains(
      {
        cons!ATE_INT_CONFIGURATION_MODULE_VEG_TIMESHEET,
        cons!ATE_INT_CONFIGURATION_MODULE_CONS_TIMESHEET
      },
      tointeger(
        index(
          local!allCustomFieldConfiguration,
          'recordType!{c859c726-925b-479e-9d91-5a281e91de4f}ATE Custom Field Configuration.fields.{e1744731-ca2d-48f7-9165-3bbb945f828e}moduleId',
          null
        )
      )
    ),
    null
  ),
  local!timesheetCustomFieldsConf,
  local!allDropdownChoices: rule!ATE_QRY_getCustomFieldDropdownChoice(
    pagingInfo: a!pagingInfo(
      startIndex: 1,
      batchSize: cons!ATE_INT_BATCH_SIZE_MAX_RECORD_BATCH_SIZE
    ),
    fetchTotalCount: false,
    filters: a!queryFilter(
      field: 'recordType!{5ab3767e-c805-4492-a08d-9b5c6afb5649}ATE Custom Field Dropdown Choice.fields.{e6dac35c-59e6-434f-bc1f-72d402f648d5}fieldConfigId',
      operator: "in",
      value: index(
        local!allTimesheetConfiguration,
        'recordType!{c859c726-925b-479e-9d91-5a281e91de4f}ATE Custom Field Configuration.fields.{1ba54d51-f6c4-4712-a39a-ccf7f987a181}fieldConfigId',
        null
      )
    ),
    
  ).data,
  local!timesheetDropDownChoices,
  local!allCrewCustomers: rule!ATE_QRY_getCustomer(
    filters: {
      a!queryFilter(
        field: 'recordType!{fc8104be-5d2c-4328-bd57-643577123348}ATE Customer.fields.{79900568-c9da-4e24-95cf-7c9451e34813}customerId',
        operator: "in",
        value: a!defaultValue(
          index(
            local!allCrewWo,
            'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{9de912bc-cb4a-4061-ac25-cb279443a748}contractList.fields.{66548d1e-7fca-4b67-994e-875197d87ee1}customerId',
            null
          ),
          {}
        )
      )
    }
  ).data,
  local!selectionMap: {
    entryType: cons!ATE_TXT_DAILY_WEEKLY_MTE_OFFLINE[1],
    crewTemplateId: null,
    crew: null,
    date: a!defaultValue(null, todate(today())),
    workOrderData: null
  },
  local!allWoEstimatedUnits: a!queryRecordType(
    recordType: 'recordType!{2460b5cc-ea95-45aa-9309-a2a649c3f3bd}ATE Work Order Estimated Unit',
    fields: {
      'recordType!{2460b5cc-ea95-45aa-9309-a2a649c3f3bd}ATE Work Order Estimated Unit.relationships.{b653ae68-bc59-4616-a875-7d51d111f4cf}serviceItemData.fields.{62990618-fac7-4ca7-87b3-751776cd51e9}description',
      'recordType!{2460b5cc-ea95-45aa-9309-a2a649c3f3bd}ATE Work Order Estimated Unit.relationships.{b653ae68-bc59-4616-a875-7d51d111f4cf}serviceItemData.fields.{48b0dabc-f28a-4e4e-90be-022287964eed}serviceItemNum',
      'recordType!{2460b5cc-ea95-45aa-9309-a2a649c3f3bd}ATE Work Order Estimated Unit.relationships.{60f28795-fb95-4949-8db3-cfb173d464bc}location.fields.{91e4030f-9721-453e-83ac-43e7cc409cdf}name',
      'recordType!{2460b5cc-ea95-45aa-9309-a2a649c3f3bd}ATE Work Order Estimated Unit.fields.{d59ca187-1f89-4b7a-86f0-d8ad9ca69e26}estimatedQuantity',
      'recordType!{2460b5cc-ea95-45aa-9309-a2a649c3f3bd}ATE Work Order Estimated Unit.fields.{c0153838-5767-41ec-8905-06bb92395c7b}workOrderNumber',
      'recordType!{2460b5cc-ea95-45aa-9309-a2a649c3f3bd}ATE Work Order Estimated Unit.fields.{d3e3f703-067e-476f-8fb1-adbacee51ffb}locationId',
      'recordType!{2460b5cc-ea95-45aa-9309-a2a649c3f3bd}ATE Work Order Estimated Unit.relationships.{60f28795-fb95-4949-8db3-cfb173d464bc}location.fields.{9ce288ac-39a4-42d1-8fbe-01ec5b97dcd8}concatIdName'
    },
    filters: {
      a!queryFilter(
        field: 'recordType!{2460b5cc-ea95-45aa-9309-a2a649c3f3bd}ATE Work Order Estimated Unit.fields.{c0153838-5767-41ec-8905-06bb92395c7b}workOrderNumber',
        operator: "in",
        value: a!defaultValue(
          touniformstring(
            index(
              local!allCrewWo,
              'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{dba57993-6687-4e94-adce-3841f30378ed}workOrderNumber',
              null
            )
          ),
          { "0" }
        )
      ),
      a!queryFilter(
        field: 'recordType!{2460b5cc-ea95-45aa-9309-a2a649c3f3bd}ATE Work Order Estimated Unit.fields.{272acf07-9078-455d-a7c8-3368caed1f2f}isActive',
        operator: "=",
        value: true
      )
    },
    pagingInfo: a!pagingInfo(
      startIndex: 1,
      batchSize: cons!ATE_INT_BATCH_SIZE_MAX_RECORD_BATCH_SIZE
    )
  ).data,
  local!allLWoLocations: rule!ATE_QRY_getWOLocations(
    fields: {
      'recordType!{03d47453-3632-4da1-8384-a861ec63cae1}ATE L WO Location.fields.{de7aaefd-655d-4b3f-b132-ab5a6b95cd1c}workOrderNumber',
      'recordType!{03d47453-3632-4da1-8384-a861ec63cae1}ATE L WO Location.relationships.{eea077f8-9005-47aa-aa9a-fb6aa2b256b7}location.fields.{8c177164-8bf1-4e5a-9f3c-6d65ad85a539}concatNameAddress',
      'recordType!{03d47453-3632-4da1-8384-a861ec63cae1}ATE L WO Location.relationships.{eea077f8-9005-47aa-aa9a-fb6aa2b256b7}location.fields.{b84015f5-1b00-4f7c-86b6-8775218a0ced}locationId',
      'recordType!{03d47453-3632-4da1-8384-a861ec63cae1}ATE L WO Location.relationships.{eea077f8-9005-47aa-aa9a-fb6aa2b256b7}location.fields.{9ce288ac-39a4-42d1-8fbe-01ec5b97dcd8}concatIdName',
      'recordType!{03d47453-3632-4da1-8384-a861ec63cae1}ATE L WO Location.relationships.{eea077f8-9005-47aa-aa9a-fb6aa2b256b7}location.fields.{91e4030f-9721-453e-83ac-43e7cc409cdf}name'
    },
    filters: {
      a!queryFilter(
        field: 'recordType!{03d47453-3632-4da1-8384-a861ec63cae1}ATE L WO Location.fields.{de7aaefd-655d-4b3f-b132-ab5a6b95cd1c}workOrderNumber',
        operator: "in",
        value: a!defaultValue(
          touniformstring(
            index(
              local!allCrewWo,
              'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{dba57993-6687-4e94-adce-3841f30378ed}workOrderNumber',
              null
            )
          ),
          { "0" }
        )
      ),
      a!queryFilter(
        field: 'recordType!{03d47453-3632-4da1-8384-a861ec63cae1}ATE L WO Location.fields.{2b32b4dd-c5ed-408d-bff7-b36577230dad}isActive',
        operator: "=",
        value: true
      )
    },
    pagingInfo: a!pagingInfo(
      startIndex: 1,
      batchSize: cons!ATE_INT_BATCH_SIZE_MAX_RECORD_BATCH_SIZE
    )
  ).data,
  local!activeMilestone: a!refreshVariable(
    value: 1,
    refreshOnReferencedVarChange: false,
    refreshAlways: false
  ),
  /*AS-1734*/
  local!woData: index(
    local!selectionMap,
    "workOrderData",
    null
  ),
  local!selectedCrewWoDetails,
  local!selectedCrewCustomerDetails: if(
    rule!ATE_checkIsNullOrEmptyArray(index(local!selectionMap, "crew", null)),
    null,
    index(
      local!allCrewCustomers,
      wherecontains(
        touniformstring(
          index(
            local!selectedCrewWoDetails,
            'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{9de912bc-cb4a-4061-ac25-cb279443a748}contractList.fields.{66548d1e-7fca-4b67-994e-875197d87ee1}customerId',
            null
          )
        ),
        touniformstring(
          index(
            local!allCrewCustomers,
            'recordType!{fc8104be-5d2c-4328-bd57-643577123348}ATE Customer.fields.{79900568-c9da-4e24-95cf-7c9451e34813}customerId',
            null
          )
        )
      ),
      null
    )
  ),
  local!selectedWOnumbers: index(
    index(local!selectionMap, "workOrderData", ""),
    "workOrderNumber",
    ""
  ),
  local!selectedProductionUnitWoDetails,
  local!allSelectedCrewTemplate: index(
    local!allCrewTemplates,
    wherecontains(
      tostring(index(local!selectionMap, "crew", {})),
      touniformstring(
        index(
          local!allCrewTemplates,
          'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.fields.{c9a61a95-0d27-45a2-a6ff-353f21a3631c}crew',
          null
        )
      )
    ),
    null
  ),
  local!selectedCrewTemplate: index(
    local!allSelectedCrewTemplate,
    wherecontains(
      tostring(
        index(local!selectionMap, "crewTemplateId", {})
      ),
      touniformstring(
        index(
          local!allSelectedCrewTemplate,
          'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.fields.{613eebb7-b28e-4805-b12c-42c7f5396694}id',
          null
        )
      )
    ),
    null
  ),
  local!allWOconfigHourType: rule!ATE_RULE_QRY_getLConfigurationHourTypes(
    fields: {
      'recordType!{0426e3e6-4546-41d3-8b1b-85aebf27b019}ATE L Configuration Hour Type.fields.{e555c2c1-b8bf-48d6-a38a-6ddd061553eb}hourTypeId',
      'recordType!{0426e3e6-4546-41d3-8b1b-85aebf27b019}ATE L Configuration Hour Type.fields.{32bbd2a9-113e-471e-9c11-d45398b827d5}configurationId'
    },
    filters: {
      a!queryFilter(
        field: 'recordType!{0426e3e6-4546-41d3-8b1b-85aebf27b019}ATE L Configuration Hour Type.fields.{32bbd2a9-113e-471e-9c11-d45398b827d5}configurationId',
        operator: "in",
        value: {
          tointeger(
            index(
              local!allCrewWo,
              'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.fields.{f0a38adf-be75-47bb-808f-104043b69f31}configurationId',
              {}
            )
          )
        }
      ),
      a!queryFilter(
        field: 'recordType!{0426e3e6-4546-41d3-8b1b-85aebf27b019}ATE L Configuration Hour Type.fields.{56b61454-0654-4846-b6c7-d55a910f07cb}isActive',
        operator: "=",
        value: true()
      )
    }
  ).data,
  local!allCrewConfigIds: reject(
    a!isNullOrEmpty(_),
    union(
      tointeger(
        index(
          local!allCrewWo,
          'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.fields.{f0a38adf-be75-47bb-808f-104043b69f31}configurationId',
          {}
        )
      ),
      tointeger({})
    )
  ),
  local!fusionProjectNoModulesData: rule!ATE_RULE_QRY_getLConfigurationModule(
    fields: {
      'recordType!{6d6374a4-d719-4bbe-862d-05c081b6cc38}ATE L Configuration Module.relationships.{297412c1-5111-4641-b49c-ef6b2afa09eb}module.fields.{0212541f-3b43-4719-b46e-95c0417a8bab}configurationModuleId'
    },
    filters: {
      a!queryFilter(
        field: 'recordType!{6d6374a4-d719-4bbe-862d-05c081b6cc38}ATE L Configuration Module.fields.{96a9b7da-ab2d-41d6-a0cb-97dac46435e0}configurationId',
        operator: "in",
        value: local!allCrewConfigIds
      ),
      a!queryFilter(
        field: 'recordType!{6d6374a4-d719-4bbe-862d-05c081b6cc38}ATE L Configuration Module.fields.{f41fe54e-95e1-4100-9059-63f88c5ef343}isActive',
        operator: "=",
        value: true
      ),
      a!queryFilter(
        field: 'recordType!{6d6374a4-d719-4bbe-862d-05c081b6cc38}ATE L Configuration Module.fields.{d70ad7b7-4bee-4294-9570-dd2ab1d34f54}rModuleId',
        operator: "=",
        value: cons!ATE_INT_ENV_CONFIGURATION_MODULE_FUSION_PROJECT_NUMBER
      )
    },
    fetchTotalCount: false,
    pagingInfo: a!pagingInfo(
      startIndex: 1,
      batchSize: cons!ATE_INT_BATCH_SIZE_MAX_RECORD_BATCH_SIZE
    )
  ).data,
  local!isForeperson: not(
    a!isUserMemberOfGroup(
      username: local!loggedInUser,
      groups: cons!ATE_GRP_PAYROLL_OVERRIDE_ACCESS
    )
  ),
  local!payrollModuleConfigIds: if(
    a!isNullOrEmpty(local!allCrewConfigIds),
    {},
    tointeger(
      index(
        rule!ATE_QRY_getConfigurationModules(
          fields: {
            'recordType!{6d6374a4-d719-4bbe-862d-05c081b6cc38}ATE L Configuration Module.fields.{96a9b7da-ab2d-41d6-a0cb-97dac46435e0}configurationId'
          },
          filters: {
            a!queryFilter(
              field: 'recordType!{6d6374a4-d719-4bbe-862d-05c081b6cc38}ATE L Configuration Module.fields.{96a9b7da-ab2d-41d6-a0cb-97dac46435e0}configurationId',
              operator: "in",
              value: local!allCrewConfigIds
            ),
            a!queryFilter(
              field: 'recordType!{6d6374a4-d719-4bbe-862d-05c081b6cc38}ATE L Configuration Module.fields.{d70ad7b7-4bee-4294-9570-dd2ab1d34f54}rModuleId',
              operator: "=",
              value: cons!ATE_INT_CONFIGURATION_MODULE_PAYROLL
            ),
            a!queryFilter(
              field: 'recordType!{6d6374a4-d719-4bbe-862d-05c081b6cc38}ATE L Configuration Module.fields.{f41fe54e-95e1-4100-9059-63f88c5ef343}isActive',
              operator: "=",
              value: true
            )
          },
          getActiveRecordsOnly: true
        ).data,
        'recordType!{6d6374a4-d719-4bbe-862d-05c081b6cc38}ATE L Configuration Module.fields.{96a9b7da-ab2d-41d6-a0cb-97dac46435e0}configurationId',
        {}
      )
    )
  ),
  local!payrollOverrideOptions: if(
    a!isNullOrEmpty(local!payrollModuleConfigIds),
    {},
    rule!ATE_QRY_getPayrollOverrideConfiguration(
      fields: {
        'recordType!{bc1923f3-1a2f-4064-a5f6-f7c467defc4c}ATE Configuration Payroll Override.fields.{635d99c3-e193-409c-b615-fdadf9524d1b}payrollConfigOverrideId',
        'recordType!{bc1923f3-1a2f-4064-a5f6-f7c467defc4c}ATE Configuration Payroll Override.fields.{4a771379-43bb-4979-b01d-b735624064e5}configurationId',
        'recordType!{bc1923f3-1a2f-4064-a5f6-f7c467defc4c}ATE Configuration Payroll Override.fields.{90d8c717-1608-42da-a272-4cf3cf5c9da1}jobCategoryName',
        'recordType!{bc1923f3-1a2f-4064-a5f6-f7c467defc4c}ATE Configuration Payroll Override.fields.{52b5cb44-4e44-46d9-945d-d5c729323443}rate'
      },
      filters: {
        a!queryFilter(
          field: 'recordType!{bc1923f3-1a2f-4064-a5f6-f7c467defc4c}ATE Configuration Payroll Override.fields.{4a771379-43bb-4979-b01d-b735624064e5}configurationId',
          operator: "in",
          value: local!payrollModuleConfigIds
        ),
        a!queryFilter(
          field: 'recordType!{bc1923f3-1a2f-4064-a5f6-f7c467defc4c}ATE Configuration Payroll Override.fields.{8221ee6f-1b25-4e81-a1f3-f0c5b9c35745}isAvailable',
          operator: "=",
          value: true
        ),
        a!queryFilter(
          field: 'recordType!{bc1923f3-1a2f-4064-a5f6-f7c467defc4c}ATE Configuration Payroll Override.fields.{6ecbbe82-81fb-463b-9046-715a8dd968ba}isActive',
          operator: "=",
          value: true
        )
      }
    ).data
  ),
  local!equipmentModuleConfigIds: if(
    a!isNullOrEmpty(local!allCrewConfigIds),
    {},
    tointeger(
      index(
        rule!ATE_QRY_getConfigurationModules(
          fields: {
            'recordType!{6d6374a4-d719-4bbe-862d-05c081b6cc38}ATE L Configuration Module.fields.{96a9b7da-ab2d-41d6-a0cb-97dac46435e0}configurationId'
          },
          filters: {
            a!queryFilter(
              field: 'recordType!{6d6374a4-d719-4bbe-862d-05c081b6cc38}ATE L Configuration Module.fields.{96a9b7da-ab2d-41d6-a0cb-97dac46435e0}configurationId',
              operator: "in",
              value: local!allCrewConfigIds
            ),
            a!queryFilter(
              field: 'recordType!{6d6374a4-d719-4bbe-862d-05c081b6cc38}ATE L Configuration Module.fields.{d70ad7b7-4bee-4294-9570-dd2ab1d34f54}rModuleId',
              operator: "=",
              value: cons!ATE_INT_ENV_CONFIGURATION_MODULE_EQUIPMENT_PAYROLL
            ),
            a!queryFilter(
              field: 'recordType!{6d6374a4-d719-4bbe-862d-05c081b6cc38}ATE L Configuration Module.fields.{f41fe54e-95e1-4100-9059-63f88c5ef343}isActive',
              operator: "=",
              value: true
            )
          },
          getActiveRecordsOnly: true
        ).data,
        'recordType!{6d6374a4-d719-4bbe-862d-05c081b6cc38}ATE L Configuration Module.fields.{96a9b7da-ab2d-41d6-a0cb-97dac46435e0}configurationId',
        {}
      )
    )
  ),
  local!equipmentOverrideOptions: if(
    a!isNullOrEmpty(local!equipmentModuleConfigIds),
    {},
    rule!ATE_QRY_getEquipmentPayrollOverrideConfiguration(
      additionalFilters: {
        a!queryFilter(
          field: 'recordType!{c1f7c17b-a1b1-4323-8ee2-3d060df03fbc}ATE Config Equipment Payroll Override.fields.{9db66801-2cbe-470c-b810-82e477fab310}configurationId',
          operator: "in",
          value: local!equipmentModuleConfigIds
        ),
        a!queryFilter(
          field: 'recordType!{c1f7c17b-a1b1-4323-8ee2-3d060df03fbc}ATE Config Equipment Payroll Override.fields.{1809c545-3c03-4a7a-9a75-49f383608918}isAvailable',
          operator: "=",
          value: true()
        )
      },
      isFetchAllFields: true()
    ).data
  ),
  local!payrollOverrideByConfig: rule!ATE_RULE_buildOfflinePayrollOverrideByConfig(
    crewWo: local!allCrewWo,
    configurationIds: local!allCrewConfigIds,
    payrollModuleConfigIds: local!payrollModuleConfigIds,
    payrollOverrideOptions: local!payrollOverrideOptions,
    isForeperson: local!isForeperson,
    equipmentModuleConfigIds: local!equipmentModuleConfigIds,
    equipmentOverrideOptions: local!equipmentOverrideOptions
  ),
  local!allSelectedWOconfigHourType,
  local!laborCrewTemplateData: a!flatten(
    index(
      local!selectedCrewTemplate,
      'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{ed8405a0-530c-4a91-aa6c-e890db20a06b}laborCrewTemplate',
      {}
    )
  ),
  local!equipmentCrewTemplateData: a!flatten(
    index(
      local!selectedCrewTemplate,
      'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.relationships.{264b1308-dfb4-4db0-b8f2-270cba088a31}equipmentCrewTemplate',
      {}
    )
  ),
  local!allRefHourTypeData: rule!ROME_QRY_getRefHourType(
    fetchAll: true(),
    fields: {
      'recordType!{0ba490b0-1715-4af0-a10a-1c8f99d9f481}ROME Ref Hour Type.fields.{f343f388-81a2-4036-9c0d-c8e692e65cc3}hourTypeId',
      'recordType!{0ba490b0-1715-4af0-a10a-1c8f99d9f481}ROME Ref Hour Type.fields.{b27c18e1-9c0c-4709-8944-9e79b07bb027}name'
    },
    
  ).data,
  local!crewDefaultLaborTime: if(
    not(
      rule!ATE_checkIsNullOrEmptyArray(local!laborCrewTemplateData)
    ),
    a!flatten(
      a!forEach(
        local!laborCrewTemplateData,
        a!map(
          workOrderNumber: null,
          employeeId: fv!item['recordType!{b29742d7-7644-4774-a125-5556cd9e0086}ATE Labor Crew Template.relationships.{4b28f158-8819-465b-b32c-0fbc93d18a47}syncedEmployeeData.fields.{c0525c87-fc48-4239-a357-c00fc48fe850}employeeId'],
          employeeName: fv!item['recordType!{b29742d7-7644-4774-a125-5556cd9e0086}ATE Labor Crew Template.relationships.{4b28f158-8819-465b-b32c-0fbc93d18a47}syncedEmployeeData.fields.{9c68dd28-51b5-4f24-b275-99b80680bb13}fullName'],
          jobDescription: fv!item['recordType!{b29742d7-7644-4774-a125-5556cd9e0086}ATE Labor Crew Template.relationships.{4b28f158-8819-465b-b32c-0fbc93d18a47}syncedEmployeeData.fields.{ac02686f-f95c-4eea-9a7e-e38d825a3ce8}jobDescription'],
          payrollConfigOverrideId: null,
          hourTypes: {
            a!forEach(
              items: cons!ATE_CONS_INT_MTE_OFFLINE_HOURTYPES[{ 1, 2 }],
              expression: a!map(
                hourTypeId: fv!item,
                hours: null,
                payrollOverrideRate: null
              )
            )
          }
        )
      )
    ),
    null
  ),
  local!crewDefaultequipmenTime: if(
    not(
      rule!ATE_checkIsNullOrEmptyArray(local!equipmentCrewTemplateData)
    ),
    a!flatten(
      a!forEach(
        local!equipmentCrewTemplateData,
        a!map(
          workOrderNumber: null,
          equipmentId: fv!item['recordType!{39493776-6005-4f99-adc0-4690c2177ef4}ATE Equipment Crew Template.fields.{22247106-0086-4043-a0b9-224ba13c483c}equipmentId'],
          equipmentName: fv!item['recordType!{39493776-6005-4f99-adc0-4690c2177ef4}ATE Equipment Crew Template.relationships.{0c56a132-3545-400e-892a-9e2bdd31cd2f}syncedRefEquipment.fields.{96b6ac3b-eed6-4175-bebd-cf2d1eee4d4d}idAndDescription'],
          hours: null,
          payrollConfigOverrideId: null,
          payrollOverrideRate: null
        )
      )
    ),
    null
  ),
  local!woCrewData,
  local!target: a!defaultValue(
    index(
      index(local!selectedCrewTemplate, 1, {}),
      'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.fields.{c98e6171-f511-4002-a536-35dce2d2dfd2}targetHours',
      {}
    ),
    10
  ),
  local!today: today(),
  local!selectedCount: length(
    a!defaultValue(local!selectedWOnumbers, "")
  ),
  local!evenSplitHours: touniformstring(
    if(
      local!selectedCount = 0,
      0,
      tointeger(local!target / local!selectedCount)
    )
  ),
  local!woDataWithUnits: if(
    a!isNotNullOrEmpty(local!woData),
    remove(
      local!woData,
      wherecontains(
        tostring(null),
        touniformstring(index(local!woData, "details", null))
      )
    ),
    {}
  ),
  local!locationWoNumbers: index(
    index(
      local!woDataWithUnits,
      wherecontains(
        tointeger(null),
        tointeger(
          index(
            index(local!woDataWithUnits, "details", null),
            "locationId",
            null
          )
        )
      ),
      {}
    ),
    "workOrderNumber",
    {}
  ),
  local!missingLocationWos: if(
    a!isNotNullOrEmpty(local!locationWoNumbers),
    remove(
      local!locationWoNumbers,
      wherecontains(
        touniformstring(
          index(
            index(
              local!selectedProductionUnitWoDetails,
              wherecontains(
                toboolean({ null, false }),
                toboolean(
                  index(
                    local!selectedProductionUnitWoDetails,
                    'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.relationships.{187d9785-3bf6-45aa-a289-5cb396e4e82f}unitConfiguration.fields.{5f412f47-933a-4938-9123-58578ef4386b}trackLocation',
                    null
                  )
                )
              ),
              null
            ),
            'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{dba57993-6687-4e94-adce-3841f30378ed}workOrderNumber',
            null
          )
        ),
        touniformstring(local!locationWoNumbers)
      )
    ),
    null
  ),
  local!missingFieldsText: joinarray(
    reject(
      a!isNullOrEmpty,
      { local!missingLocationWos }
    ),
    ", "
  ),
  local!missingFields: a!match(
    value: null,
    whenTrue: rule!ATE_checkIsNullOrEmptyArray(local!woData),
    then: "No Work Order details available",
    whenTrue: rule!ATE_checkIsNullOrEmptyArray(local!missingFieldsText),
    then: null,
    default: local!missingFieldsText
  ),
  /*The commented logic doesn't work for weekly timesheet - Commented to reduce the performance as it has many foreach*/
  local!validateHours: false,
  /*or(*/
  /*a!forEach(*/
  /*items: local!woCrewData,*/
  /*expression: or(*/
  /* Labor Hour Types */
  /*or(*/
  /*a!forEach(*/
  /*items: fv!item.labors,*/
  /*expression: any(*/
  /*a!isNotNullOrEmpty(_),*/
  /*a!forEach(*/
  /*items: fv!item.hourTypes,*/
  /*expression: rule!ATE_UTIL_validateHour(*/
  /*hourTypeId: fv!item.hourTypeId,*/
  /*hours: fv!item.hours*/
  /*)*/
  /*)*/
  /*)*/
  /*)*/
  /*),*/
  /* Equipment */
  /*any(*/
  /*a!isNotNullOrEmpty(_),*/
  /*a!forEach(*/
  /*items: fv!item.equipments,*/
  /*expression: rule!ATE_UTIL_validateHour(hourTypeId: null, hours: fv!item.hours)*/
  /*)*/
  /*)*/
  /*)*/
  /*)*/
  /*),*/
  local!weekStart: todate(local!selectionMap.date) - weekday(local!selectionMap.date) + 1,
  local!weekDays: a!forEach(
    items: enumerate(7),
    expression: local!weekStart + fv!item
  ),
  local!weekCrewData,
  local!isWeekly: local!selectionMap.entryType = cons!ATE_TXT_DAILY_WEEKLY_MTE_OFFLINE[2],
  local!selectedDay: if(
    contains(
      touniformstring(local!weekDays),
      tostring(todate(today()))
    ),
    weekday(today()),2),
  local!currentWoCrewData: rule!ATE_UTIL_GetCurrentWoCrewData(
    isWeekly: local!isWeekly,
    weekCrewData: local!weekCrewData,
    selectedDay: local!selectedDay,
    dailyWoCrewData: local!woCrewData
  ),
  local!dayTotalPg3: rule!DCL_RULE_safeSum(
    if(
      local!selectionMap.entryType = cons!ATE_TXT_DAILY_WEEKLY_MTE_OFFLINE[2],
      {
        index(
          index(
            index(
              local!weekCrewData[local!selectedDay].woCrewData,
              "labors",
              {}
            ),
            "hourTypes",
            {}
          ),
          "hours",
          {}
        ),
        /*index(*/
        /*index(*/
        /*local!weekCrewData[local!selectedDay].woCrewData,*/
        /*"equipments",*/
        /*{}*/
        /*),*/
        /*"hours",*/
        /*{}*/
        /*)*/
        
      },
      {
        index(
          index(
            index(local!currentWoCrewData, "labors", {}),
            "hourTypes",
            {}
          ),
          "hours",
          {}
        ),
        /*index(*/
        /*index(*/
        /*local!currentWoCrewData,*/
        /*"equipments",*/
        /*{}*/
        /*),*/
        /*"hours",*/
        /*{}*/
        /*)*/
        
      }
    )
  ),
  local!weekTotalPg3: rule!DCL_RULE_safeSum(
    if(
      local!selectionMap.entryType = cons!ATE_TXT_DAILY_WEEKLY_MTE_OFFLINE[2],
      append(
        /* Labor Hours */
        a!flatten(
          index(
            index(
              index(
                index(local!weekCrewData, "woCrewData", {}),
                "labors",
                {}
              ),
              "hourTypes",
              {}
            ),
            "hours",
            {}
          )
        ),
        
      ),
      /* Daily */
      append(
        index(
          index(
            index(local!currentWoCrewData, "labors", {}),
            "hourTypes",
            {}
          ),
          "hours",
          {}
        ),
        /*index(*/
        /*index(*/
        /*local!currentWoCrewData,*/
        /*"equipments",*/
        /*{}*/
        /*),*/
        /*"hours",*/
        /*{}*/
        /*)*/
        
      )
    )
  ),
  local!selectionWeekMap,
  local!userFavWoList: rule!ATE_QRY_getLoggedInUserFavMarkedWOLIst(loggedInUser: local!loggedInUser),
  local!woFavourites: index(
    local!userFavWoList,
    'recordType!{1a88eda1-fe0d-410d-91f7-00881e69fd3d}ATE Favourite WO List.fields.{217c537b-b2fb-4e52-a813-abc5de5b149b}workOrderNumber',
    null
  ),
  local!timesheetCustomFieldValue,
  /*AS-1734*/
  a!formLayout(
    contents: {
      a!sideBySideLayout(
        items: {
          a!sideBySideItem(item: {}),
          a!sideBySideItem(
            item: a!stampField(
              text: if(local!activeMilestone > 1, null, "1"),
              icon: if(local!activeMilestone > 1, "check", null),
              align: "CENTER",
              size: "TINY",
              backgroundColor: if(
                local!activeMilestone >= 1,
                cons!ROME_TEXT_HEX_ORANGE,
                "SECONDARY"
              )
            )
          ),
          a!sideBySideItem(
            item: a!stampField(
              text: if(local!activeMilestone > 2, null, "2"),
              icon: if(local!activeMilestone > 2, "check", null),
              align: "CENTER",
              size: "TINY",
              backgroundColor: if(
                local!activeMilestone >= 2,
                cons!ROME_TEXT_HEX_ORANGE,
                "SECONDARY"
              )
            )
          ),
          a!sideBySideItem(
            item: a!stampField(
              text: if(local!activeMilestone > 3, null, "3"),
              icon: if(local!activeMilestone > 3, "check", null),
              align: "CENTER",
              size: "TINY",
              backgroundColor: if(
                local!activeMilestone >= 3,
                cons!ROME_TEXT_HEX_ORANGE,
                "SECONDARY"
              )
            )
          ),
          a!sideBySideItem(
            item: a!stampField(
              text: if(local!activeMilestone > 4, null, "4"),
              icon: if(local!activeMilestone > 4, "check", null),
              align: "CENTER",
              size: "TINY",
              backgroundColor: if(
                local!activeMilestone >= 4,
                cons!ROME_TEXT_HEX_ORANGE,
                "SECONDARY"
              )
            )
          ),
          a!sideBySideItem(item: {})
        },
        marginBelow: "MORE",
        spacing: "DENSE"
      ),
      choose(
        local!activeMilestone,
        rule!ATE_SEC_timeEntryTabForMteOfflineAppPage1(
          brandingMap: local!brandingMap,
          selectionMap: local!selectionMap,
          crewTemplates: local!allCrewTemplates
        ),
        rule!ATE_SCT_workOrderSelectionMTEOfflinePage2(
          productionUnitWO: local!selectedCrewWoDetails,
          contractList: local!selectedCrewCustomerDetails,
          finalMap: local!selectionMap,
          selectedWoNumbers: local!selectedWOnumbers,
          brandingMap: local!brandingMap,
          woFavourites: local!woFavourites,
          fusionPrNoModuleData: local!fusionProjectNoModulesData
        ),
        rule!ATE_SCT_mteOfflineAppPage3(
          step: local!activeMilestone,
          dayTotal: local!dayTotalPg3,
          target: local!target,
          crewDisplayName: index(
            local!selectedCrewTemplate,
            'recordType!{d6330344-44a8-4467-a866-608dbcad82a4}ATE Crew Template.fields.{31d19529-415f-463c-9721-d92f5baad441}name',
            {}
          ),
          woCrewData: local!currentWoCrewData,
          selectedWOIds: local!selectedWOnumbers,
          evenSplitHours: local!evenSplitHours,
          laborCrewTemplateData: local!laborCrewTemplateData,
          selectedCount: local!selectedCount,
          equipmentCrewTemplateData: local!equipmentCrewTemplateData,
          today: local!today,
          allRefHourTypeData: local!allRefHourTypeData,
          selectedWoDetails: local!selectedProductionUnitWoDetails,
          brandingMap: local!brandingMap,
          allSelectedWoConfigHourType: local!allSelectedWOconfigHourType,
          entryMode: local!selectionMap.entryType,
          weekCrewData: local!weekCrewData,
          selectedDay: local!selectedDay,
          weekEndingDate: todate(local!selectionMap.date),
          timesheetCustomFieldConf: local!timesheetCustomFieldsConf,
          timesheetCustomFieldValue: local!timesheetCustomFieldValue,
          timesheetDropDownChoices: local!timesheetDropDownChoices,
          locationUniqueWoNumbers: local!locationUniqueWoNumbers,
          payrollOverrideByConfig: local!payrollOverrideByConfig,
          fusionPrNoModuleData: local!fusionProjectNoModulesData
        ),
        /*AS-1734*/
        rule!ATE_SCT_reviewAndSubmitMTEOfflinePage4(
          step: local!activeMilestone,
          brandingMap: local!brandingMap,
          finalMap: if(
            local!selectionMap.entryType = cons!ATE_TXT_DAILY_WEEKLY_MTE_OFFLINE[2],
            local!selectionWeekMap,
            local!selectionMap
          ),
          missingFields: local!missingFields,
          dayTotal: local!weekTotalPg3,
          locations: local!allLWoLocations,
          crewWO: local!selectedProductionUnitWoDetails,
          customers: local!selectedCrewCustomerDetails,
          fusionPrNoModuleData: local!fusionProjectNoModulesData
        )/*AS-1734*/
        
      ),
      a!sideBySideLayout(
        stackWhen: "NEVER",
        items: {
          a!sideBySideItem(
            item: a!richTextDisplayField(
              value: {
                a!richTextItem(
                  text: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{c6177738-ab61-437b-b992-736ebaed83c7}Please check hour validations on',
                  color: "NEGATIVE",
                  style: "STRONG"
                ),
                a!richTextItem(text: " "),
                a!richTextItem(
                  text: 'translation!{5fa41cdb-bb96-404f-bee1-63b5d5dd00f7}ATE Translations.{315c34a0-40c3-4847-af39-ffbeb7621cc9}People tab..',
                  style: "STRONG",
                  showWhen: a!isNotNullOrEmpty(local!validateHours),
                  link: a!dynamicLink(
                    saveInto: {
                      a!save(
                        local!woCrewData,
                        a!forEach(
                          items: local!woCrewData,
                          expression: a!update(
                            data: fv!item,
                            index: "selectedMenu",
                            value: cons!ATE_STOP_CARD_LABELS_UNDER_UNITS_OFFLINE_PAGE3[1]
                          )
                        )
                      ),
                      a!save(
                        local!activeMilestone,
                        local!activeMilestone - 1
                      )
                    }
                  ),
                  size: "SMALL",
                  color: cons!ROME_TEXT_HEX_ORANGE,
                  linkStyle: "INLINE"
                )
              },
              marginAbove: "MORE",
              align: "LEFT"
            ),
            width: "MINIMIZE"
          ),
          a!sideBySideItem(
            item: a!textField(
              value: " ",
              validations: if(local!validateHours, " ", {}),
              readOnly: true(),
              marginAbove: "NONE",
              marginBelow: "NONE",
              align: "LEFT"
            ),
            width: "AUTO"
          ),
          
        },
        showWhen: and(
          local!activeMilestone = 4,
          local!validateHours
        )
      )
    },
    buttons: {
      a!buttonLayout(
        primaryButtons: {
          a!buttonWidget(
            label: "Continue To WorkOrder",
            value: cons!ATE_TEXT_BUTTON_LABEL_NEXT,
            saveInto: {
              a!save(
                local!activeMilestone,
                local!activeMilestone + 1
              ),
              a!save(
                local!selectedCrewWoDetails,
                if(
                  rule!ATE_checkIsNullOrEmptyArray(index(local!selectionMap, "crew", null)),
                  null,
                  index(
                    local!allCrewWo,
                    wherecontains(
                      touniformstring(index(local!selectionMap, "crew", null)),
                      touniformstring(
                        index(
                          local!allCrewWo,
                          'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{e9b80a47-a6e1-49c9-b7ce-5397d606a098}ulcsCrewNumber',
                          null
                        )
                      )
                    ),
                    null
                  )
                )
              ),
              a!save(local!allSelectedWOconfigHourType, null),
              a!save(
                local!selectedCrewWoDetails,
                rule!ATE_RULE_sortWOListBasedOnMTEOfflineSelectedWo(
                  productionUnitWo: local!selectedCrewWoDetails,
                  selectedWO: local!selectedWOnumbers,
                  woFavourites: local!woFavourites
                )
              ),
              
            },
            showWhen: local!activeMilestone = 1,
            validate: true(),
            disabled: any(
              a!isNullOrEmpty(_),
              {
                index(
                  local!selectionMap,
                  {
                    "entryType",
                    "crewTemplateId",
                    "crew",
                    "date"
                  },
                  {}
                )
              }
            ),
            submit: false(),
            color: cons!ROME_TEXT_HEX_ORANGE,
            style: "SOLID"
          ),
          a!buttonWidget(
            label: cons!ATE_TXT_BUTTON_LABEL_CONTINUE_TO_ENTRY,
            value: cons!ATE_TXT_BUTTON_LABEL_CONTINUE_TO_ENTRY,
            saveInto: {
              a!save(
                local!activeMilestone,
                local!activeMilestone + 1
              ),
              a!save(
                local!woCrewData,
                a!forEach(
                  local!selectedWOnumbers,
                  a!localVariables(
                    local!wo: fv!item,
                    local!woEstimatedUnits: index(
                      local!allWoEstimatedUnits,
                      wherecontains(
                        tostring(fv!item),
                        touniformstring(
                          local!allWoEstimatedUnits['recordType!{2460b5cc-ea95-45aa-9309-a2a649c3f3bd}ATE Work Order Estimated Unit.fields.{c0153838-5767-41ec-8905-06bb92395c7b}workOrderNumber']
                        )
                      ),
                      null
                    ),
                    a!map(
                      workOrderNumber: local!wo,
                      fusionProjectNo: index(
                        index(
                          local!selectedCrewWoDetails,
                          wherecontains(
                            local!wo,
                            local!selectedCrewWoDetails['recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{dba57993-6687-4e94-adce-3841f30378ed}workOrderNumber']
                          ),
                          null
                        ),
                        'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{2e705ca2-38e4-42f6-9895-98bc75a3d59c}oracleProjectNumber',
                        null
                      ),
                      labors: if(
                        a!isNullOrEmpty(local!crewDefaultLaborTime),
                        {},
                        a!update(
                          local!crewDefaultLaborTime,
                          { "workOrderNumber" },
                          { local!wo }
                        )
                      ),
                      equipments: if(
                        a!isNullOrEmpty(local!crewDefaultequipmenTime),
                        {},
                        a!update(
                          local!crewDefaultequipmenTime,
                          { "workOrderNumber" },
                          { local!wo }
                        )
                      ),
                      units: if(
                        a!isNullOrEmpty(local!woEstimatedUnits),
                        {},
                        a!forEach(
                          local!woEstimatedUnits,
                          a!map(
                            estimatedUnitId: fv!item['recordType!{2460b5cc-ea95-45aa-9309-a2a649c3f3bd}ATE Work Order Estimated Unit.fields.{eedfa163-74f2-47ec-afda-a2048cc39dc5}estimatedUnitId'],
                            serviceItemId: fv!item['recordType!{2460b5cc-ea95-45aa-9309-a2a649c3f3bd}ATE Work Order Estimated Unit.relationships.{b653ae68-bc59-4616-a875-7d51d111f4cf}serviceItemData.fields.{5601247c-d439-4320-a2d5-512327fb8cd2}serviceItemId'],
                            locationId: fv!item['recordType!{2460b5cc-ea95-45aa-9309-a2a649c3f3bd}ATE Work Order Estimated Unit.fields.{d3e3f703-067e-476f-8fb1-adbacee51ffb}locationId'],
                            quantity: null
                          )
                        )
                      ),
                      woEstimatedUnits: local!woEstimatedUnits,
                      locations: index(
                        index(
                          local!allLWoLocations,
                          wherecontains(
                            tostring(fv!item),
                            touniformstring(
                              local!allLWoLocations['recordType!{03d47453-3632-4da1-8384-a861ec63cae1}ATE L WO Location.fields.{de7aaefd-655d-4b3f-b132-ab5a6b95cd1c}workOrderNumber']
                            )
                          ),
                          null
                        ),
                        'recordType!{03d47453-3632-4da1-8384-a861ec63cae1}ATE L WO Location.relationships.{eea077f8-9005-47aa-aa9a-fb6aa2b256b7}location',
                        null
                      ),
                      selectedMenu: null,
                      crewVal: null,
                      selectedHourTypeId: null,
                      timesheetComments: "",
                      unitsComments: "",
                      photoDocId: null
                    )
                  )
                )
              ),
              a!save(
                local!woCrewData,
                rule!ATE_mergeWoCrewData(
                  woCrewData: local!woCrewData,
                  selectionMap: local!selectionMap
                )
              ),
              a!save(
                local!selectedProductionUnitWoDetails,
                if(
                  rule!ATE_checkIsNullOrEmptyArray(local!selectedWOnumbers),
                  {},
                  index(
                    local!selectedCrewWoDetails,
                    wherecontains(
                      touniformstring(local!selectedWOnumbers),
                      touniformstring(
                        index(
                          local!selectedCrewWoDetails,
                          'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{dba57993-6687-4e94-adce-3841f30378ed}workOrderNumber',
                          null
                        )
                      )
                    ),
                    null
                  )
                )
              ),
              a!save(
                local!timesheetCustomFieldsConf,
                index(
                  local!allTimesheetConfiguration,
                  wherecontains(
                    tointeger(
                      index(
                        index(
                          local!selectedProductionUnitWoDetails,
                          wherecontains(
                            touniformstring(index(local!selectedWOnumbers, 1, null)),
                            touniformstring(
                              index(
                                local!selectedProductionUnitWoDetails,
                                'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{dba57993-6687-4e94-adce-3841f30378ed}workOrderNumber',
                                null
                              )
                            )
                          ),
                          null
                        ),
                        'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.fields.{f0a38adf-be75-47bb-808f-104043b69f31}configurationId',
                        null
                      )
                    ),
                    tointeger(
                      index(
                        local!allTimesheetConfiguration,
                        'recordType!{c859c726-925b-479e-9d91-5a281e91de4f}ATE Custom Field Configuration.fields.{61d58e5e-d409-4f63-8c04-af04b5e978bd}configurationId',
                        null
                      )
                    )
                  ),
                  null
                )
              ),
              a!save(
                local!timesheetDropDownChoices,
                rule!ATE_RULE_getUdfDropdownChoicesForMTEOffline(
                  customFieldConfig: local!timesheetCustomFieldsConf,
                  dropdownChoices: local!allDropdownChoices
                )
              ),
              a!save(
                local!timesheetCustomFieldValue,
                if(
                  tointeger(
                    index(
                      local!timesheetCustomFieldsConf,
                      'recordType!{c859c726-925b-479e-9d91-5a281e91de4f}ATE Custom Field Configuration.fields.{1ba54d51-f6c4-4712-a39a-ccf7f987a181}fieldConfigId',
                      null
                    )
                  ) = tointeger(
                    index(
                      local!timesheetCustomFieldValue,
                      "fieldConfigId",
                      null
                    )
                  ),
                  local!timesheetCustomFieldValue,
                  null
                )
              ),
              if(
                local!selectionMap.entryType = cons!ATE_TXT_DAILY_WEEKLY_MTE_OFFLINE[2],
                {
                  a!save(
                    local!selectionWeekMap,
                    a!forEach(
                      items: local!selectionWeekMap,
                      expression: a!localVariables(
                        local!existingWOs: index(
                          fv!item.workOrderData,
                          wherecontains(
                            touniformstring(local!selectedWOnumbers),
                            touniformstring(fv!item.workOrderData.workOrderNumber)
                          ),
                          null
                        ),
                        local!existingWONumber: index(
                          local!existingWOs,
                          "workOrderNumber",
                          null
                        ),
                        local!newWOs: remove(
                          local!selectedWOnumbers,
                          wherecontains(
                            touniformstring(local!existingWONumber),
                            touniformstring(local!selectedWOnumbers)
                          )
                        ),
                        a!map(
                          entryType: fv!item.entryType,
                          crewTemplateId: fv!item.crewTemplateId,
                          crew: fv!item.crew,
                          date: fv!item.date,
                          workOrderData: a!flatten(
                            {
                              local!existingWOs,
                              index(
                                local!woCrewData,
                                wherecontains(
                                  touniformstring(local!newWOs),
                                  touniformstring(
                                    index(
                                      local!woCrewData,
                                      "workOrderNumber",
                                      null
                                    )
                                  )
                                ),
                                null
                              )
                            }
                          )
                        )
                      )
                    )
                  ),
                  a!save(
                    local!weekCrewData,
                    if(
                      a!isNullOrEmpty(local!selectionWeekMap),
                      a!forEach(
                        items: local!weekDays,
                        expression: a!localVariables(
                          local!dayDate: fv!item,
                          a!map(
                            dayName: text(local!dayDate, "DDDD"),
                            date: local!dayDate,
                            woCrewData: a!forEach(
                              items: local!woCrewData,
                              expression: a!localVariables(
                                local!wo: fv!item,
                                a!map(
                                  workOrderNumber: local!wo.workOrderNumber,
                                  fusionProjectNo: index(
                                    index(
                                      local!selectedCrewWoDetails,
                                      wherecontains(
                                        local!wo.workOrderNumber,
                                        local!selectedCrewWoDetails['recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{dba57993-6687-4e94-adce-3841f30378ed}workOrderNumber']
                                      ),
                                      null
                                    ),
                                    'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.fields.{2e705ca2-38e4-42f6-9895-98bc75a3d59c}oracleProjectNumber',
                                    null
                                  ),
                                  labors: local!wo.labors,
                                  equipments: local!wo.equipments,
                                  units: local!wo.units,
                                  woEstimatedUnits: local!wo.woEstimatedUnits,
                                  locations: local!wo.locations,
                                  selectedMenu: local!wo.selectedMenu,
                                  crewVal: local!wo.crewVal,
                                  selectedHourTypeId: null,
                                  workAddress: local!wo.workAddress,
                                  timesheetComments: local!wo.timesheetComments,
                                  unitsComments: local!wo.unitsComments,
                                  photoDocId: local!wo.photoDocId
                                )
                              )
                            ),
                            totalHours: 0,
                            status: "EMPTY"
                          )
                        )
                      ),
                      a!forEach(
                        items: enumerate(length(local!selectionWeekMap)),
                        expression: a!localVariables(
                          local!dayIndex: fv!item + 1,
                          a!map(
                            dayName: text(
                              local!selectionWeekMap[local!dayIndex].date,
                              "dddd"
                            ),
                            date: local!selectionWeekMap[local!dayIndex].date,
                            woCrewData: a!forEach(
                              items: local!selectionWeekMap[local!dayIndex].workOrderData,
                              expression: fv!item
                            ),
                            totalHours: local!selectionWeekMap[local!dayIndex].totalHours,
                            status: local!selectionWeekMap[local!dayIndex].status
                          )
                        )
                      )
                    )
                  )
                },
                {}
              ),
              a!save(
                local!selectionMap,
                rule!ATE_castMTEOfflineTimeSheetMap(
                  selectedWorkOrders: local!selectedWOnumbers,
                  map: local!selectionMap
                )
              ),
              a!save(
                local!selectedCrewWoDetails,
                rule!ATE_RULE_sortWOListBasedOnMTEOfflineSelectedWo(
                  productionUnitWo: local!selectedCrewWoDetails,
                  selectedWO: local!selectedWOnumbers,
                  woFavourites: local!woFavourites
                )
              ),
              a!save(
                local!allSelectedWOconfigHourType,
                index(
                  local!allWOconfigHourType,
                  wherecontains(
                    tointeger(
                      index(
                        local!selectedCrewWoDetails,
                        'recordType!{96a1105e-c06f-47a3-9521-815d11fdb1d5}ROME Production Unit WO.relationships.{7522895c-d9ee-4bb6-9000-2040ca09171b}contractListRegion102.relationships.{7cdbf61e-5e14-425e-b5a8-30cb39296721}configuration.fields.{f0a38adf-be75-47bb-808f-104043b69f31}configurationId',
                        {}
                      )
                    ),
                    index(
                      local!allWOconfigHourType,
                      'recordType!{0426e3e6-4546-41d3-8b1b-85aebf27b019}ATE L Configuration Hour Type.fields.{32bbd2a9-113e-471e-9c11-d45398b827d5}configurationId',
                      {}
                    )
                  )
                )
              )
            },
            showWhen: local!activeMilestone = 2,
            disabled: a!isNullOrEmpty(local!selectedWOnumbers),
            color: cons!ROME_TEXT_HEX_ORANGE,
            style: "SOLID"
          ),
          a!buttonWidget(
            label: cons!ATE_TXT_BUTTON_LABEL_CONTINUE_TO_REVIEW,
            value: cons!ATE_TXT_BUTTON_LABEL_CONTINUE_TO_REVIEW,
            saveInto: {
              a!save(
                local!activeMilestone,
                local!activeMilestone + 1
              ),
              if(
                local!selectionMap.entryType = cons!ATE_TXT_DAILY_WEEKLY_MTE_OFFLINE[2],
                a!save(
                  local!selectionWeekMap,
                  rule!ATE_UTIL_offlineClearExcludedPayrollOverrideDays(
                    weekData: a!forEach(
                      items: local!weekCrewData,
                      expression: a!map(
                        entryType: local!selectionMap.entryType,
                        crewTemplateId: local!selectionMap.crewTemplateId,
                        crew: local!selectionMap.crew,
                        date: fv!item.date,
                        workOrderData: fv!item.woCrewData
                      )
                    ),
                    woKey: "workOrderData"
                  )
                ),
                a!save(
                  local!selectionMap,
                  a!update(
                    local!selectionMap,
                    "workOrderData",
                    local!currentWoCrewData
                  )
                )
              )
            },
            showWhen: local!activeMilestone = 3,
            validate: true,
            disabled: { not(local!weekTotalPg3 > 0) },
            color: cons!ROME_TEXT_HEX_ORANGE,
            style: "SOLID"
          ),
          /*AS-1734*/
          a!buttonWidget(
            label: cons!ATE_TXT_BUTTON_LABEL_SUBMIT_TIMESHEET,
            value: cons!ATE_TEXT_BUTTON_VALUE_SUBMIT,
            saveInto: {
              ri!buttonAction,
              a!save(
                local!activeMilestone,
                local!activeMilestone + 1
              ),
              a!save(
                ri!finalTimesheetMap,
                if(
                  local!selectionMap.entryType = cons!ATE_TXT_DAILY_WEEKLY_MTE_OFFLINE[2],
                  rule!ATE_UTIL_offlineClearExcludedPayrollOverrideDays(
                    weekData: local!selectionWeekMap,
                    woKey: "workOrderData"
                  ),
                  local!selectionMap
                )
              ),
              if(
                a!isNullOrEmpty(local!timesheetCustomFieldValue),
                {},
                a!save(
                  local!timesheetCustomFieldValue,
                  a!update(
                    local!timesheetCustomFieldValue,
                    {
                      "createdBy",
                      "createdOn",
                      "modifiedBy",
                      "modifiedOn"
                    },
                    {
                      loggedInUser(),
                      now(),
                      loggedInUser(),
                      now()
                    }
                  )
                )
              ),
              a!save(
                ri!customFieldValue,
                local!timesheetCustomFieldValue
              ),
              a!save(ri!woFavouritesList, local!woFavourites),
              a!save(ri!loggedInUser, local!loggedInUser)
            },
            showWhen: local!activeMilestone = 4,
            validate: true,
            disabled: a!isNullOrEmpty(local!dayTotalPg3),
            submit: true,
            color: cons!ROME_TEXT_HEX_ORANGE,
            style: "SOLID"
          )/*AS-1734*/
          
        },
        secondaryButtons: {
          a!buttonWidget(
            label: cons!ATE_TEXT_BUTTON_VALUE_CANCEL,
            value: cons!ATE_TEXT_BUTTON_VALUE_CANCEL,
            saveInto: ri!buttonAction,
            validate: false(),
            submit: true(),
            color: cons!ROME_TEXT_HEX_ORANGE
          ),
          a!buttonWidget(
            label: cons!ATE_TEXT_BUTTON_LABEL_BACK,
            value: cons!ATE_TEXT_BUTTON_LABEL_BACK,
            saveInto: {
              if(
                local!activeMilestone = 3,
                {
                  if(
                    local!selectionMap.entryType = cons!ATE_TXT_DAILY_WEEKLY_MTE_OFFLINE[2],
                    {
                      a!save(
                        local!selectionWeekMap,
                        rule!ATE_UTIL_offlineClearExcludedPayrollOverrideDays(
                          weekData: a!forEach(
                            items: local!weekCrewData,
                            expression: a!map(
                              entryType: local!selectionMap.entryType,
                              crewTemplateId: local!selectionMap.crewTemplateId,
                              crew: local!selectionMap.crew,
                              date: fv!item.date,
                              workOrderData: fv!item.woCrewData
                            )
                          ),
                          woKey: "workOrderData"
                        )
                      ),
                      
                    },
                    {}
                  ),
                  a!save(
                    local!selectionMap.workOrderData,
                    local!currentWoCrewData
                  )
                },
                {}
              ),
              a!save(
                local!activeMilestone,
                local!activeMilestone - 1
              )
            },
            showWhen: local!activeMilestone > 1,
            validate: false(),
            color: cons!ROME_TEXT_HEX_ORANGE
          )
        }
      )
    }
  )
)

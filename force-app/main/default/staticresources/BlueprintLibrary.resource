[
  {
    "name": "case_escalate",
    "label": "Case Escalation",
    "tags": [
      "service",
      "Case",
      "Escalation"
    ],
    "targetSObject": "Case",
    "operation": "UPDATE",
    "summary": "Escalated case with new priority and owner.",
    "checkpoint": "Escalate the case, adjust priority, and (optionally) reassign ownership.",
    "keyFields": [
      "Id"
    ],
    "inputs": [
      {
        "apiName": "Id",
        "fieldApiName": "Id",
        "label": "Case Id",
        "dataType": "Id",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "Status",
        "fieldApiName": "Status",
        "label": "Status",
        "dataType": "String",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "Priority",
        "fieldApiName": "Priority",
        "label": "Priority",
        "dataType": "String",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "Escalation_Notes__c",
        "fieldApiName": "Escalation_Notes__c",
        "label": "Escalation Notes",
        "dataType": "String",
        "required": false,
        "usage": "FIELD"
      },
      {
        "apiName": "OwnerId",
        "fieldApiName": "OwnerId",
        "label": "New Owner",
        "dataType": "Id",
        "required": false,
        "usage": "FIELD"
      }
    ],
    "guardrails": [
      {
        "type": "FLS_EDIT",
        "params": {
          "fields": [
            "Status",
            "Priority",
            "Escalation_Notes__c",
            "OwnerId"
          ]
        }
      },
      {
        "type": "PII_REDACT",
        "params": {
          "fields": [
            "Escalation_Notes__c"
          ]
        },
        "message": "Redact sensitive escalation notes before execution."
      },
      {
        "type": "SHARING_REQUIRED"
      }
    ]
  },
  {
    "name": "lead_qualify",
    "label": "Lead Qualification",
    "tags": [
      "sales",
      "Lead",
      "Qualification"
    ],
    "targetSObject": "Lead",
    "operation": "UPDATE",
    "summary": "Qualified lead and updated status/rating.",
    "checkpoint": "Qualify the lead and update status.",
    "keyFields": [
      "Id"
    ],
    "inputs": [
      {
        "apiName": "Id",
        "fieldApiName": "Id",
        "label": "Lead Id",
        "dataType": "Id",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "Status",
        "fieldApiName": "Status",
        "label": "Status",
        "dataType": "String",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "Rating",
        "fieldApiName": "Rating",
        "label": "Rating",
        "dataType": "String",
        "required": false,
        "usage": "FIELD"
      },
      {
        "apiName": "IsConverted",
        "fieldApiName": "IsConverted",
        "label": "Is Converted",
        "dataType": "Boolean",
        "required": false,
        "usage": "FIELD"
      }
    ],
    "guardrails": [
      {
        "type": "FLS_EDIT",
        "params": {
          "fields": [
            "Status",
            "Rating",
            "IsConverted"
          ]
        }
      },
      {
        "type": "SHARING_REQUIRED"
      }
    ]
  },
  {
    "name": "opportunity_closed_won",
    "tags": [
      "Opportunity",
      "Update",
      "Stage",
      "ClosedWon"
    ],
    "operation": "UPDATE",
    "targetSObject": "Opportunity",
    "inputs": {
      "Id": {
        "type": "Id",
        "required": true
      },
      "StageName": {
        "type": "Picklist",
        "required": true,
        "enum": [
          "Closed Won"
        ]
      },
      "CloseDate": {
        "type": "Date",
        "required": false
      }
    },
    "guardrails": {
      "fls": {
        "fields": [
          "StageName",
          "CloseDate"
        ],
        "requireUpdateable": true
      },
      "sharing": "WITH_SHARING"
    },
    "checkpoint": "Set opportunity to Closed Won with optional CloseDate."
  },
  {
    "name": "oppty_closed_won",
    "label": "Opportunity Closed Won",
    "tags": [
      "sales",
      "Opportunity",
      "Stage",
      "ClosedWon"
    ],
    "targetSObject": "Opportunity",
    "operation": "UPDATE",
    "summary": "Updated Opportunity stage to Closed Won.",
    "checkpoint": "Set opportunity to Closed Won with optional CloseDate.",
    "keyFields": [
      "Id"
    ],
    "inputs": [
      {
        "apiName": "Id",
        "fieldApiName": "Id",
        "label": "Opportunity Id",
        "dataType": "Id",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "StageName",
        "fieldApiName": "StageName",
        "label": "New Stage",
        "dataType": "String",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "CloseDate",
        "fieldApiName": "CloseDate",
        "label": "Close Date",
        "dataType": "Date",
        "required": false,
        "usage": "FIELD"
      }
    ],
    "guardrails": [
      {
        "type": "FLS_EDIT",
        "params": {
          "fields": [
            "StageName",
            "CloseDate"
          ]
        }
      },
      {
        "type": "ENUM_ALLOWED",
        "params": {
          "field": "StageName",
          "values": [
            "Closed Won"
          ]
        }
      },
      {
        "type": "SHARING_REQUIRED"
      }
    ]
  }
]
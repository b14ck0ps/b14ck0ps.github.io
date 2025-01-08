---
date: '2025-01-08T19:41:18+06:00'
draft: false
title: 'Dynamic Attachment for Custom Workflow Email'
author: "Ajran Hossain"
tags:
  - AL
  - D365BC
description: "Learn how to add a dynamic attachment generated from a custom report for a custom workflow in Dynamics 365 Business Central."
---
## How to Add a Dynamic Attachment Generated from a Custom Report for a Custom Workflow Email

Recently, I received a request from a client to develop a Comparison Sheet Module for Quotations with an approval workflow. To achieve this, I followed the [official guide for workflow events and responses in Business Central](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-walkthrough-workflow-events-responses).

While implementing the approval workflow, I encountered a challenge: the need to dynamically attach a document to the email notification sent for approval. After much exploration, I couldn’t find an easier solution, so I decided to tackle this problem using AL code and event subscriptions. While this might not be the best solution, it worked for my use case. Here’s how I did it.

---

### Step 1: Subscribe the `OnBeforeSend` Event
To dynamically attach a file to the email, I subscribed to the `OnBeforeSend` event of the `Email Item` table. This event allows me to intercept the email before it’s sent and add the necessary attachment.

```al
[EventSubscriber(ObjectType::Table, Database::"Email Item", OnBeforeSend, '', false, false)]
local procedure OnBeforeSend(var EmailItem: Record "Email Item"; var HideMailDialog: Boolean; var MailManagement: Codeunit "Mail Management"; EmailScenario: Enum "Email Scenario"; var Result: Boolean; var IsHandled: Boolean)
```

---

### Step 2: Identify the Relevant Record
Using the `GetSourceDocuments` method, I retrieved all related records for the email. This method provides the source tables, source IDs, and relation types as lists.

```al
EmailItem.GetSourceDocuments(SourceTableList, SourceIDList, SourceRelationTypeList);

// Check if the email is linked to a CS Quote Header
if not SourceTableList.Contains(Database::"CS Quote Header") then
    exit;
```

To ensure I was attaching the file only to emails related to the `CS Quote Header`, I checked whether this table was present in the source tables list.

---

### Step 3: Retrieve the Relevant Record Data
Once I confirmed the email was related to a `CS Quote Header`, I identified the corresponding record using its `SystemId`.

```al
CSTableIndex := SourceTableList.IndexOf(Database::"CS Quote Header");
SysGuidCS := SourceIDList.Get(CSTableIndex); // Table Index and Source ID are in the same index
CS.GetBySystemId(SysGuidCS);
```

This step ensures I am working with the exact `CS Quote Header` record linked to the email.

---

### Step 4: Generate and Attach the PDF
The final step was to generate the PDF file from the `CS Quotation Report` and attach it to the email.

```al
tempBlob.CreateOutStream(OutStr);
CSQR.SetTableView(CS);
FileName := 'CS Quotation -' + CS."CS No." + '.pdf';
PdfGenerated := CSQR.SaveAs('', format::Pdf, OutStr);

if PdfGenerated then begin
    tempBlob.CreateInStream(InStr);
    EmailItem.AddAttachment(Instr, FileName);
end;
```

By creating a temporary blob to store the PDF output, I generated the file and added it as an attachment to the `Email Item` record.

---

### Complete Code
Here is the full implementation of the event subscriber:

```al
[EventSubscriber(ObjectType::Table, Database::"Email Item", OnBeforeSend, '', false, false)]
local procedure OnBeforeSend(var EmailItem: Record "Email Item"; var HideMailDialog: Boolean; var MailManagement: Codeunit "Mail Management"; EmailScenario: Enum "Email Scenario"; var Result: Boolean; var IsHandled: Boolean)
var
    CS: Record "CS Quote Header";
    CSQR: Report "CS Quotation Report";
    tempBlob: Codeunit "Temp Blob";
    PdfGenerated: Boolean;
    SysGuidCS: Guid;
    Instr: InStream;
    CSTableIndex: Integer;
    SourceIDList: List of [Guid];
    SourceRelationTypeList: List of [Integer];
    SourceTableList: List of [Integer];
    OutStr: OutStream;
    format: ReportFormat;
    FileName: Text[250];
begin
    // Retrieve source documents linked to the email
    EmailItem.GetSourceDocuments(SourceTableList, SourceIDList, SourceRelationTypeList);

    // Check if the email is linked to a CS Quote Header
    if not SourceTableList.Contains(Database::"CS Quote Header") then
        exit;

    // Retrieve the CS Quote Header record
    CSTableIndex := SourceTableList.IndexOf(Database::"CS Quote Header");
    SysGuidCS := SourceIDList.Get(CSTableIndex); // Table Index and Source ID are in the same index
    CS.GetBySystemId(SysGuidCS);

    // Generate and attach the PDF
    tempBlob.CreateOutStream(OutStr);
    CSQR.SetTableView(CS);
    FileName := 'CS Quotation -' + CS."CS No." + '.pdf';
    PdfGenerated := CSQR.SaveAs('', format::Pdf, OutStr);

    if PdfGenerated then begin
        tempBlob.CreateInStream(InStr);
        EmailItem.AddAttachment(Instr, FileName);
    end;
end;
```

---

This solution worked perfectly for my use case. While there might be other approaches to achieve the same result, this method allowed me to dynamically generate and attach a PDF document to approval emails in a custom workflow. If you’re facing a similar challenge, I hope this helps!

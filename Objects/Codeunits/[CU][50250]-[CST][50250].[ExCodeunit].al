// - Strategix Integration Extension
//Version: 1
//Author:  CS
//Type:    Custom
//Object:  Codeunit
//ID:      50250
//NAME:    Example Codeunit

codeunit 50250 "Example Codeunit"
{
    trigger OnRun()
    begin
    end;

    //GAP6>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    procedure fAdjustSpayConsumptionJournal(PvTemplate: code[20]; PvBatch: Code[20]; PvTotalConsumption: Decimal; PvColour: code[20]) RvSucess: Boolean
    var
        LrecConsumptionJournal: Record "Item Journal Line";
        LrecConsumptionJournal2: Record "Item Journal Line";
        LrecPowderItem: Record Item;
        LrecCoatedItem: Record Item;
        LrecPOL: Record "Prod. Order Line";
        LvCoatedLineArea: Decimal;
        LvSumOfCoatedArea: Decimal;
        LvLineWeight: Decimal;
        LvLineActualConsumption: Decimal;
    begin
        RvSucess := false;
        if PvTotalConsumption <= 0 then
            error('Cannot consume 0 or less!');
        LrecPowderItem.get(PvColour);
        LrecPowderItem.TestField("Item Category Code", 'POWDER');
        LrecConsumptionJournal.reset;
        LrecConsumptionJournal.SetRange("Journal Template Name", PvTemplate);
        LrecConsumptionJournal.SetRange("Journal Batch Name", PvBatch);
        LrecConsumptionJournal.SetRange("Item No.", LrecPowderItem."No.");
        If LrecConsumptionJournal.FindFirst() then begin
            repeat
                LrecPOL.get(LrecPOL.Status::Released, LrecConsumptionJournal."Order No.", LrecConsumptionJournal."Order Line No.");
                LrecCoatedItem.get(LrecPOL."Item No.");
                LvSumOfCoatedArea += LrecCoatedItem."BWA Square Meter" * LrecPOL.Quantity;
            until LrecConsumptionJournal.Next() = 0;

            LrecConsumptionJournal.FindFirst();

            repeat
                LrecPOL.get(LrecPOL.Status::Released, LrecConsumptionJournal."Order No.", LrecConsumptionJournal."Order Line No.");
                LrecCoatedItem.get(LrecPOL."Item No.");
                LvLineWeight := ((LrecCoatedItem."BWA Square Meter" * LrecPOL.Quantity) / LvSumOfCoatedArea);
                LvLineActualConsumption := (LvLineWeight * PvTotalConsumption);
                LrecConsumptionJournal2.get(LrecConsumptionJournal."Journal Template Name",
                                            LrecConsumptionJournal."Journal Batch Name",
                                            LrecConsumptionJournal."Line No.");
                LrecConsumptionJournal2.validate(Quantity, LvLineActualConsumption);
                LrecConsumptionJournal2.Modify(true);
            until LrecConsumptionJournal.Next() = 0;
            RvSucess := true;
        end;
    end;
    //GAP6<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    //=============================================================================================================================
    //GAP15>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    procedure fCreateMetalSalesOrder(PrecSOH: Record "Sales Header"; PvPaymentTerms: code[20]): code[20]
    var
        LrecSOH_PC: Record "Sales Header";
        LRECSOH_STK: Record "Sales Header";
        LrecSOL_PC: Record "Sales Line";
        LrecSOL_STK: Record "Sales Line";
        LrecItem_PC: Record item;
        LrecItem_STK: record Item;
        LvMetalItemFound: Boolean;
        LvLineNo: Integer;
    begin
        LvMetalItemFound := false;
        LrecSOH_PC.get(PrecSOH."Document Type", PrecSOH."No.");
        LrecSOh_PC.TestField(status, LrecSOH_PC.Status::Released);
        LrecSOL_PC.reset;
        LrecSOL_PC.setrange("Document Type", LrecSOH_PC."Document Type");
        LrecSOL_PC.setrange("Document No.", LrecSOH_PC."No.");
        LrecSOL_PC.SetFilter(Type, '%1|%2', LrecSOL_PC.Type::Item, LrecSOL_PC.Type::" ");
        //Test If Substitude metal items exist
        if LrecSOL_PC.FindFirst() then
            repeat
                if LrecItem_PC.get(LrecSOL_PC."No.") and LrecItem_STK.get(LrecItem_PC."BWA Stocked Metal Code") then
                    LvMetalItemFound := true;
            until LrecSOL_PC.Next() = 0;

        if LrecSOL_PC.FindFirst() and LvMetalItemFound then begin
            fInsertStockingSalesHeader(LrecSOH_PC, LRECSOH_STK, PvPaymentTerms);
            LvLineNo := 10000;
            fInsertStockingSalesLine(LrecSOL_PC, LrecSOL_STK, LRECSOH_STK, LvLineNo, 'STOCKING ORDER FOR POWDERCOATING');
            fInsertStockingSalesLine(LrecSOL_PC, LrecSOL_STK, LRECSOH_STK, LvLineNo, StrSubstNo('PC Order No: %1', LrecSOH_PC."No."));
            repeat
                fInsertStockingSalesLine(LrecSOL_PC, LrecSOL_STK, LRECSOH_STK, LvLineNo, '');
            until LrecSOL_PC.Next() = 0;
        end
        else
            error('No Stocked Metal Substitude found!');

        exit(LRECSOH_STK."No.");
    end;

    local procedure fInsertStockingSalesHeader(VAR PrecSOH_PC: Record "Sales Header"; VAR PrecSOH_STK: Record "Sales Header"; PvPaymentTerms: code[20])
    var
        LrecPaymentTerms: Record "Payment Terms";
    begin
        LrecPaymentTerms.Get(PvPaymentTerms);

        PrecSOH_STK.init;
        PrecSOH_STK.validate("Document Type", PrecSOH_STK."Document Type"::Order);
        PrecSOH_STK.insert(true);
        PrecSOH_STK.validate("Sell-to Customer No.", PrecSOH_PC."Sell-to Customer No.");
        PrecSOH_STK.validate("Order Date", PrecSOH_PC."Document Date");
        PrecSOH_STK.validate("Document Date", PrecSOH_PC."Document Date");
        PrecSOH_STK.validate("Posting Date", PrecSOH_PC."Posting Date");
        PrecSOH_STK.validate("Ship-to Code", PrecSOH_PC."Ship-to Code");
        PrecSOH_STK.validate("Shortcut Dimension 1 Code", 'STK');
        PrecSOH_STK.validate("Shortcut Dimension 2 Code", 'METAL');
        PrecSOH_STK.Validate("Payment Terms Code", PvPaymentTerms);
        PrecSOH_STK.Validate("Location Code", 'STOCKING');
        PrecSOH_STK.Modify(true);
    end;

    local procedure fInsertStockingSalesLine(VAR PrecSOL_PC: Record "Sales Line"; var PrecSOL_STK: Record "Sales Line"; PrecSOH_STK: Record "Sales Header"; VAR PvLine: Integer; PvMsg: Text[50])
    var
        LrecItem_STK: Record item;
        LrecItem_PC: Record Item;
    begin

        If PvMsg <> '' then begin
            PrecSOL_STK.init;
            PrecSOL_STK.validate("Document Type", PrecSOH_STK."Document Type");
            PrecSOL_STK.Validate("Document No.", PrecSOH_STK."No.");
            PrecSOL_STK.Validate("Line No.", PvLine);
            PrecSOL_STK.Validate(Type, PrecSOL_STK.type::" ");
            PrecSOL_STK.Description := PvMsg;
            PrecSOL_STK.insert(true);
        end
        else begin
            if not (PrecSOL_PC.Type in [PrecSOL_PC.Type::" ", PrecSOL_PC.Type::Item]) then
                exit;

            if not LrecItem_PC.get(PrecSOL_PC."No.") then
                exit;

            if not LrecItem_STK.get(LrecItem_PC."BWA Stocked Metal Code") then
                exit;

            fTestDefaultDims(LrecItem_STK."No.");

            PrecSOL_STK.init;
            PrecSOL_STK.TransferFields(PrecSOL_PC, false);
            PrecSOL_STK.validate("Document Type", PrecSOH_STK."Document Type");
            PrecSOL_STK.Validate("Document No.", PrecSOH_STK."No.");
            PrecSOL_STK.Validate("Line No.", PvLine);
            if PrecSOL_STK.Type = PrecSOL_STK.Type::Item then begin
                PrecSOL_STK.Validate("No.", LrecItem_STK."No.");
                PrecSOL_STK.Validate("Location Code", 'STOCKING');
                PrecSOL_STK.validate(Quantity, PrecSOL_PC.Quantity);
            end;

            PrecSOL_STK.insert(true);
        end;
        PvLine += 10000;
    end;
    //GAP15<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    //=============================================================================================================================
    //GAP2>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    procedure fCollectMetal(PrecSOH: Record "Sales Header")
    var
        LrecSOL: Record "Sales Line";
        LrecIJL: Record "Item Journal Line";
        LrecItem: Record Item;
        LrecSnRsetup: Record "Sales & Receivables Setup";
        LrecIJB: Record "Item Journal Batch";
        LcuNoSmngmnt: Codeunit NoSeriesManagement;
        LvDocNo: Code[20];
        LvLineNo: Integer;
    begin
        LrecSnRsetup.get();
        PrecSOH.TestField(Status, PrecSOH.Status::Released);
        LrecIJB.get(LrecSnRsetup."BWA Collection Template", LrecSnRsetup."BWA Collection Batch");
        LrecIJB.TestField("No. Series", '');
        LvDocNo := LcuNoSmngmnt.GetNextNo(LrecSnRsetup."BWA Collection No. Series", Today(), true);
        PrecSOH.TestField("BWA Colour Specifier");

        LrecIJL.reset;
        LrecIJL.SetRange("Journal Template Name", LrecIJB."Journal Template Name");
        LrecIJL.SetRange("Journal Batch Name", LrecIJB.Name);
        if LrecIJL.FindLast() then
            LvLineNo := LrecIJL."Line No." + 10000
        else
            LvLineNo := 10000;

        LrecSOL.reset;
        LrecSOL.SetRange("Document Type", PrecSOH."Document Type");
        LrecSOL.SetRange("Document No.", PrecSOH."No.");
        LrecSOL.SetRange(Type, LrecSOL.type::Item);
        LrecSOL.setfilter("BWA Qty to Collect", '<>0');

        if LrecSOL.FindSet() then begin
            repeat
                LrecItem.get(LrecSOL."No.");
                if LrecItem."Item Category Code" <> 'PC ITEMS' then
                    error('Not allowed to collect non-PCI items!');
                fInsertCollectionJournal(LrecIJL, LrecSOL, LrecIJB, LvDocNo, LvLineNo);
            until LrecSOL.Next() = 0;

            fPostCollectionJournal(LrecIJL);
        end;
    end;

    local procedure fInsertCollectionJournal(var PrecIJL: Record "Item Journal Line";
                                             var PrecSOL: record "Sales Line";
                                             PrecIJB: Record "Item Journal Batch";
                                             PvDocNo: Code[20];
                                             var PvLineNo: Integer)
    var
        lrecitem: Record item;
        LrecTrackSpec: Record "Tracking Specification" temporary;
        LrecSOH: Record "Sales Header";
    begin
        PrecIJL.Reset();
        lrecitem.get(PrecSOL."No.");

        LrecSOH.get(PrecSOL."Document Type", PrecSOL."Document No.");

        PrecIJL.init;
        PrecIJL.Validate("Journal Template Name", PrecIJB."Journal Template Name");
        PrecIJL.Validate("Journal Batch Name", PrecIJB.Name);
        PrecIJL.Validate("Line No.", PvLineNo);
        PvLineNo += 1000;

        precIJL.Validate("Posting Date", Today());

        if PrecSOL."BWA Qty to Collect" > 0 then
            PrecIJL.validate("Entry Type", PrecIJL."Entry Type"::"Positive Adjmt.")
        else
            PrecIJL.validate("Entry Type", PrecIJL."Entry Type"::"Negative Adjmt.");

        PrecIJL.Validate("Document No.", PvDocNo);
        PrecIJL.validate("Item No.", PrecSOL."No.");
        //PrecIJL.Validate("Variant Code", PrecSOL."Variant Code");

        if PrecSOL."BWA Qty to Collect" > 0 then
            PrecIJL.Description := StrSubstNo('CA:%1;%2', PrecSOL."Document No.", PrecSOL."No.")
        else
            PrecIJL.Description := StrSubstNo('RET:%1;%2', PrecSOL."Document No.", PrecSOL."No.");

        PrecIJL.validate("Location Code", PrecSOL."Location Code");
        PrecIJL.Validate(Quantity, Abs(PrecSOL."BWA Qty to Collect"));
        PrecIJL.Validate("Unit of Measure Code", PrecSOL."Unit of Measure Code");
        PrecIJL.Validate("Unit Cost", 0);
        PrecIJL.Validate("Unit Amount", 0);
        //Insert and Track
        if (PrecIJL.insert(true)) then begin
            //Update Sales Order Line
            if (fCreateItmJrnTracking(PrecIJL, PrecSOL)) then begin
                PrecSOL."BWA Qty to Collect" := 0;
                PrecSOL.modify;
            end
            else
                error('Collection line could not be tracked');

        end
        else
            error('Collection line could not be created');

    end;

    local procedure fPostCollectionJournal(var PrecIJL: Record "Item Journal Line")
    var
        LcuPostItmJrnl: Codeunit "Item Jnl.-Post";
        LrecIJL: Record "Item Journal Line";
    begin
        LrecIJL.reset;
        LrecIJL.SetRange("Journal Template Name", PrecIJL."Journal Template Name");
        LrecIJL.SetRange("Journal Batch Name", PrecIJL."Journal Batch Name");

        if LrecIJL.FindFirst() then
            LcuPostItmJrnl.Run(PrecIJL);
    end;

    local procedure fCreateItmJrnTracking(PrecItmJnl: Record "Item Journal Line"; PrecSOL: Record "Sales Line"): Boolean
    var
        LrecResEntry: Record "Reservation Entry";
        LrecLotInfo: Record "Lot No. Information";
        LrecItem: Record item;
        LvEntryNo: Integer;
        LvFactor: Integer;
    begin
        LrecResEntry.reset;

        if LrecResEntry.FindLast() then
            LvEntryNo := LrecResEntry."Entry No." + 1
        else
            LvEntryNo := 1;

        if PrecSOL."BWA Qty to Collect" > 0 then
            LvFactor := 1
        else
            LvFactor := -1;

        LrecItem.get(PrecItmJnl."Item No.");

        LrecResEntry.init;
        LrecResEntry."Entry No." := LvEntryNo;
        LrecResEntry."Reservation Status" := LrecResEntry."Reservation Status"::Prospect;
        LrecResEntry."Creation Date" := WorkDate();
        LrecResEntry."Source Type" := Database::"Item Journal Line";
        if LvFactor = 1 then
            LrecResEntry."Source Subtype" := 2
        else
            LrecResEntry."Source Subtype" := 3;
        LrecResEntry."Source ID" := 'ITEM';
        LrecResEntry."Source Batch Name" := PrecItmJnl."Journal Batch Name";
        LrecResEntry."Source Ref. No." := PrecItmJnl."Line No.";
        LrecResEntry.Positive := (LvFactor = 1);
        LrecResEntry.validate("Location Code", PrecItmJnl."Location Code");
        LrecResEntry.Validate("Item No.", PrecItmJnl."Item No.");
        LrecResEntry.Validate("Variant Code", PrecItmJnl."Variant Code");
        LrecResEntry.Validate("Quantity (Base)", PrecItmJnl."Quantity (Base)" * LvFactor);
        LrecResEntry.Validate(Quantity, PrecItmJnl.Quantity * LvFactor);
        LrecResEntry."Item Tracking" := LrecResEntry."Item Tracking"::"Lot No.";
        LrecResEntry."Lot No." := format(PrecSOL."Document No.");
        if LrecResEntry.insert(true) then begin
            if not LrecLotInfo.get(LrecResEntry."Item No.", LrecResEntry."Variant Code", LrecResEntry."Lot No.") then begin
                LrecLotInfo.init;
                LrecLotInfo.Validate("Item No.", LrecResEntry."Item No.");
                LrecLotInfo.Validate("Variant Code", LrecResEntry."Variant Code");
                LrecLotInfo.Validate("Lot No.", LrecResEntry."Lot No.");
                if LvFactor = 1 then
                    LrecLotInfo.Description := StrSubstNo('Col:%1 on %2/%3',
                                                        PrecSOL."Sell-to Customer No.",
                                                        PrecSOL."Document No.",
                                                        PrecSOL."Line No.")
                else
                    LrecLotInfo.Description := StrSubstNo('Ret:%1 on %2/%3',
                                        PrecSOL."Sell-to Customer No.",
                                        PrecSOL."Document No.",
                                        PrecSOL."Line No.");
                LrecLotInfo.insert(true);
            end;
        end
        else
            exit(false);

        exit(true);
    end;
    //GAP2<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    //=============================================================================================================================
    //GAP13>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    procedure fConfigurePCI(PvColour: code[20]; PvDie: Code[10]; PvLenght: Integer; var PvPCitem: Code[20]; var PvPCvariant: Code[20])
    var
        LrecItemPCI: Record Item;
        LrecItemPowder: Record Item;
        LrecItemVariant: Record "Item Variant";
        LrecDieRegister: Record "BWA Die Register";
        LrecProdBOMHeader: Record "Production BOM Header";
        LrecSalesPricePCI: Record "Sales Price";
        LrecSalesPricePowder: Record "Sales Price";
        LvExistingItem: Code[20];
    begin
        //Check Requirements

        LrecDieRegister.get(PvDie);
        LrecItemPowder.get(PvColour);
        LrecItemPowder.TestField(Blocked, false);

        //Create Item
        if not LrecItemPCI.get(fGetPCitem(PvDie, PvLenght)) then begin
            LvExistingItem := 'PCI-' + Format(LrecDieRegister."Die No.") + '-' + Format(PvLenght);
            LrecItemPCI.get(fInsertPCItem(LvExistingItem, PvDie, PvLenght));
        end;

        //Create Variant
        LrecItemVariant.reset;
        if not LrecItemVariant.get(LrecItemPCI."No.", PvColour) then begin
            LrecItemVariant.init;
            LrecItemVariant.validate("Item No.", LrecItemPCI."No.");
            LrecItemVariant.Validate(Code, PvColour);
            LrecItemVariant.Validate(Description, Format(LrecItemPCI."No." + '-' + PvColour));
            LrecItemVariant.Validate("Description 2", LrecItemPowder.Description);
            LrecItemVariant.Validate("BWA Item Variant BOM", LrecProdBOMHeader."No.");
            LrecItemVariant.insert(true);
        end;

        //Create BOM
        if not LrecProdBOMHeader.get(LrecItemPCI."No.") then
            LrecProdBOMHeader.get(fPCIProdBOM(LrecItemPCI."No.", PvColour));

        //Update Variant
        if (LrecItemVariant."BWA Item Variant BOM" = '') then begin
            LrecItemVariant.validate("BWA Item Variant BOM", LrecProdBOMHeader."No.");
            LrecItemVariant.Modify(true);
        end;

        //Create Price
        fSetSalesPrices(LrecItemVariant);

        PvPCitem := LrecItemVariant."Item No.";
        PvPCvariant := LrecItemVariant.code;
    end;

    local procedure fGetPCitem(PvDie: code[10]; PvLenght: Integer) RvItem: Code[20]
    var
        lrecItem: Record Item;
        LvText00001: TextConst ENU = 'There are %3 duplicate items for die %1 and Lenght %2!';
    begin
        lrecItem.reset;
        lrecItem.setrange("BWA Die No.", PvDie);
        lrecItem.SetRange("BWA Lenght", PvLenght);
        lrecItem.SetRange("Item Category Code", 'PC ITEMS');

        if lrecItem.FindFirst() then begin
            if lrecItem.Count() > 1 then
                error(LvText00001, PvDie, PvLenght, lrecItem.Count())
            else
                RvItem := lrecItem."No.";
        end
        else
            RvItem := '';
    end;

    local procedure fInsertPCItem(PvNewItemNo: Code[20]; PvDieNo: Code[10]; PvLenght: Integer) RvItemNo: Code[20]
    var
        LrecItem: Record 27;
        LrecDieReg: Record "BWA Die Register";
        LrecIUOM: Record "Item Unit of Measure";
        LcuAttMngt: Codeunit "Item Attribute Management";
        LvSquares: Decimal;
    begin
        LrecDieReg.get(PvDieNo);

        LrecItem.init;
        LrecItem.Validate("No.", PvNewItemNo);
        LrecItem.Validate(Description, StrSubstNo('%1', PvDieNo));
        LrecItem.Validate("Description 2", StrSubstNo('Die:%1 Lenght:%2', PvDieNo, PvLenght));
        LrecItem.insert(true);
        fApplyItemSetupTemplate(LrecItem, 'POWDERCOAT');

        LrecItem.Validate("BWA Die No.", PvDieNo);
        LrecItem.Validate("BWA Lenght", PvLenght);
        LrecItem.Validate(Picture, LrecDieReg."Die Profile");
        LrecItem.Modify(true);

        LrecIUOM.Init();
        LrecIUOM.Validate("Item No.", LrecItem."No.");
        LrecIUOM.Validate(Code, 'SQM');
        LrecIUOM.Validate("Qty. per Unit of Measure", fCalcSquareArea(LrecItem."BWA Lenght", LrecItem."BWA Die No."));
        LrecIUOM.Insert(true);
        LrecIUOM.Init();
        LrecIUOM.Validate(Code, 'METER');
        LrecIUOM.Validate("Qty. per Unit of Measure", (PvLenght / 1000));
        LrecIUOM.Insert(true);

        //Still add Item Attributes


        RvItemNo := LrecItem."No.";
    end;

    local procedure fPCIProdBOM(PvItem: Code[20]; PvColour: Code[20]) RvBOMNo: Code[20]
    var
        LrecBOMheader: Record "Production BOM Header";
        LrecBOMlines: Record "Production BOM Line";
        LrecItemPCI: Record Item;
        LrecItemPowder: Record Item;
        LvBOMcode: Code[20];
        LrecSnRsetup: Record "Sales & Receivables Setup";
        LcuNoSeriesmngt: Codeunit NoSeriesManagement;
    begin
        LrecItemPCI.get(PvItem);
        LrecItemPowder.get(PvColour);
        LrecSnRsetup.get();

        LrecItemPCI.TestField("BWA Square Meter");
        LrecItemPowder.TestField("BWA Coverage per KG");

        //Build BOM Code
        if LrecSnRsetup."BWA Variant BOM No. Series" <> '' then
            LvBOMcode := LcuNoSeriesmngt.GetNextNo(LrecSnRsetup."BWA Variant BOM No. Series", Today(), true)
        else begin
            LrecItemPCI.testfield("BWA Die No.");
            LrecItemPCI.TestField("BWA Lenght");
            LvBOMcode := LrecItemPCI."BWA Die No." + '-' + format(LrecItemPCI."BWA Lenght") + '-' + LrecItemPowder."No.";
        end;



        LrecBOMheader.init;
        LrecBOMheader.Validate("No.", LvBOMcode);
        LrecBOMheader.validate(Description, format(LrecItemPCI.Description));
        LrecBOMheader.Validate("Unit of Measure Code", LrecItemPCI."Base Unit of Measure");
        LrecBOMheader.Insert(true);

        LrecBOMlines.init;
        LrecBOMlines.validate("Production BOM No.", LrecBOMheader."No.");
        LrecBOMlines.validate("Line No.", 10000);
        LrecBOMlines.validate(Type, LrecBOMlines.Type::Item);
        LrecBOMlines.validate("No.", LrecItemPCI."No.");
        //LrecBOMlines.Validate("Variant Code", LrecItemPowder."No.");
        LrecBOMlines.validate("Unit of Measure Code", LrecItemPCI."Base Unit of Measure");
        LrecBOMlines.validate("Quantity per", 1);
        LrecBOMlines.insert(true);

        LrecBOMlines.init;
        LrecBOMlines.validate("Production BOM No.", LrecBOMheader."No.");
        LrecBOMlines.validate("Line No.", 20000);
        LrecBOMlines.validate(Type, LrecBOMlines.Type::Item);
        LrecBOMlines.validate("No.", LrecItemPowder."No.");
        LrecBOMlines.validate("Unit of Measure Code", LrecItemPowder."Base Unit of Measure");
        LrecBOMlines.Validate("Quantity per", LrecItemPCI."BWA Square Meter" * LrecItemPowder."BWA Coverage per KG");
        LrecBOMlines.insert(true);

        LrecBOMheader.validate(Status, LrecBOMheader.Status::Certified);
        LrecBOMheader.Modify(true);

        RvBOMNo := LrecBOMheader."No.";
    end;

    local procedure fApplyItemSetupTemplate(var PrecItem: Record Item; PvItemTemplate: code[20]);
    var
        LcuConfigMngt: Codeunit "Config. Template Management";
        LrfItem: RecordRef;
        LrecConfigTemplateHeader: Record "Config. Template Header";
        LrecDimTemplate: Record "Dimensions Template";
        LrecItem: Record Item;
    begin
        LrecItem.get(PrecItem."No.");
        LrecConfigTemplateHeader.reset;
        LrecConfigTemplateHeader.SetRange(Enabled, true);
        LrecConfigTemplateHeader.SetRange("Table ID", 27);
        LrecConfigTemplateHeader.SetRange(Code, PvItemTemplate);
        if not LrecConfigTemplateHeader.FindFirst then
            error('Template %1 does not exist!', PvItemTemplate);

        LrfItem.GETTABLE(LrecItem);
        LcuConfigMngt.UpdateRecord(LrecConfigTemplateHeader, LrfItem);
        LrecDimTemplate.InsertDimensionsFromTemplates(LrecConfigTemplateHeader, LrecItem."No.", DATABASE::Item);
        LrfItem.SETTABLE(LrecItem);
        LrecItem.Modify();
        PrecItem := LrecItem;
    end;

    procedure fCalcSquareArea(PvLenght: Decimal; PvDie: Code[10]) RvSquareArea: Decimal
    var
        LrecDieRegister: Record "BWA Die Register";
    begin
        //Perimeter --> mm
        //Lenght    --> mm
        //Area      --> M
        if LrecDieRegister.get(PvDie) then begin
            if LrecDieRegister."Misc. Die" then
                RvSquareArea := ((PvLenght) / 1000)
            else
                RvSquareArea := ((LrecDieRegister.Perimeter / 1000) * (PvLenght / 1000));
        end
        else
            RvSquareArea := 0;
    end;

    local procedure fSetSalesPrices(PrecItemVariant: Record "Item Variant")
    var
        LrecItemPCI: Record Item;
        LrecItemPowder: Record Item;
        LrecSalesPricePowder: Record "Sales Price";
        LrecSalesPricePCI_Variant: Record "Sales Price";
        LvCalculatedSalesPrice: Decimal;
    begin
        LrecItemPCI.get(PrecItemVariant."Item No.");
        LrecItemPowder.get(PrecItemVariant.Code);

        LrecSalesPricePCI_Variant.RESET;
        LrecSalesPricePCI_Variant.SETRANGE("Item No.", PrecItemVariant."Item No.");
        LrecSalesPricePCI_Variant.SetRange("Variant Code", PrecItemVariant.Code);
        LrecSalesPricePCI_Variant.SetRange("Unit of Measure Code", LrecItemPCI."Base Unit of Measure");

        LrecSalesPricePowder.reset;
        LrecSalesPricePowder.SetRange("Unit of Measure Code", 'SQM');
        LrecSalesPricePowder.SetRange("Item No.", LrecItemPowder."No.");

        LvCalculatedSalesPrice := 0;
        if not LrecSalesPricePowder.FindFirst() then
            Error('No Valid Price for item %1', LrecItemPowder."No.")
        else
            repeat
                LvCalculatedSalesPrice := LrecSalesPricePowder."Unit Price" * LrecItemPCI."BWA Square Meter";
                LrecSalesPricePCI_Variant.SetRange("Sales Type", LrecSalesPricePowder."Sales Type");
                LrecSalesPricePCI_Variant.SetRange("Sales Code", LrecSalesPricePowder."Sales Code");
                LrecSalesPricePCI_Variant.SetRange("Currency Code", LrecSalesPricePowder."Currency Code");
                LrecSalesPricePCI_Variant.SetRange("Minimum Quantity", LrecSalesPricePowder."Minimum Quantity");
                LrecSalesPricePCI_Variant.SetRange("Starting Date", LrecSalesPricePowder."Starting Date");

                if LrecSalesPricePCI_Variant.FindFirst() then begin
                    if (LrecSalesPricePCI_Variant."Ending Date" <> LrecSalesPricePowder."Ending Date") then begin
                        LrecSalesPricePCI_Variant."Ending Date" := LrecSalesPricePowder."Ending Date";
                        LrecSalesPricePCI_Variant.Modify(true);
                    end;

                    if (LrecSalesPricePCI_Variant."Unit Price" <> LvCalculatedSalesPrice) then begin
                        LrecSalesPricePCI_Variant.Validate("Unit Price", LvCalculatedSalesPrice);
                        LrecSalesPricePCI_Variant.Modify(true);
                    end;
                end
                else begin
                    LrecSalesPricePCI_Variant.INIT;
                    LrecSalesPricePCI_Variant.Validate("Item No.", PrecItemVariant."Item No.");
                    LrecSalesPricePCI_Variant.Validate("Variant Code", PrecItemVariant.CODE);
                    LrecSalesPricePCI_Variant.Validate("Currency Code", LrecSalesPricePowder."Currency Code");
                    LrecSalesPricePCI_Variant.Validate("Sales Type", LrecSalesPricePowder."Sales Type");
                    LrecSalesPricePCI_Variant.Validate("Sales Code", LrecSalesPricePowder."Sales Code");
                    LrecSalesPricePCI_Variant.Validate("Minimum Quantity", LrecSalesPricePowder."Minimum Quantity");
                    LrecSalesPricePCI_Variant.Validate("Unit of Measure Code", LrecItemPCI."Base Unit of Measure");
                    LrecSalesPricePCI_Variant.Validate("Starting Date", LrecSalesPricePowder."Starting Date");
                    LrecSalesPricePCI_Variant.Validate("Ending Date", LrecSalesPricePowder."Ending Date");
                    LrecSalesPricePCI_Variant.Validate("Allow Invoice Disc.", LrecSalesPricePowder."Allow Invoice Disc.");
                    LrecSalesPricePCI_Variant.Validate("Allow Line Disc.", LrecSalesPricePowder."Allow Line Disc.");
                    LrecSalesPricePCI_Variant.Validate("Price Includes VAT", LrecSalesPricePowder."Price Includes VAT");
                    LrecSalesPricePCI_Variant.Validate("Unit Price", LvCalculatedSalesPrice);
                    LrecSalesPricePCI_Variant.INSERT(TRUE);
                end;
            until LrecSalesPricePowder.Next() = 0;
    end;
    //GAP13<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    //=============================================================================================================================
    //GAP14>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    procedure fUpdateSalesPrices(PvPowder: Code[20])
    var
        LrecItemPCI: Record Item;
        LrecItemPowder: Record Item;
        LrecItemVariant: Record "Item Variant";
    begin
        LrecItemPowder.get(PvPowder);

        LrecItemVariant.SetRange(code, LrecItemPowder."No.");
        if LrecItemVariant.FindSet() then
            repeat
                if LrecItemPCI.get(LrecItemVariant."Item No.") then
                    fSetSalesPrices(LrecItemVariant);
            until LrecItemVariant.Next() = 0;
    end;
    //GAP14<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    //=============================================================================================================================
    //Event Subscribers>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    procedure fesReleaseSalesHeader(VAR SalesHeader: Record "Sales Header");
    var
    begin
        //Check the powder Level
        fCheckPowderLevel(SalesHeader);

        //Add Lot Number
        //fSetSalesItemLineTracking(SalesHeader);
    end;

    procedure fesOnInitProdLinesAfterVariantCode(var PrecProdOrderLine: Record "Prod. Order Line"; PvVariantCode: Code[20])
    var
        LrecItemVariant: Record "Item Variant";
    begin
        if LrecItemVariant.get(PrecProdOrderLine."Item No.", PvVariantCode) and (LrecItemVariant."BWA Item Variant BOM" <> '') then begin
            PrecProdOrderLine.Validate("Production BOM No.", LrecItemVariant."BWA Item Variant BOM");
        end;
    end;

    procedure fesSalesLineOnAfterValidateEvent(VAR PrecRec: Record "Sales Line"; VAR PrecxRec: Record "Sales Line")
    var
        LrecItem: Record Item;
        LrecSOH: Record "Sales Header";
    begin
        if PrecRec.Type = PrecRec.Type::Item then begin
            LrecSOH.get(PrecRec."Document Type", PrecRec."Document No.");
            LrecItem.get(PrecRec."No.");

            if PrecRec."No." <> PrecxRec."No." then begin
                PrecRec."BWA Die No." := LrecItem."BWA Die No.";
                PrecRec."BWA Extrusion Lenght" := LrecItem."BWA Lenght";
            end;

            if LrecSOH."BWA Colour Specifier" <> '' then
                PrecRec.validate("BWA Price per Sqr", LrecSOH."BWA Price per Sqr")
            else
                PrecRec."BWA Price per Sqr" := 0;

            PrecRec.CalcFields("BWA Sqr Meter Per");

            if ((PrecRec."BWA Sqr Meter Per" <> 0) and (PrecRec."BWA Price per Sqr" <> 0)) then
                PrecRec.Validate("Unit Price", PrecRec."BWA Sqr Meter Per" * PrecRec."BWA Price per Sqr");
        end;
    end;

    procedure fesOnAfterRefreshProdOrder(VAR ProductionOrder: Record "Production Order"; ErrorOccured: Boolean)
    var
    begin
        fSetProductionOrdertracking(ProductionOrder);
        fSetProdOrderColour(ProductionOrder);
    end;

    procedure fesOnAfterCreateProdOrder(VAR ProdOrder: Record "Production Order"; VAR SalesLine: Record "Sales Line")
    var
        lrecPOL: Record "Prod. Order Line";
    begin
        fSetProductionOrdertracking(ProdOrder);
        fSetProdOrderColour(ProdOrder);
    end;

    procedure fesOnAfterInitOutstandingQty(Var PrecSalesLines: Record "Sales Line")
    var
        LrecSalesLines: Record "Sales Line";
    begin
        if (LrecSalesLines.get(PrecSalesLines."Document Type", PrecSalesLines."Document No.", PrecSalesLines."Line No.")) then begin
            if LrecSalesLines.Type = LrecSalesLines.Type::Item then begin
                LrecSalesLines.calcfields("BWA Qty Collected", "BWA Qty Returned");
                if (LrecSalesLines."Document Type" = LrecSalesLines."Document Type"::Order) and
                   ((LrecSalesLines."BWA Qty Collected" = 0) and (LrecSalesLines."BWA Qty Returned" = 0)) then
                    PrecSalesLines.validate("BWA Qty to Collect", ((PrecSalesLines."Outstanding Quantity") -
                                                                (LrecSalesLines."BWA Qty Collected" - LrecSalesLines."BWA Qty Returned")
                                                                ));
            end;
        end;
    end;
    //Event Subscribers<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    //=============================================================================================================================
    //Misc>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    local procedure fCheckPowderLevel(VAR SalesHeader: Record "Sales Header")
    var
        LrecSalesOrderHeader: Record "Sales Header";
        LrecSalesOrderLines: Record "Sales Line";
        LrecItemPowder: Record Item;
        LrecItemSalesLine: Record Item;
        LrecItemVariant: Record "Item Variant";
        LrecPBOMH: Record "Production BOM Header";
        lrecPBOML: Record "Production BOM Line";
        LvExpectedQty: Decimal;
        LvTotalStockPos: Decimal;
        LvWarning: Boolean;
    begin
        LvWarning := false;
        LvExpectedQty := 0;
        if (LrecSalesOrderHeader.get(SalesHeader."Document Type", SalesHeader."No.")) and
           (LrecItemPowder.get(SalesHeader."BWA Colour Specifier")) then begin
            LrecSalesOrderLines.reset;
            LrecSalesOrderLines.SetRange("Document Type", LrecSalesOrderHeader."Document Type");
            LrecSalesOrderLines.SetRange("Document No.", LrecSalesOrderHeader."No.");
            LrecSalesOrderLines.SetRange(Type, LrecSalesOrderLines.Type::Item);
            LrecSalesOrderLines.SetFilter("No.", '<>%1', '');

            if LrecSalesOrderLines.FindSet() then
                repeat
                    LrecItemSalesLine.get(LrecSalesOrderLines."No.");
                    if LrecItemSalesLine."Item Category Code" = 'POWDER' then
                        LvExpectedQty += LrecSalesOrderLines."Qty. to Ship (Base)"
                    else
                        if (LrecItemSalesLine."Replenishment System" = LrecItemSalesLine."Replenishment System"::"Prod. Order") then begin
                            if (LrecItemVariant.get(LrecSalesOrderLines."No.", LrecSalesOrderLines."Variant Code")) and
                               (LrecItemVariant."BWA Item Variant BOM" <> '') and
                               (LrecPBOMH.get(LrecItemVariant."BWA Item Variant BOM")) then begin
                                lrecPBOML.reset;
                                lrecPBOML.SetRange("Production BOM No.", LrecPBOMH."No.");
                                lrecPBOML.SetRange(Type, lrecPBOML.type::Item);
                                lrecPBOML.SetRange("No.", LrecItemPowder."No.");
                                if lrecPBOML.FindSet() then begin
                                    repeat
                                        LvExpectedQty += (lrecPBOML."Quantity per") * LrecSalesOrderLines."Quantity (Base)";
                                    until lrecPBOML.Next() = 0;
                                end
                                else
                                    LvWarning := true;
                            end
                            else
                                LvWarning := true;
                        end;
                until LrecSalesOrderLines.Next() = 0;

            LrecItemPowder.CalcFields("Qty. on Purch. Order", Inventory, "Qty. on Sales Order", "Qty. on Component Lines");
            //LvTotalStockPos := ((LrecItemPowder."Qty. on Purch. Order" + LrecItemPowder.Inventory) -
            //                    (LrecItemPowder."Qty. on Sales Order" + LrecItemPowder."Qty. on Component Lines"));
            LvTotalStockPos := ((LrecItemPowder.Inventory) - (LrecItemPowder."Qty. on Sales Order" + LrecItemPowder."Qty. on Component Lines"));

            if (LvExpectedQty >= LvTotalStockPos) or (LvWarning) then begin
                if not Confirm('Note: There might not be enough powder %1 to cover the total demand of %2.' +
                               '\The total expected stock is %3.\' +
                               '\Would you like to continue to release the order?', true, LrecItemPowder."No.", LvExpectedQty, LvTotalStockPos) then
                    error('Document not released!');

            end;
        end;
    end;

    local procedure fSetProductionOrdertracking(PvProductionOrder: Record "Production Order")
    var
        lrecPOL: Record "Prod. Order Line";
        LrecPOC: Record "Prod. Order Component";
        LrecItem: Record Item;
    begin
        lrecPOL.reset;
        lrecPOL.SetRange(Status, PvProductionOrder.Status);
        lrecPOL.setrange("Prod. Order No.", PvProductionOrder."No.");
        LrecPOC.SetRange("Prod. Order No.", PvProductionOrder."No.");
        if lrecPOL.FindFirst() then
            repeat
                fSetProdOrderLineTracking(PvProductionOrder, lrecPOL);
                LrecPOC.SetRange("Prod. Order Line No.", lrecPOL."Line No.");
                if LrecPOC.FindFirst() then
                    repeat
                        LrecItem.get(LrecPOC."Item No.");
                        if LrecItem."Item Category Code" = 'PC ITEMS' then
                            fSetComponentLineTracking(LrecPOC, LrecPOL);
                    until LrecPOC.Next() = 0;
            until lrecPOL.Next() = 0;
    end;

    local procedure fSetProdOrderLineTracking(var PrecProdOrder: Record "Production Order"; var PrecProdOrderLine: Record "Prod. Order Line")
    var
        LrecRE: Record "Reservation Entry";
        LrecRE2: Record "Reservation Entry";
    begin
        LrecRE.reset;
        LrecRE.SetRange("Item No.", PrecProdOrderLine."Item No.");
        LrecRE.SetRange("Variant Code", PrecProdOrderLine."Variant Code");
        LrecRE.SetRange("Location Code", PrecProdOrderLine."Location Code");
        LrecRE.SetRange("Quantity (Base)", PrecProdOrderLine."Quantity (Base)");
        LrecRE.SetRange("Reservation Status", LrecRE."Reservation Status"::Reservation);
        LrecRE.SetRange("Source Type", 5406);
        LrecRE.SetRange("Source Subtype", 3);
        LrecRE.SetRange("Source ID", PrecProdOrder."No.");
        LrecRE.SetRange("Source Prod. Order Line", PrecProdOrderLine."Line No.");
        LrecRE.SetRange(Positive, true);

        if LrecRE.FindFirst() then begin
            LrecRE2.reset;
            LrecRE2.SetRange("Entry No.", LrecRE."Entry No.");
            LrecRE2.FindFirst();
            LrecRE2.ModifyAll("Lot No.", format(PrecProdOrder."Source No."), true);
        end;
    end;

    local procedure fSetComponentLineTracking(PrecPOC: Record "Prod. Order Component"; PrecPOL: record "Prod. Order Line")
    var
        LrecResEntry: Record "Reservation Entry";
        LrecPOH: Record "Production Order";
        LvEntryNo: Integer;
        LvFactor: Integer;
    begin
        LrecResEntry.reset;
        LrecPOH.get(PrecPOL.Status, PrecPOL."Prod. Order No.");

        if LrecPOH."Source Type" <> LrecPOH."Source Type"::"Sales Header" then
            exit;

        if LrecResEntry.FindLast() then
            LvEntryNo := LrecResEntry."Entry No." + 1
        else
            LvEntryNo := 1;

        LvFactor := -1;

        LrecResEntry.init;
        LrecResEntry."Entry No." := LvEntryNo;
        LrecResEntry."Reservation Status" := LrecResEntry."Reservation Status"::Surplus;
        LrecResEntry."Creation Date" := WorkDate();
        LrecResEntry."Source Type" := Database::"Prod. Order Component";
        LrecResEntry."Source Subtype" := 3;
        LrecResEntry."Source ID" := PrecPOC."Prod. Order No.";
        LrecResEntry."Source Prod. Order Line" := PrecPOC."Prod. Order Line No.";
        LrecResEntry."Source Ref. No." := PrecPOC."Line No.";

        LrecResEntry.Positive := (LvFactor = 1);
        LrecResEntry.validate("Location Code", PrecPOC."Location Code");
        LrecResEntry.Validate("Item No.", PrecPOC."Item No.");
        LrecResEntry.Validate("Variant Code", PrecPOC."Variant Code");
        LrecResEntry.Validate("Quantity (Base)", PrecPOC."Expected Qty. (Base)" * LvFactor);
        LrecResEntry.Validate(Quantity, PrecPOC."Expected Quantity" * LvFactor);
        LrecResEntry."Item Tracking" := LrecResEntry."Item Tracking"::"Lot No.";
        LrecResEntry."Lot No." := format(LrecPOH."Source No.");

        LrecResEntry.insert(true);
    end;

    local procedure fSetProdOrderColour(var PrecProductionOrder: Record "Production Order")
    var
        LrecSOH: Record "Sales Header";
        LrecItem: Record Item;
    begin
        If (PrecProductionOrder."Source Type" = PrecProductionOrder."Source Type"::"Sales Header") and
           (LrecSOH.get(LrecSOH."Document Type"::Order, PrecProductionOrder."Source No.")) and
           (LrecItem.get(LrecSOH."BWA Colour Specifier")) then begin
            PrecProductionOrder."BWA Colour Specifier" := LrecItem."No.";
            PrecProductionOrder.Modify(false);
        end;
    end;

    local procedure fTestDefaultDims(PvItemNo: code[20])
    var
        LrecDefaultDim: Record "Default Dimension";
    begin
        LrecDefaultDim.get(27, PvItemNo, 'DIVISION');
        LrecDefaultDim.TestField("Dimension Value Code");

        LrecDefaultDim.get(27, PvItemNo, 'PRODUCT LINE');
        LrecDefaultDim.TestField("Dimension Value Code");
    end;

    procedure fCalcPricing(PvItemNo: Code[20]; PvUnitPrice: Decimal; PvQty: Integer; var PvPriceSQRM: Decimal; var PvPriceLenght: Decimal): Boolean
    var
        LrecItem: Record item;
    begin
        PvPriceLenght := 0;
        PvPriceSQRM := 0;

        if not LrecItem.get(PvItemNo) or (PvQty <= 0) then
            exit(false);

        PvPriceLenght := Round((PvUnitPrice / (LrecItem."BWA Lenght" / 1000)), 0.02);
        PvPriceSQRM := round((PvUnitPrice / LrecItem."BWA Square Meter"), 0.02);
        exit(true);
    end;

    procedure fAdjustJournalItemTrackingLines(PrecItemJournal: Record "Item Journal Line"; PvNewLotNo: code[20])
    var
        LrecRE: Record "Reservation Entry";
    begin
        LrecRE.reset;
        LrecRE.setrange("Source Type", 83);
        LrecRE.setrange("Source Subtype", 6);
        LrecRE.SetRange("Reservation Status", LrecRE."Reservation Status"::Prospect);
        LrecRE.setrange("Source ID", PrecItemJournal."Journal Template Name");
        LrecRE.SetRange("Source Batch Name", PrecItemJournal."Journal Batch Name");
        LrecRE.setrange("Source Ref. No.", PrecItemJournal."Line No.");
        LrecRE.setrange("Item No.", PrecItemJournal."Item No.");
        LrecRE.setrange("Variant Code", PrecItemJournal."Variant Code");
        LrecRE.SetRange("Location Code", PrecItemJournal."Location Code");
        if LrecRE.FindFirst() then begin
            LrecRE.Validate("Quantity (Base)", PrecItemJournal."Output Quantity (Base)");
            if PvNewLotNo <> '' then
                LrecRE.Validate("Lot No.", PvNewLotNo);

            LrecRE.Modify(true);
        end;
    end;

    procedure fDeleteProdOrderLinks(PvProdOrder: Code[20])
    var
        LrecPOH: Record "Production Order";
        LrecRE: Record "Reservation Entry";
        LrecRE2: Record "Reservation Entry";
        LrecILE: Record "Item Ledger Entry";
        LrecCLE: Record "Capacity Ledger Entry";
        LrecVLE: Record "Value Entry";
        LrecWHE: Record "Warehouse Entry";
    begin
        LrecPOH.get(LrecPOH.Status::Released, PvProdOrder);

        LrecILE.reset;
        LrecILE.setrange("Order No.", Lrecpoh."No.");
        LrecILE.setrange("Order Type", LrecILE."Order Type"::Production);
        if LrecILE.FindFirst() then
            error('Entries Exist!');

        LrecCLE.reset;
        LrecCLE.setrange("Order No.", Lrecpoh."No.");
        LrecCLE.setrange("Order Type", LrecCLE."Order Type"::Production);
        if LrecCLE.FindFirst() then
            error('Entries Exist!');

        LrecVLE.reset;
        LrecVLE.setrange("Order No.", Lrecpoh."No.");
        LrecVLE.setrange("Order Type", LrecVLE."Order Type"::Production);
        if LrecVLE.FindFirst() then
            error('Entries Exist!');

        LrecWHE.reset;
        LrecWHE.setrange("Source No.", Lrecpoh."No.");
        LrecWHE.setfilter("Source Type", '%1|%2|%3', 83, 5406, 5407);
        if LrecWHE.FindFirst() then
            error('Entries Exist!');


        LrecRE.reset;
        LrecRE.SetFilter("Source Type", '%1|%2', 5406, 5407);
        LrecRE.SetRange("Source Subtype", LrecRE."Source Subtype"::"3");
        LrecRE.setrange("Source ID", LrecPOH."No.");

        if LrecRE.FindFirst() then
            repeat
                LrecRE2.setrange("Entry No.", LrecRE."Entry No.");
                If LrecRE2.FindFirst() then
                    LrecRE2.DeleteAll();
            until LrecRE.Next() = 0;
    end;

    procedure fSetSalesOrderProgress(var PrecSalesOrder: Record "Sales Header")
    var
        LrecSOL: Record "Sales Line";
        LrecItem: Record Item;
        LrecILE: Record "Item Ledger Entry";
        LrecRPOH: Record "Production Order";
        LvBusy: Boolean;
        LvAvailibleStock: Decimal;
    begin
        LrecSOL.reset;
        LrecSOL.SetRange("Document Type", PrecSalesOrder."Document Type");
        LrecSOL.SetRange("Document No.", PrecSalesOrder."No.");
        if not LrecSOL.FindFirst() then begin
            PrecSalesOrder."BWA Job Progress" := PrecSalesOrder."BWA Job Progress"::"No Job";
            PrecSalesOrder.Modify(false);
            exit;
        end;
        LrecSOL.SetRange(Type, LrecSOl.Type::Item);
        LrecSOL.SetFilter("Outstanding Quantity", '<>0');

        LrecILE.reset;
        LrecILE.SetRange(Open, true);

        LrecRPOH.reset;
        LrecRPOH.SetRange("Source Type", LrecRPOH."Source Type"::"Sales Header");

        if not LrecSOL.FindFirst() then begin
            PrecSalesOrder."BWA Job Progress" := PrecSalesOrder."BWA Job Progress"::Completed;
            PrecSalesOrder.Modify(false);
            exit;
        end
        else begin
            repeat
                LvAvailibleStock := 0;
                LrecItem.get(LrecSOL."No.");
                LrecILE.setrange("Item No.", LrecItem."No.");
                LrecILE.SetRange("Variant Code", LrecSOL."Variant Code");
                if LrecItem."Item Tracking Code" <> '' then
                    LrecILE.SetRange("Lot No.", PrecSalesOrder."No.");

                IF LrecILE.FindFirst() then begin
                    repeat
                        LvAvailibleStock += LrecILE."Remaining Quantity";
                    until LrecILE.Next() = 0;
                END;

                if LvAvailibleStock < LrecSOL."Outstanding Qty. (Base)" then
                    LvBusy := true;

            until (LrecSOL.Next() = 0) or LvBusy;

            IF LvBusy then begin
                LrecRPOH.setrange("Source No.", PrecSalesOrder."No.");

                if LrecRPOH.FindFirst() then
                    PrecSalesOrder."BWA Job Progress" := PrecSalesOrder."BWA Job Progress"::"In Progress"
                else
                    PrecSalesOrder."BWA Job Progress" := PrecSalesOrder."BWA Job Progress"::"No Job";
            END
            else
                PrecSalesOrder."BWA Job Progress" := PrecSalesOrder."BWA Job Progress"::Completed;
            PrecSalesOrder.Modify(false);
        end;
    end;
    //Misc<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    var

}
//BWA - Strategix Integration Extension
//Version: 1
//Author:  FCV
//Type:    Extension
//Object:  Report
//ID:      99000762
//NAME:    Prod.Order - Job Card

report 50102 "BWA Prod. Order - Job Card"
{
    // version NAVW113.00

    DefaultLayout = RDLC;
    //RDLCLayout = './Layouts/BWA_ProdJobCard.rdlc';
    //WordLayout = './Objects/Reports/Layouts/BWA_ProdJobCard.docx';
    ApplicationArea = Manufacturing;
    Caption = 'BWA Prod. Order - Job Card';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Production Order"; "Production Order")
        {
            DataItemTableView = SORTING (Status, "No.");
            RequestFilterFields = Status, "No.", "Source Type", "Source No.";
            column(Status_ProdOrder; Status)
            {
            }
            column(No_ProdOrder; "No.")
            {
            }
            column(BWA_Colour_Specifier; "BWA Colour Specifier")
            {
            }
            column(BWA_Colour_Description; "BWA Colour Description")
            {
            }
            column(Source_No_; "Source No.")
            {
            }
            column(Picture; CompanyInformation.Picture)
            {
            }
            column(CustomerNo; SalesHeader."Sell-to Customer No.")
            {
            }
            column(GRNDate; SalesHeader."Order Date")
            {
            }
            column(YourRef; SalesHeader."External Document No.")
            {
            }
            column(CustName; SalesHeader."Sell-to Customer Name")
            {
            }
            column(PreTreatmentCaption; PreTreatmentLbl)
            {
            }
            column(ReportTitle; ReportTitle)
            {
            }
            column(DateCapt; DateLbl)
            {
            }
            column(LongEmptyString; longEmptyStringLbl)
            {
            }
            column(PowderBatchLbl; PowderBatchLbl)
            {
            }
            column(QualityLbl; QualityLbl)
            {
            }
            column(Customer; Customer)
            {
            }
            column(AccLbl; AccLbl)
            {
            }
            column(OrdLbl; OrdLbl)
            {
            }
            column(GrnDateLbl; GrnDateLbl)
            {
            }
            column(YourOrderLbl; YourOrderLbl)
            {
            }
            column(ConfirmationTitle; ConfirmationTitle)
            {
            }
            column(JobNoLbl; JobNoLbl)
            {
            }
            column(ColourLbl; ColourLbl)
            {
            }

            dataitem("Prod. Order Line"; "Prod. Order Line")
            {
                DataItemLinkReference = "Production Order";
                DataItemLink = Status = FIELD (Status), "Prod. Order No." = FIELD ("No.");
                column(Item_No_; "Item No.")
                {

                }
                column(Quantity; Quantity)
                {

                }
                column(ItemLength; Item."BWA Lenght" / 1000)
                {

                }
                column(SqM; Item."BWA Square Meter" * Quantity)
                {
                }
                column(TMass; (Item."BWA Lenght" / 1000) * Quantity)
                {
                }
                column(DieNo; Item."BWA Die No.")
                {

                }
                column(Line_No_; "Line No." / 10000)
                {

                }
                column(Description; Description)
                {
                }
                trigger OnAfterGetRecord()
                var
                    myInt: Integer;
                begin
                    Item.get("Prod. Order Line"."Item No.");

                end;
            }


            trigger OnAfterGetRecord()
            var
                ProdOrderRoutingLine: Record "Prod. Order Routing Line";

            begin
                //ProdOrderRoutingLine.SetRange(Status, Status);
                //ProdOrderRoutingLine.SetRange("Prod. Order No.", "No.");
                //if not ProdOrderRoutingLine.FindFirst then
                //    CurrReport.Skip;
                CompanyInformation.get;
                CompanyInformation.CalcFields(Picture);
                SalesHeader.Reset();
                SalesHeader.SetRange("No.", "Production Order"."Source No.");
                if SalesHeader.FindFirst() then
                    YourReferenceNo := SalesHeader."External Document No."
                else
                    YourReferenceNo := '';

            end;

            trigger OnPreDataItem()
            begin
                ProdOrderFilter := GetFilters;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        ProdOrderFilter: Text;
        CapacityUoM: Code[10];
        CurrReportPageNoCaptionLbl: Label 'Page';
        ProdOrderJobCardCaptionLbl: Label 'Prod. Order - Job Card';
        ProdOrderRtngLnStrtDtCaptLbl: Label 'Starting Date';
        ProdOrdRtngLnEndDatCaptLbl: Label 'Ending Date';
        ProdOrdRtngLnExpcCapNdCptLbl: Label 'Time Needed';
        PrecalcTimesCaptionLbl: Label 'Precalc. Times';
        ProdOrderSourceNoCaptLbl: Label 'Item No.';
        OutputCaptionLbl: Label 'Output';
        ScrapCaptionLbl: Label 'Scrap';
        DateCaptionLbl: Label 'Date';
        ByCaptionLbl: Label 'By';
        PreTreatmentLbl: Label 'Pre-Treatment Sign off:';
        ReportTitle: Label 'Job Card';
        DateLbl: Label 'Date: _____________';
        longEmptyStringLbl: Label '____________________________________________';
        PowderBatchLbl: Label 'Powder Batch';
        QualityLbl: Label 'Quality Controller Sign off:';
        Customer: Label 'CUSTOMER:';
        AccLbl: Label 'ACCOUNT NUMBER:';
        OrdLbl: Label 'ORDER NUMBER:';
        GrnDateLbl: Label 'GRN DATE:';
        YourOrderLbl: Label 'YOUR ORDER NO:';
        ConfirmationTitle: Label '(Order Confirmation)';
        JobNoLbl: Label 'JOB NO:';
        ColourLbl: Label 'COLOUR';
        EmptyStringCaptionLbl: Label '___________';
        MaterialRequirementsCaptLbl: Label 'Material Requirements';
        Item: Record Item;
        CompanyInformation: Record "Company Information";
        YourReferenceNo: Code[20];
        SalesHeader: Record "Sales Header";
}


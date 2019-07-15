//BWA - Strategix Integration Extension
//Version: 1
//Author:  FCV
//Type:    Custom
//Object:  Query
//ID:      50151
//NAME:    BWA Powder Items

query 50151 "BWA Powder Items"
{
    QueryType = API;
    APIPublisher = 'BWA';
    APIGroup = 'BWASTXIntegration';
    APIVersion = 'v1.0';
    EntityName = 'Powder';
    EntitySetName = 'Powders';

    elements
    {
        dataitem(ITEMS; Item)
        {
            DataItemTableFilter = "Item Category Code" = filter ('POWDER');
            column(No; "No.")
            { }
            column(Description; Description)
            { }
            column(Inventory; Inventory)
            { }
            column(QtyPurchOrder; "Qty. on Purch. Order")
            { }
            column(QtySalesOrder; "Qty. on Sales Order")
            { }
            column(QtyComponentLines; "Qty. on Component Lines")
            { }

            //filter(FilterName; SourceFieldName)
            //{}
        }
    }

    var

    trigger OnBeforeOpen()
    begin

    end;
}

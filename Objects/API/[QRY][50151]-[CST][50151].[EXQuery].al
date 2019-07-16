// - Strategix Integration Extension
//Version: 1
//Author:  CS
//Type:    Custom
//Object:  Query
//ID:      50151
//NAME:    Example Query

query 50151 "Example Query"
{
    QueryType = API;
    APIPublisher = '';
    APIGroup = '';
    APIVersion = 'v1.0';
    EntityName = '';
    EntitySetName = '';

    elements
    {
        dataitem(ITEMS; Item)
        {
            DataItemTableFilter = "Item Category Code" = filter ('');
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

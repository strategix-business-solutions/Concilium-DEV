// - Strategix Integration Extension
//Version: 1
//Author:  CS
//Type:    Extension
//Object:  Table
//ID:      27
//NAME:    Items

tableextension 50205 "Example Item Extension" extends Item
{
    fields
    {
        field(50000; "BWA Die No."; code[10])
        {
            TableRelation = "BWA Die Register"."Die No.";

            trigger OnValidate()
            var
                LcuBWAmngt: Codeunit "BWA Management";
            begin
                //Convert to M
                "BWA Square Meter" := (LcuBWAmngt.fCalcSquareArea("BWA Lenght", "BWA Die No."));
            end;
        }
        field(50001; "BWA Lenght"; Integer)
        {
            trigger OnValidate()
            var
                LcuBWAmngt: Codeunit "BWA Management";
            begin
                //Convert to M
                "BWA Square Meter" := (LcuBWAmngt.fCalcSquareArea("BWA Lenght", "BWA Die No."));
            end;
        }
        field(50002; "BWA Square Meter"; Decimal)
        {
        }

        field(50003; "BWA Coverage per KG"; Decimal)
        {
            trigger Onvalidate()
            var
                LrecIUOM: Record "Item Unit of Measure";
                LrecUOM: Record "Unit of Measure";
            begin
                LrecUOM.get('SQM');
                if LrecIUOM.get("No.", LrecUOM.Code) then begin
                    LrecIUOM.validate("Qty. per Unit of Measure", (1 / "BWA Coverage per KG"));
                    LrecIUOM.Modify(true);
                end
                else begin
                    LrecIUOM.init;
                    LrecIUOM.validate("Item No.", "No.");
                    lreciuom.validate(Code, LrecUOM.Code);
                    LrecIUOM.Validate("Qty. per Unit of Measure", (1 / "BWA Coverage per KG"));
                    LrecIUOM.insert(true);
                end;

            end;
        }

        field(50004; "BWA Stocked Metal Code"; Code[20])
        {
            TableRelation = Item."No." where ("Item Category Code" = filter ('STOCKING'), Blocked = const (false));
            ValidateTableRelation = true;
        }
    }



    var
}
//BWA - Strategix Integration Extension
//Version: 1
//Author:  FCV
//Type:    Extension
//Object:  Page
//ID:      99000867
//NAME:    Finished Production Order
//GAP1

pageextension 50105 "BWA Finished Prod Order" extends "Finished Production Order"
{
    layout
    {
        addafter(General)
        {
            group("Powder Coating")
            {
                field("BWA Colour Specifier"; "BWA Colour Specifier")
                {
                }
                field("BWA Colour Description"; "BWA Colour Description")
                {
                }
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var

}

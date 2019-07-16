// - Strategix Integration Extension
//Version: 1
//Author:  CS
//Type:    Extension
//Object:  Page
//ID:      99000867
//NAME:    Example Page Extension
//GAP1

pageextension 50105 "Example Page Extension" extends "Finished Production Order"
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

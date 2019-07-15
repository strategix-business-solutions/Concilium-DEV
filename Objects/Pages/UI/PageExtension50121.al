pageextension 50121 PageExtension50121 extends "Purchase Order List"
{
  layout
  {
    modify("Assigned User ID")
    {
    Visible = false;
    }
    modify("Vendor Authorization No.")
    {
    Visible = false;
    }
  }
}

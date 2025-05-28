UPDATE SERIES_SETUP_MST SET igst_fr_xn_prefix=igst_xn_prefix WHERE ISNULL(igst_fr_xn_prefix,'')=''
UPDATE SERIES_SETUP_MST SET cgst_fr_xn_prefix=cgst_xn_prefix WHERE ISNULL(cgst_fr_xn_prefix,'')=''
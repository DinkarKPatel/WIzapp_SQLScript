DELETE a from GST_ACCOUNTS_CONFIG_DET_REVENUE A JOIN GST_ACCOUNTS_CONFIG_DET_REVENUE b on a.gst_percentage=b.gst_percentage
and a.xn_type=b.xn_type
where a.section_code='' and b.section_code='0000000'
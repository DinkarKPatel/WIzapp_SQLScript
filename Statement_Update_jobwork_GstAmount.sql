	UPDATE A SET Total_Gst_Amount=b.Gst_amount
		FROM JOBWORK_RECEIPT_MST A (nolock)
		join
		(
		   SELECT receipt_id,
				  sum(isnull(igst_amount,0)+isnull(cgst_amount,0)+isnull(sgst_amount,0)) as Gst_amount
		    from JOBWORK_RECEIPT_DET 
		   GROUP BY  receipt_id 
		) B ON A.receipt_id =B.receipt_id
          WHERE A.cancelled  =0
		  and isnull(Total_Gst_Amount,0)<>isnull(b.Gst_amount,0)
    
UPDATE A SET XN_ID=B.MRR_ID FROM XNRECONMEMO A
JOIN PIM01106 B ON A.XN_ID=B.INV_ID 
JOIN XNRECONM C ON C.RECON_ID=A.RECON_ID
WHERE C.XN_TYPE='PUR' AND B.INV_MODE=2

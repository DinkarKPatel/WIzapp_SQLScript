--- Merged it after confirmation by Anil that he made changes in Article and Uom master to synch this column on saving ofthese masters (Ticket#0523-00024)
update a set discon=b.uom_type from article a join uom b on a.uom_code=b.uom_code
where a.discon<>b.uom_type



IF OBJECT_ID('chk_article_no','C') IS NOT NULL	
ALTER TABLE article DROP CONSTRAINT chk_article_no

IF OBJECT_ID('chk_subsection_name','C') IS NOT NULL	
ALTER TABLE SECTIOND DROP CONSTRAINT chk_subsection_name

IF OBJECT_ID('chk_section_name','C') IS NOT NULL	
ALTER TABLE SECTIONM DROP CONSTRAINT chk_section_name

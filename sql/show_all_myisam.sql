SELECT Concat('ALTER TABLE ', table_schema, '.', table_name, ' engine=INNODB;') 
       AS 
       '===== MyISAM Tables without FULLTEXT indexes =====' 
FROM   information_schema.tables 
WHERE  engine = 'MyISAM' 
       AND table_schema <> 'mysql' 
       AND table_schema <> 'information_schema' 
       AND Concat(table_schema, '.', table_name) NOT IN 
           (SELECT 
           Concat(table_schema, '.', table_name) 
                                                         FROM 
               information_schema.statistics 
                                                         WHERE 
           index_type = 'fulltext'); 

SELECT Concat(table_schema, '.', table_name) AS 
       '===== MyISAM Tables with FULLTEXT indexes =====' 
FROM   information_schema.tables 
WHERE  engine = 'MyISAM' 
       AND table_schema <> 'mysql' 
       AND table_schema <> 'information_schema' 
       AND Concat(table_schema, '.', table_name) IN (SELECT 
           Concat(table_schema, '.', table_name) 
                                                     FROM 
           information_schema.statistics 
                                                     WHERE 
           index_type = 'fulltext'); 

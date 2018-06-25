-- We will do that with sp_fulltext_database procedure
EXEC sp_fulltext_database 'enable'

-- determins if full text search is installed
SELECT FULLTEXTSERVICEPROPERTY('IsFullTextInstalled')
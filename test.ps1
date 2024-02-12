echo "-- New file" > c:\Anshul\datamigration\step1_createschemascript2.sql

# CREATE SCHEMA
./sfdatamigration.ps1 -configFilePath ./config.json -actionsFilePath  ./schemaactions.json -sfenv AI

# EXTRACT DATA FROM SOURCE SF to local DB
./sfdatamigration.ps1 -configFilePath ./config.json -actionsFilePath ./dataexport.json -sfenv AI

# EXPORT Data from Local DV and Load into Target SF
./sfdatamigration.ps1 -configFilePath ./config.json -actionsFilePath ./dataload.json -sfenv SF_LEARN
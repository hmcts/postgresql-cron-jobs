
#Summary

This repo contains database extracts from various databases to fulfil business requirements. 
Reports are either sent as an email attachment or uploaded to an Azure storage based on their size.
Two seperate Azure pipelines are created to cover **`daily`** and  **`Weekly`** reports which run on a corn schedule.


## Service Connection
Service connections enable you to connect to Azure tenant(s) to execute tasks in a job. It uses service Principal to authenticate to the tenant.
    
    DTS Production Database Reporting

## Storage Account
   Some of the reports are very large and above the recommended size limit of sendgrid(SMTP) attachment. As a work around, any reports greater than 9MB in size will be upload to an storage account.
   Access key for the storage account is stored in keyvault. 
      
       Storage account: timdaexedata
       Container: Weeklies       #For Weekly reports
       Container: Daily          #For Daily reports
       KeyVault: ccd-prod

## Testing

   It is recommended to run the pipelines against a branch, by editing corresponding pipeline file. Please note, some of the reports can cause database performance issues when run during business hours.
# Azure Open AI Report

[AOAIReport.pbit](AOAIReport.pbit) is a sample Power BI report template that queries the data from Cosmos DB. You can change the data source as you need.

## Data source

[Log Parser](/LogParser) stores the log into Application Insights and Cosmos DB by default. We provide the example queries and Power BI report template as a starting point.

## Queries

You can find query samples in [queries](/queries/) directory where we provide two samples.

- Cosmos DB: [query.sql](/queries/query.sql)
- Application Insights: [query.kql](/queries/query.kql)

Both queries return the similar results that can be used to create Power BI reports.

### Cosmos DB

1. Go to the Cosmos DB instance.
1. Open the Data Explorer, then select the database and collection.
1. Click new query and paste query.
1. Execute the query to see the result.

The sample query doesn't consider any performance and cost optimizations for now.

### Application Insights

1. Go to the Application Insight account.
1. Click Logs and paste the query.
1. Execute the query and see the result.


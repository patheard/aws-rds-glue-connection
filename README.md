# AWS RDS Glue connection
Simple setup showing how to connect a Glue job to an RDS instance in the private subnets of a VPC.

```sh
cd terraform
terraform init
terraform apply
```

## Populate test data
Enable the RDS data API and use the query editor to create and populate a test table:

```sql
CREATE TABLE template (
    name VARCHAR(255),
    description VARCHAR(255)
);

INSERT INTO template (name, description) VALUES 
('Project Plan', 'Standard template for project documentation'),
('Meeting Agenda', 'Structured template for team meetings'),
('Budget Report', 'Financial reporting template'),
('Training Manual', 'Employee onboarding and skill development guide'),
('Marketing Strategy', 'Comprehensive marketing plan framework');
```
The VPC here is configured not to use a transit gateway, since one won't exist in Localstack where we run tests. `transit_gateway_enabled` defaults to true, so you can omit it in your usage (if you use TGW).

> [!WARNING] Limited Testing Scope
> Many of the resources are commented out in this example due to lack of support in Localstack (and creating things like VPCs and RDS in AWS is prohibitively expensive in terms of time and money). When changing these resources, it's a good idea to do a `terraform apply` in AWS for real world testing.

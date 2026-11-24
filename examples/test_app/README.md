The VPC here is configured not to use a transit gateway, since one won't exist in Ministack where we run tests. `transit_gateway_enabled` defaults to true, so if you use TGW you can omit it in your usage.

DynamoDB autoscaling is disabled for the same reason: Ministack doesn't implement the Application Auto Scaling API, so `RegisterScalableTarget` fails with a 400. `autoscaling_enabled` defaults to true, so omit it in your usage.

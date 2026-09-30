output "cluster_name" { value = module.eks.cluster_name }
output "ecr_repository_url" { value = aws_ecr_repository.app.repository_url }
output "rds_endpoint" { value = aws_db_instance.postgres.address }
output "vpc_id" { value = module.vpc.vpc_id }

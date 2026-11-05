sed -i 's|\./nginx-local/|./nginx-release/|g' docker-compose.full.postgres.yml
sed -i 's|\./nginx-local/|./nginx-release/|g' docker-compose.full.mongo.yml

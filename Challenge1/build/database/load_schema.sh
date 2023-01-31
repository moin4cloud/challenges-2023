PROJECT=$1
SQLNAME=$2

echo "creating a storage bucket for copying the schema sql file"
gsutil mb gs://$PROJECT-demo-app
gsutil cp schema.sql gs://$PROJECT-demo-app/schema.sql

SQL_SERVICE_ACCOUNT=$(gcloud sql instances describe $SQLNAME --format="value(serviceAccountEmailAddress)" | xargs)
gsutil iam ch serviceAccount:$SQL_SERVICE_ACCOUNT:objectViewer gs://$PROJECT-demo-app/
gcloud sql import sql $SQLNAME gs://$PROJECT-demo-app/schema.sql -q
echo "schema file imported on Cloud SQL successfully"

### Cleaning up of GCS resources
gsutil rm gs://$PROJECT-demo-app/schema.sql
gsutil rb gs://$PROJECT-demo-app
bucketName=$1
tableName=$2
region=$3

bucketstatus=$(aws s3api head-bucket --bucket $bucketName --region $region  2>&1)
if echo "${bucketstatus}" | grep -q 'Not Found';
then
  bucket=$(aws s3api create-bucket --bucket $bucketName --region $region 2>&1)
  echo "${bucket}";
fi

tablestatus=$(aws dynamodb describe-table --table-name $tableName --region $region 2>&1)
if echo "${tablestatus}" | grep -q 'not found';
then
  table=$(aws dynamodb create-table --table-name $tableName --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 --region $region 2>&1)
  echo "${table}";
fi

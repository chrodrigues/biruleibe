#!/bin/bash
# backup settings and prefix
BUCKET="abcd"
PREFIX="bucket/path/file/"
CUSTOMER="client"
DESTINATION_BUCKET="destination-bucket"

# List of files to be moved
FILES_LIST=$(aws s3api list-objects-v2 \
  --bucket "$BUCKET" \
  --prefix "$PREFIX" \
  --query "Contents[?LastModified >= '2023-10-23T00:00:00Z' && LastModified <= '2024-10-23T23:59:59Z'].Key" \
  --output text)

# go trought list of files
for FILE in $FILES_LIST; do
  FILE_NAME=$(basename "$FILE") # extract only file name
  echo "Moving file: $FILE"

  # try to move the file
  aws s3 mv "s3://$BUCKET/$FILE" "s3://$DESTINATION_BUCKET/$FILE_NAME"
  if [ $? -eq 0 ]; then
    echo "File $FILE successfully moved."
  else
    echo "Failed to move $FILE. Trying again..."
    aws s3 mv "s3://$BUCKET/$FILE" "s3://$DESTINATION_BUCKET/$FILE_NAME"
    if [ $? -eq 0 ]; then
      echo "File $FILE successfully moved."
    else
      echo "Error again moving file $FILE."
    fi
  fi
done


################## permission requirements ##################

######################################## bucket permission
#####        {
#####            "Version": "2012-10-17",
#####            "Statement": [
#####                {
#####                    "Effect": "Allow",
#####                    "Principal": {
#####                        "AWS": [
#####                            "arn:aws:iam::896492669044:user/user"
#####
#####                        ]
#####                    },
#####                    "Action": [
#####                        "s3:ListBucket",
#####                        "s3:*"
#####                    ],
#####                    "Resource": "arn:aws:s3:::bucket-name"
#####                }
#####            ]
#####        }


######################################## policy permission

#####       {
#####           "Version": "2012-10-17",
#####           "Statement": [
#####               {
#####                   "Sid": "VisualEditor0",
#####                   "Effect": "Allow",
#####                   "Action": [
#####                       "s3:PutObject",
#####                       "s3:GetObject"
#####                   ],
#####                   "Resource": [
#####                       "arn:aws:s3:::bucket-name/*"
#####                   ]
#####               }
#####           ]
#####       }
BUCKET_NAME ?= default
BUCKET_ACL ?= private

aws := aws --endpoint=$(ENDPOINT)

deploy:
	$(aws) s3 ls
	$(aws) s3api head-bucket --bucket=$(BUCKET_NAME) || \
		$(aws) s3api create-bucket \
			--bucket=$(BUCKET_NAME) \
			--acl=$(BUCKET_ACL)

undeploy:
	- $(aws) s3api delete-bucket --bucket=$(BUCKET)

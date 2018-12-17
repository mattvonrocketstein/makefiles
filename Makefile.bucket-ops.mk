bucket-encrypt: assert-bucket assert-AWS_PROFILE
	aws s3api put-bucket-encryption \
	--bucket $$bucket \
	--server-side-encryption-configuration '\
	{"Rules": [{"ApplyServerSideEncryptionByDefault": \
	{"SSEAlgorithm": "AES256"}}]}'

# requires `pip install hurry.filesize` and `pip install s4cmd`
bucket-size: assert-bucket assert-AWS_PROFILE
	# compute root folder sizes
	s4cmd du -r s3://$(value bucket) > .tmp.bucket
	# sum subtotals and add line for total
	echo $$(cat .tmp.bucket | awk '{print $$1}' | tr '\n' '+')0 \
	| bc | xargs -I% echo % Total \
	>> .tmp.bucket
	# convert to human-readable sizes
	cat .tmp.bucket \
	| python -c'\
	import sys; from hurry.filesize import size; \
	tmp=[x.strip().split() for x in sys.stdin.readlines()]; \
	tmp=["{} {}".format(size(int(x[0])),x[1]) for x in tmp]; \
	print "\n".join(tmp)'
	@rm .tmp.bucket

bucket-list:
	@aws s3api list-buckets --query 'Buckets[*].Name'|jq -r .[]

bucket-restore: assert-bucket assert-AWS_PROFILE
	aws s3 ls --human-readable --summarize --recursive s3://$(value bucket); \
	aws s3 sync s3://$(value AWS_PROFILE)-backups/$(value bucket)/ s3://$(value bucket)/ ; \
	aws s3 ls --human-readable --summarize --recursive s3://$(value AWS_PROFILE)-backups/$(value bucket)/

bucket-backup-delete: assert-bucket assert-AWS_PROFILE
	aws s3 rm --recursive s3://$(value AWS_PROFILE)-backups/$(value bucket)

bucket-backup: assert-bucket assert-AWS_PROFILE
	# compute size of src bucket
	make bucket-size
	aws s3 sync s3://$(value bucket)/ s3://$(value AWS_PROFILE)-backups/$(value bucket)/
	# compute size of dest bucket/prefix
	bucket=$(value AWS_PROFILE)-backups/$(value bucket) make bucket-size

bucket-clean: assert-bucket assert-AWS_PROFILE
	aws s3 rm --recursive s3://$(value bucket)
	python -c"\
	import os, boto3; \
	s3 = boto3.resource('s3'); \
	bucket = s3.Bucket(os.environ['bucket']); \
	bucket.object_versions.delete();"

bucket-rm: assert-bucket assert-AWS_PROFILE
	aws s3api delete-bucket --bucket $(value bucket)

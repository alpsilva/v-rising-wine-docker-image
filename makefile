stack_name = VRisingServerStack
default_vpc_id = vpc-0d94037e30dc9809a
# Change to your created instance public IP and key pair id.
ec2_public_ip = 177.71.192.122
key_pair_id = key-079052180a7c17723
 
create-stack:
	@aws cloudformation create-stack \
	--stack-name $(stack_name) \
	--template-body file://cloudformation-template.yaml \
	--parameters ParameterKey=KeyName,ParameterValue=VRisingServerKey \
	--capabilities CAPABILITY_IAM

download-keypair:
	@aws ssm get-parameter \
	--name /ec2/keypair/$(key_pair_id) \
	--with-decryption \
	--query Parameter.Value \
	--output text > VRisingServerKey.pem
	sudo chmod 400 VRisingServerKey.pem

setup-stack:
	ssh -i "VRisingServerKey.pem" ec2-user@$(ec2_public_ip) "\
	sudo yum update -y && \
	sudo yum install git -y && \
	sudo yum install docker -y && \
	sudo service docker start && \
	sudo chkconfig docker on && \
	sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose && \
	sudo chmod +x /usr/local/bin/docker-compose"

delete-stack:
	@aws cloudformation delete-stack --stack-name $(stack_name)

deploy:
	ssh -i "VRisingServerKey.pem" ec2-user@$(ec2_public_ip) "\
	git clone https://github.com/alpsilva/v-rising-wine-docker-image.git && \
	cd v-rising-wine-docker-image/server/ && \
	mkdir saves"
	scp -i VRisingServerKey.pem ./server/.env ec2-user@$(ec2_public_ip):~/v-rising-wine-docker-image/server/.env

start:
	ssh -i "VRisingServerKey.pem" ec2-user@$(ec2_public_ip) "\
	cd v-rising-wine-docker-image/server/ && \
	sudo docker-compose up -d"

stop:
	ssh -i "VRisingServerKey.pem" ec2-user@$(ec2_public_ip) "\
	cd v-rising-wine-docker-image/server/ && \
	sudo docker-compose down"
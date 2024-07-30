provider "aws" {  
  region = "us-east-1"
 
  

}




variable "region" {
    type = string
  default = "us-east-1"
}
variable "keyname" {
    type = string
  
}

variable "ami_id" {
  type = map
  default = {
    us-east-1    = "ami-0a0e5d9c7acc336f1"
    us-west-2    = "ami-0a0e5d9c7acc336f1"
    eu-central-1 = "ami-0a0e5d9c7acc336f1"
  }
}

terraform {
  backend "s3" {
      region = "us-east-1"
     bucket = "tfstateb1lab"
     dynamodb_table = "tflcktable"     
     key = "jenkins.tfstate"
    
  }
}

resource "aws_key_pair" "tf-key-pair" {
key_name = var.keyname
public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
algorithm = "RSA"
rsa_bits  = 4096
}
resource "local_file" "tf-key" {
content  = tls_private_key.rsa.private_key_pem
filename = var.keyname
}

resource "aws_instance" "web-server" {
  ami           = "${lookup(var.ami_id, var.region)}"
  instance_type = "t2.micro"
  key_name      = var.keyname


 
  provisioner "remote-exec" {
      inline = [
        "sudo apt-get update",
		"sudo apt install -y openjdk-11-jre-headless",
		"sudo apt install -y tomcat9",
		"sudo rm -fr /var/lib/tomcat9/webapps/ROOT"
        
        
      ]
    }
	
 provisioner "file" {
    source      = "../target/japp1.war"
    destination = "/var/lib/tomcat9/webapps/ROOT.war"
  }
  connection {
    user        = "ubuntu"
    private_key = "${file(local_file.tf-key.filename)}"
      host = "${aws_instance.web-server.public_ip}"
  }
}

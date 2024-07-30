provider "aws" {  
  region = "us-east-1"
}


variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

variable "region" {
    type = string
  default = "us-east-1"
}
variable "private_key_path" {
    type = string
  default = "ntskey.pem"
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



resource "aws_instance" "web-server" {
  ami           = "${lookup(var.ami_id, var.region)}"
  instance_type = "t2.micro"
  key_name      = "ntskey"


 
  provisioner "remote-exec" {
      inline = [
        "sudo apt-get update",
		"sudo apt install -y openjdk-11-jre-headless",
		"sudo apt install -y tomcat9 tomcat9-admin"
        
        
      ]
    }
	
	 provisioner "file" {
    source      = ./targets/*.war
    destination = "/tmp/index.html"
  }
  connection {
    user        = "ubuntu"
    private_key = "${file("${var.private_key_path}")}"
      host = "${aws_instance.web-server.public_ip}"
  }
}

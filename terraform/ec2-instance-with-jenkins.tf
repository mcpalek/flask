data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] 
}

resource "aws_instance" "flaskapp-host" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  key_name 	  = aws_key_pair.deployer-with-ssh.key_name
  security_groups = [aws_security_group.ubuntu.name]
  associate_public_ip_address = true

  provisioner "remote-exec" {
    inline = [  
      #"echo Inastalling jeknins",
      #"wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -",
      #"sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ >/etc/apt/sources.list.d/jenkins.list'",
      #"sudo apt-get update",
      #"sudo apt-get install jenkins",
      #"touch file"
	"sudo add-apt-repository universe",
      "sudo apt-get -f install",
      "sudo apt install net-tools",
      "curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl",
      "sudo chmod +x ./kubectl",
      "sudo mv ./kubectl /usr/local/bin/kubectl",
      "sudo apt install awscli -y",
      "wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -",
      "sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'",
      "sudo apt update -qq",
      "sudo apt install -y default-jre",
      "sudo apt install -y jenkins",
      "sudo systemctl start jenkins",
      "sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080",
      "sudo sh -c \"iptables-save > /etc/iptables.rules\"",
      "echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections",
      "echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections",
      "sudo apt-get -y install iptables-persistent",
      "sudo ufw allow 8080"
	]
  }
	
   connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("~/quickstart.pem")
  }
  tags = {
     Name = "ec-2-Jenkins"
  }
}

# --- Association with key in order to ssh --- 
resource "aws_key_pair" "deployer-with-ssh" {
  key_name   = var.key_name
  public_key = file("~/.ssh/authorized_keys")
}
# --- Security group --- 
resource "aws_security_group" "ubuntu" {
  name        = "ubuntu-security-group"
  description = "Allow HTTP, HTTPS and SSH traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

#output "public_ip" {
# value = aws_instance.public_ip
#}

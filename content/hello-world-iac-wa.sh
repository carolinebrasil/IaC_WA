#!/bin/bash
# Use this for your user data (script from top to bottom)
# install httpd (Linux 2 version)
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello World IaC Well Architected! ---Ec2 $(hostname -f)--- </h1>" > /var/www/html/index.html

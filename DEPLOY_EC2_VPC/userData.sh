#!/bin/bash
yum update -y
yum install httpd -y
echo "<html><h1>webpage 1(Hello! Welcome to your next favourite spot on the net!)</h1></html>" > /var/www/html/index.html
service httpd start
chkconfig httpd on

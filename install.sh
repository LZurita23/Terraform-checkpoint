#! /bin/bash
sudo yum update -y
sudo yum install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd
echo "The page was created by the user-data" | sudo tee /var/www/html/index.html
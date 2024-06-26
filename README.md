# Automate Terraform with GitHub Actions


• Evidence the proper function of the infrastructure
Discuss your approach to the build out, including challenges and adaptations
• Detail your grasp of weak configurations and their potential consequences
• Demonstrate the value of the security tool in reducing risk



Database Server Configuration
• Create a Linux EC2 instance on which a database server is installed (e.g. MongoDB)
• Configure the database with authentication so you can build a database connection string
• Allow DB traffic to originate only from your VPC
• Configure the DB to regularly & automatically backup to your exercise S3 Bucket
• Configure an instance profile to the VM and add the permission “ec2:*” as a custom
policy
• Configure a security group to allow SSH to the VM from the public internet
Web Application Configuration
• Create an EKS cluster instance in the same VPC as your database server
• Build and host a container image for your web application*
• Ensure your built container image contains an arbitrary file called “wizexercise.txt” with
some content
• Deploy your container-based web application to the EKS cluster
• Ensure your web application authenticates to your database server (connection strings
are a common approach)
• Allow public internet traffic to your web application using service type loadbalancer
• Configure your EKS cluster to grant cluster-admin privileges to your web application
container(s)
*Need a containerized app which will talk to your database server? Write your own, grab one of
the many open-source options, or try: https://github.com/jeffthorne/tasky
S3 Bucket Configuration
• Create an S3 Bucket to hold your database backups
• Configure your bucket such that the public can read and download objects from it
AWS Config
• Activate and ensure AWS Config covers your environment
• Ensure AWS Config detects one or more misconfigurations you can review in your
presentation, introducing novel misconfigurations if necessary

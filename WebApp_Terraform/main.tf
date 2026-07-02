resource "aws_vpc" "myvpc"{
cidr_block = "10.0.0.0/16"
instance_tenancy = "default"

  tags = {
    Name = "murthy_vpc"
  }
}


resource "aws_subnet" "mysub1"{
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

}

resource "aws_subnet" "mysub2"{
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "murthyigw"
  }
}


resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.myvpc.id

  
  route {
  gateway_id = aws_internet_gateway.igw.id
  cidr_block = "0.0.0.0/0"
  }
}

 resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.mysub1.id
  route_table_id = aws_route_table.rt.id
} 

 resource "aws_route_table_association" "rta1" {
   subnet_id  = aws_subnet.mysub2.id
   route_table_id = aws_route_table.rt.id
}

 resource "aws_security_group" "sg" {
  vpc_id      = aws_vpc.myvpc.id
   name = "websg"

  ingress {

   cidr_blocks = ["0.0.0.0/0"]
   from_port = 80
   to_port  = 80
   protocol = "tcp"
  }
  ingress {
 
  cidr_blocks = ["0.0.0.0/0"]
  from_port = 22
  to_port = 22
  protocol = "tcp"
  }

  egress {

  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "insta"{

tags = {
 Name = "murthyinsta"

}

ami = "ami-0b6d9d3d33ba97d99"

instance_type = "t2.micro"
vpc_security_group_ids = [aws_security_group.sg.id]
subnet_id = aws_subnet.mysub1.id
user_data = base64encode(file("userdata1.sh"))

}

resource "aws_instance" "insta2"{

  tags = {
    Name = "murthyve1"
  }
ami = "ami-0b6d9d3d33ba97d99"
instance_type = "t2.micro"
vpc_security_group_ids = [aws_security_group.sg.id]
subnet_id = aws_subnet.mysub2.id
user_data = base64encode(file("userdata2.sh"))
}

resource "aws_lb" "mylb"{
  name = "myalb"
  internal = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.sg.id]
  subnets = [aws_subnet.mysub1.id, aws_subnet.mysub2.id]

  tags = {
    Name = "my_alb"
  }
}

 resource "aws_lb_target_group" "target" {
  name     = "myapptargetgroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id  
}

  resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.target.arn
  target_id        = aws_instance.insta.id
  port             = 80
}

  resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.target.arn
  target_id        = aws_instance.insta2.id
  port             = 80
}

  resource "aws_alb_listener" "murthy"{
   load_balancer_arn = aws_lb.mylb.arn
  port              = 80
  protocol          = "HTTP"


  default_action {
     type       = "forward"
    target_group_arn = aws_lb_target_group.target.arn
  }
}

  output "loadbalancerdns"{
    value = aws_lb.mylb.dns_name
  }

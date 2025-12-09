resource "aws_vpc" "main" {
	cidr_block           = "10.0.0.0/16"
	enable_dns_support   = true
	enable_dns_hostnames = true
	tags = {
		Name = "test-cluster-vpc"
	}
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "test-cluster-igw"
  }
}

resource "aws_subnet" "public" {
  for_each = toset(["us-east-1a", "us-east-1b"])
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value == "us-east-1a" ? "10.0.1.0/24" : "10.0.2.0/24"
  availability_zone       = each.value
  map_public_ip_on_launch = true
  tags = {
    Name = "test-cluster-public-${each.value}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "test-cluster-public-rt" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}




resource "aws_vpc" "a_dummy_vpc" {
  
  cidr_block = "10.0.0.0/24"
  
  tags = {
    resource_identifier_for_turbo_firefly = "turbo_firefly_a_dummy_vpc"
    Name = "a_dummy_vpc"
  }
}

resource "aws_internet_gateway" "extra_gateway" {

  tags = {
    Name = "extra_gateway"
  }
}
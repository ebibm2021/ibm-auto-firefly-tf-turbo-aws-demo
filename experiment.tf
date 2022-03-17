
resource "aws_vpc" "a_dummy_vpc" {
  
  cidr_block = "10.0.0.0/24"
  
  tags = {
    resource_identifier_for_turbo_firefly = "turbo_firefly_a_dummy_vpc"
    Name = "a_dummy_vpc"
  }
}

resource "aws_vpc" "yet_another_dummy_vpc" {
  
  cidr_block = "10.0.0.0/24"
  
  tags = {
    resource_identifier_for_turbo_firefly = "turbo_firefly_yet_another_dummy_vpc"
    Name = "yet_another_dummy_vpc"
  }
}

resource "aws_internet_gateway" "extra_gateway" {

  tags = {
    Name = "extra_gateway"
  }
}

resource "aws_internet_gateway" "another_extra_gateway" {

  tags = {
    Name = "another_extra_gateway"
  }
}

resource "aws_internet_gateway" "yet_another_extra_gateway" {

  tags = {
    Name = "yet_another_extra_gateway"
  }
}
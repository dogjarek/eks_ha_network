resource "aws_nat_gateway" "eks_nat_gateway" {
  count         = "${var.number_of_nat_gateways != "" ? var.number_of_nat_gateways : 0}"
  allocation_id = "${element(aws_eip.eks_nat_gw.*.id, count.index)}"
  subnet_id     = "${element(values(zipmap(aws_subnet.eks_vpc_public_subnets.*.availability_zone, aws_subnet.eks_vpc_public_subnets.*.id)), count.index)}"
  tags          = "${var.nat_gateway_tags}"
  depends_on    = ["aws_internet_gateway.eks_vpc_igw", "aws_subnet.eks_vpc_public_subnets", "aws_eip.eks_nat_gw"]
}

resource "aws_eip" "eks_nat_gw" {
  count = "${var.number_of_nat_gateways != "" ? var.number_of_nat_gateways : 0}"
}

resource "aws_subnet" "eks_vpc_private_subnets" {
  count = "${length(var.eks_private_subnet_cidr) > 1 ? length(data.aws_availability_zones.available.names) * length(var.eks_private_subnet_cidr) : length(data.aws_availability_zones.available.names)}"

  vpc_id = "${aws_vpc.eks_vpc.id}"

  availability_zone = "${element(sort(data.aws_availability_zones.available.names), length(var.eks_private_subnet_cidr) > 1 ? count.index / length(var.eks_private_subnet_cidr) : count.index )}"

  cidr_block = "${cidrsubnet("${element(var.eks_private_subnet_cidr, count.index)}", 2, "${length(var.eks_private_subnet_cidr) > 1 ? count.index / length(data.aws_availability_zones.available.names) : count.index }")}"

  tags = "${merge(
    var.eks_private_subnet_tags,
    map(
      "Name", "EKS Private Subnet ${count.index+1} (${cidrsubnet("${element(var.eks_private_subnet_cidr, count.index)}", 2, "${length(var.eks_private_subnet_cidr) > 1 ? count.index / length(data.aws_availability_zones.available.names) : count.index }")}) ${data.aws_availability_zones.available.names[count.index / length(var.eks_private_subnet_cidr) ]}"
    ))}"

  depends_on = ["aws_vpc.eks_vpc", "aws_vpc_ipv4_cidr_block_association.eks_vpc_secondary_cidr_blocks"]
}

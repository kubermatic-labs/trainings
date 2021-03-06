/*
Copyright 2019 The KubeOne Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

provider "openstack" {
}

data "openstack_networking_network_v2" "external_network" {
  name     = var.external_network_name
  external = true
}

resource "openstack_compute_keypair_v2" "deployer" {
  name       = "${var.cluster_name}-deployer-key"
  public_key = file(var.ssh_public_key_file)
}

resource "openstack_networking_network_v2" "network" {
  name           = "${var.cluster_name}-cluster"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet" {
  name            = "${var.cluster_name}-cluster"
  network_id      = openstack_networking_network_v2.network.id
  cidr            = var.subnet_cidr
  ip_version      = 4
  dns_nameservers = var.subnet_dns_servers
}

resource "openstack_networking_router_v2" "router" {
  name                = "${var.cluster_name}-cluster"
  admin_state_up      = "true"
  external_network_id = data.openstack_networking_network_v2.external_network.id
}

resource "openstack_networking_router_interface_v2" "router_subnet_link" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}

resource "openstack_networking_secgroup_v2" "securitygroup" {
  name        = "${var.cluster_name}-cluster"
  description = "Security group for the Kubeone Kubernetes cluster ${var.cluster_name}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_allow_internal_ipv4" {
  description       = "Allow security group internal IPv4 traffic"
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_group_id   = openstack_networking_secgroup_v2.securitygroup.id
  security_group_id = openstack_networking_secgroup_v2.securitygroup.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_ssh" {
  description       = "Allow SSH"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.securitygroup.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_apiserver" {
  description       = "Allow kube-apiserver"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.securitygroup.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_apiserver_internal" {
  description       = "Allow kube-apiserver"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "192.168.1.0/24"
  security_group_id = openstack_networking_secgroup_v2.securitygroup.id
}

resource "openstack_compute_instance_v2" "control_plane" {
  count = 3
  name  = "${var.cluster_name}-cp-${count.index}"

  image_name      = var.image
  flavor_name     = var.control_plane_flavor
  key_pair        = openstack_compute_keypair_v2.deployer.name
  security_groups = [openstack_networking_secgroup_v2.securitygroup.name]

  network {
    port = element(openstack_networking_port_v2.control_plane.*.id, count.index)
  }
}

resource "openstack_networking_port_v2" "control_plane" {
  count = 3
  name  = "${var.cluster_name}-control_plane-${count.index}"

  admin_state_up     = "true"
  network_id         = openstack_networking_network_v2.network.id
  security_group_ids = [openstack_networking_secgroup_v2.securitygroup.id]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.subnet.id
  }
}


resource "openstack_networking_floatingip_v2" "control_plane" {
  count = 3
  pool  = var.external_network_name
}


resource "openstack_networking_floatingip_associate_v2" "control_plane" {
  count = 3

  floating_ip = element(
    openstack_networking_floatingip_v2.control_plane.*.address,
    count.index,
  )
  port_id = element(openstack_networking_port_v2.control_plane.*.id, count.index)
}

## Start LBaaS
resource "openstack_lb_loadbalancer_v2" "kubeapi_lb" {
  name           = "${var.cluster_name}-kubeapi_lb"
  admin_state_up = "true"
  vip_subnet_id = openstack_networking_subnet_v2.subnet.id

  security_group_ids = [openstack_networking_secgroup_v2.securitygroup.id]

}

resource "openstack_lb_listener_v2" "kubeapi_listener" {
  name          = "${var.cluster_name}-kubeapi-lb-listener"
  protocol        = "TCP"
  protocol_port   = 6443
  loadbalancer_id = openstack_lb_loadbalancer_v2.kubeapi_lb.id
}

resource "openstack_lb_pool_v2" "kubeapi_pool" {
  name          = "${var.cluster_name}-kubeapi-lb-pool"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.kubeapi_listener.id
}

resource "openstack_lb_member_v2" "kubeapi_nodes" {
  name          = "${var.cluster_name}-kubeapi-lb-member"
  count         = var.control_plane_target_pool_members_count
  pool_id       = openstack_lb_pool_v2.kubeapi_pool.id
  subnet_id     = openstack_networking_subnet_v2.subnet.id
  address       = "${element(openstack_compute_instance_v2.control_plane.*.network.0.fixed_ip_v4, count.index)}"
  protocol_port = 6443

  depends_on = [
    "openstack_lb_loadbalancer_v2.kubeapi_lb",
  ]
}

resource "openstack_networking_floatingip_v2" "kubeapi_lb_floating_ip" {
  pool  = var.external_network_name
  port_id = "${openstack_lb_loadbalancer_v2.kubeapi_lb.vip_port_id}"

  depends_on = [
    "openstack_lb_loadbalancer_v2.kubeapi_lb",
  ]
}

resource "openstack_lb_monitor_v2" "kubeapi_monitor" {
  name          = "${var.cluster_name}-kubeapi-monitor"
  pool_id        = "${openstack_lb_pool_v2.kubeapi_pool.id}"
  type           = "TCP"
  delay          = 20
  timeout        = 10
  max_retries    = 5
}
provider "aci" {
    username = ""
    password = ""
    url      = ""
    insecure = true
}

resource "aci_vlan_pool" "aci_p26_static_vlanpool" {
    name            =       "aci_p26_static_vlanpool"
    description     =       "aci_p26_static_vlanpool"
    alloc_mode      =       "static"
}

resource "aci_vlan_pool" "aci_p26_dynamic_vlanpool" {
    name            =       "aci_p26_dynamic_vlanpool"
    description     =       "aci_p26_dynamic_vlanpool"
    alloc_mode      =       "dynamic"
}

resource "aci_ranges" "vlan_pool_static" {
    vlan_pool_dn    =       aci_vlan_pool.aci_p26_static_vlanpool.id
    _from           =       local.static_vlan_start
    to              =       local.static_vlan_end
    alloc_mode      =       "inherit"
    role            =       "external"
}

resource "aci_ranges" "vlan_pool_dynamic" {
    vlan_pool_dn    =       aci_vlan_pool.aci_p26_dynamic_vlanpool.id
    _from           =       local.dynamic_vlan_start
    to              =       local.dynamic_vlan_end
    alloc_mode      =       "inherit"
    role            =       "external"
}

resource "aci_physical_domain" "aci_p26_physdom" {
    name            =       "aci_p26_physdom"
    relation_infra_rs_vlan_ns = aci_vlan_pool.aci_p26_static_vlanpool.id
}

resource "aci_l3_domain_profile" "aci_p26_extrtdom" {
    name            =       "aci_p26_extrtdom"
}

resource "aci_attachable_access_entity_profile" "aci_p26_l2_aep" {
    name            =       "aci_p26_l2_aep"
    relation_infra_rs_dom_p =       [aci_physical_domain.aci_p26_physdom.id]
}

resource "aci_attachable_access_entity_profile" "aci_p26_l3_aep" {
    name            =       "aci_p26_l3_aep"
    relation_infra_rs_dom_p =       [aci_l3_domain_profile.aci_p26_extrtdom.id]
}

resource "aci_attachable_access_entity_profile" "aci_p26_vmm_aep" {
    name            =       "aci_p26_vmm_aep"
}

data "aci_l2_interface_policy" "aci_lab_l2global" {
    name = "aci_lab_l2global"
}

data "aci_lldp_interface_policy" "aci_lab_lldp" {
    name = "aci_lab_lldp"
}

data "aci_cdp_interface_policy" "aci_lab_cdp" {
    name = "aci_lab_cdp"
}

data "aci_miscabling_protocol_interface_policy" "aci_lab_mcp" {
    name = "aci_lab_mcp"
}
resource "aci_leaf_access_port_policy_group" "aci_p26_intpolg_access" {
    name                            = "aci_p26_intpolg_access"
    relation_infra_rs_cdp_if_pol    = data.aci_cdp_interface_policy.aci_lab_cdp.id
    relation_infra_rs_lldp_if_pol   = data.aci_lldp_interface_policy.aci_lab_lldp.id
    relation_infra_rs_mcp_if_pol    = data.aci_miscabling_protocol_interface_policy.aci_lab_mcp.id
    relation_infra_rs_l2_if_pol     = data.aci_l2_interface_policy.aci_lab_l2global.id
    relation_infra_rs_att_ent_p     = aci_attachable_access_entity_profile.aci_p26_l3_aep.id
}

data "aci_lacp_policy" "aci_lab_lacp" {
    name = "aci_lab_lacp"
}

resource "aci_pcvpc_interface_policy_group" "aci_p26_intpolg_pc" {
    name                            = "aci_p26_intpolg_pc"
    relation_infra_rs_cdp_if_pol    =  data.aci_cdp_interface_policy.aci_lab_cdp.id
    relation_infra_rs_lldp_if_pol   = data.aci_lldp_interface_policy.aci_lab_lldp.id
    relation_infra_rs_mcp_if_pol    = data.aci_miscabling_protocol_interface_policy.aci_lab_mcp.id
    relation_infra_rs_l2_if_pol     = data.aci_l2_interface_policy.aci_lab_l2global.id
    relation_infra_rs_att_ent_p     = aci_attachable_access_entity_profile.aci_p26_l2_aep.id
    relation_infra_rs_lacp_pol      = data.aci_lacp_policy.aci_lab_lacp.id
}

resource "aci_pcvpc_interface_policy_group" "aci_p26_intpolg_vpc" {
    name                            = "aci_p26_intpolg_vpc"
    relation_infra_rs_cdp_if_pol    = data.aci_cdp_interface_policy.aci_lab_cdp.id
    relation_infra_rs_lldp_if_pol   = data.aci_lldp_interface_policy.aci_lab_lldp.id
    relation_infra_rs_mcp_if_pol    = data.aci_miscabling_protocol_interface_policy.aci_lab_mcp.id
    relation_infra_rs_l2_if_pol     = data.aci_l2_interface_policy.aci_lab_l2global.id
    relation_infra_rs_att_ent_p     = aci_attachable_access_entity_profile.aci_p26_vmm_aep.id
    relation_infra_rs_lacp_pol      = data.aci_lacp_policy.aci_lab_lacp.id
}

resource "aci_leaf_interface_profile" "aci_p26_acc_intf_p" {
    name                            = "aci_p26_acc_intf_p"
}

resource "aci_access_port_selector" "pod26_acc_port_selector" {
    leaf_interface_profile_dn      = aci_leaf_interface_profile.aci_p26_acc_intf_p.id
    name                           = "pod26_acc_port_selector"
    access_port_selector_type      = "range"
    relation_infra_rs_acc_base_grp = aci_leaf_access_port_policy_group.aci_p26_intpolg_access.id
}

resource "aci_access_port_block" "pod26_acc_port_block" {
    access_port_selector_dn = aci_access_port_selector.pod26_acc_port_selector.id
    name                    = "pod26_acc_port_block"
    from_card               = "1"
    from_port               = local.access_port
    to_card                 = "1"
    to_port                 = local.access_port
}

resource "aci_leaf_profile" "aci_p26_access_sp" {
    name                         = "aci_p26_access_sp"
    relation_infra_rs_acc_port_p = [aci_leaf_interface_profile.aci_p26_acc_intf_p.id]
}

resource "aci_switch_association" "aci_p26_access_sp" {
    leaf_profile_dn         = aci_leaf_profile.aci_p26_access_sp.id
    name                    = "aci_p26_access_sp"
    switch_association_type = "range"
}

resource "aci_node_block" "pod26_access_leaf_nodes" {
    switch_association_dn = aci_switch_association.aci_p26_access_sp.id
    name                  = "pod26_access_leaf_nodes"
    from_                 = local.access_leaf
    to_                   = local.access_leaf
}

resource "aci_leaf_interface_profile" "aci_p26_pc_intf_p" {
    name                            = "aci_p26_pc_intf_p"
}

resource "aci_access_port_selector" "pod26_pc_port_selector" {
    leaf_interface_profile_dn      = aci_leaf_interface_profile.aci_p26_pc_intf_p.id
    name                           = "pod26_pc_port_selector"
    access_port_selector_type      = "range"
    relation_infra_rs_acc_base_grp = aci_pcvpc_interface_policy_group.aci_p26_intpolg_pc.id
}

resource "aci_access_port_block" "pod26_pc_port_block" {
    access_port_selector_dn = aci_access_port_selector.pod26_pc_port_selector.id
    name                    = "pod26_pc_port_block"
    from_card               = "1"
    from_port               = local.PC_port_1
    to_card                 = "1"
    to_port                 = local.PC_port_2
}

resource "aci_leaf_profile" "aci_p26_pc_sp" {
    name                         = "aci_p26_pc_sp"
    relation_infra_rs_acc_port_p = [aci_leaf_interface_profile.aci_p26_pc_intf_p.id]
}

resource "aci_switch_association" "aci_p26_pc_sp" {
    leaf_profile_dn         = aci_leaf_profile.aci_p26_pc_sp.id
    name                    = "aci_p26_pc_sp"
    switch_association_type = "range"
}

resource "aci_node_block" "pod26_pc_leaf_nodes" {
    switch_association_dn = aci_switch_association.aci_p26_pc_sp.id
    name                  = "pod26_pc_leaf_nodes"
    from_                 = local.PC_leaf
    to_                   = local.PC_leaf
}

resource "aci_leaf_interface_profile" "aci_p26_vpc_intf_p" {
    name                            = "aci_p26_vpc_intf_p"
}

resource "aci_access_port_selector" "pod26_vpc_port_selector" {
    leaf_interface_profile_dn      = aci_leaf_interface_profile.aci_p26_vpc_intf_p.id
    name                           = "pod26_vpc_port_selector"
    access_port_selector_type      = "range"
    relation_infra_rs_acc_base_grp = aci_pcvpc_interface_policy_group.aci_p26_intpolg_vpc.id
}

resource "aci_access_port_block" "pod26_vpc_port_block" {
    access_port_selector_dn = aci_access_port_selector.pod26_vpc_port_selector.id
    name                    = "pod26_vpc_port_block"
    from_card               = "1"
    from_port               = local.vpc_port_1
    to_card                 = "1"
    to_port                 = local.vpc_port_2
}

resource "aci_leaf_profile" "aci_p26_vpc_sp" {
    name                         = "aci_p26_vpc_sp"
    relation_infra_rs_acc_port_p = [aci_leaf_interface_profile.aci_p26_vpc_intf_p.id]
}

resource "aci_switch_association" "aci_p26_vpc_sp" {
    leaf_profile_dn         = aci_leaf_profile.aci_p26_vpc_sp.id
    name                    = "aci_p26_vpc_sp"
    switch_association_type = "range"
}

resource "aci_node_block" "pod26_vpc_leaf_nodes" {
    switch_association_dn = aci_switch_association.aci_p26_vpc_sp.id
    name                  = "pod26_vpc_leaf_nodes"
    from_                 = local.vpc_leaf_1
    to_                   = local.vpc_leaf_2
}

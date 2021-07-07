cluster_name = "kkp-master"
  
project = "TODO-YOUR-GCP-PROJECT-ID"

region = "europe-west4"

# instance to create of the control plane
control_plane_count = 1

# listeners of the Loadbalancer. Default is NOT HA, but ensure the bootstraping works -> after bootstraping increase to e.g. 3
control_plane_target_pool_members_count = 1
  
### update to your location if needed
//ssh_public_key_file = "~/.ssh/id_rsa.pub"
ssh_public_key_file = "../../../.secrets/id_rsa.pub"
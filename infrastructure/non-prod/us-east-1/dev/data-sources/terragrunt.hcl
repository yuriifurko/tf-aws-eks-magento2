include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "datasources" {
  path   = "${dirname(find_in_parent_folders())}/_common/data-sources.hcl"
  expose = false
}

inputs = {}
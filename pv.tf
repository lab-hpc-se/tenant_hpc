resource "kubernetes_namespace" "app_namespace" {
  metadata {
    annotations = {
      name = var.app_namespace
    }
    labels = {
      name = var.app_namespace
    }
    name = var.app_namespace
  }
}


resource "kubernetes_persistent_volume" "lustre_local_pv" {
  metadata {
    name = var.pv_name
  }

  spec {
    capacity = {
      storage = format("%sGi", var.lustre_storage_capacity)
    }
    volume_mode                      = "Filesystem"
    access_modes                     = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      local {
        path = "/lustre_fsx"
      }
    }

    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "Name"
            operator = "In"
            values = [
              "hpc-1-group-1",
              "hpc-1-group-2"
            ]
          }
        }
      }
    }
  }
}


resource "kubernetes_persistent_volume_claim" "lustre_local_pvc" {
  metadata {
    name      = var.pvc_name
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "${var.lustre_storage_capacity}Gi"
      }
    }
    volume_name        = kubernetes_persistent_volume.lustre_local_pv.metadata[0].name
    storage_class_name = ""
  }
}

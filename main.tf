terraform {
  backend "gcs" {
    bucket = "tfstatesharky"
  }
}
data "google_container_engine_versions" "gke_version" {
  location       = "us-central1-f"
  version_prefix = "1.27."
}

resource "google_container_cluster" "sharky-primary" {
  name     = "${var.project_id}-gke"
  location = "us-central1-f"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
}

# Separately Managed Node Pool
resource "google_container_node_pool" "sharky-primary_nodes" {
  name     = google_container_cluster.sharky-primary.name
  location = "us-central1-f"
  cluster  = google_container_cluster.sharky-primary.name

  version    = "1.30.8-gke.1162001"
  node_count = var.gke_num_nodes

  node_config {
    disk_size_gb = 60
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_id
    }

    # preemptible  = true
    machine_type = "c2d-standard-4"
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

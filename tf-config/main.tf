terraform {
  required_version = ">=0.14"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.44.1"
    }
  }
}

locals {
  api_config_id_prefix = "api"
  api_id               = "crc-api"
  gateway_id           = "kcuartero-gw"
  display_name         = "kcuartero-api"
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = var.public_key 
}

resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
  disable_on_destroy = true
}

#enable api gateway
resource "google_project_service" "apigateway_googleapis_com" {
  project = var.project_number
  service = "apigateway.googleapis.com"
}

#create cloud run service
resource "google_cloud_run_service" "run_service" {
  name     = "app"
  location = var.region

  template {
    spec {
      containers {
        image = "us-central1-docker.pkg.dev/kcuartero-crc-tf/kcuartero-repo/bb8bd4f5c4d9:latest"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  #wait for cloud run api to be enabled
  depends_on = [
    google_project_service.run_api
  ]
}

#allow unauthenticated users to invoke the service 
resource "google_cloud_run_service_iam_member" "run_all_users" {
  service  = google_cloud_run_service.run_service.name
  location = google_cloud_run_service.run_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

#display service URL
output "service_url" {
  value = google_cloud_run_service.run_service.status[0].url
}

  resource "google_storage_bucket" "kcuartero_resume" {
  force_destroy            = false
  name                     = "kcuartero_resume"
  location                 = "US"
  project                  = var.project_id
  public_access_prevention = "inherited"
  storage_class            = "STANDARD"
  website {
    main_page_suffix = "index.html"
  }
  cors {
    origin = ["*"]
    method = ["GET", "POST"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

}

resource "google_storage_default_object_access_control" "public_rule" {
  bucket = google_storage_bucket.kcuartero_resume.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_storage_bucket_object" "index" {
  name = "index.html"
  source = var.index 
  bucket = google_storage_bucket.kcuartero_resume.name
  depends_on = [google_storage_default_object_access_control.public_rule]
}

resource "google_storage_bucket_object" "update_function" {
  name = "updateVisitorCount.js"
  source = var.updateFunction
  bucket = google_storage_bucket.kcuartero_resume.name
  depends_on = [google_storage_default_object_access_control.public_rule]
}

resource "google_storage_bucket_object" "style_css" {
  name = "style.css"
  source = var.style_css
  bucket = google_storage_bucket.kcuartero_resume.name
depends_on = [google_storage_default_object_access_control.public_rule]
}

resource "google_storage_bucket_object" "cors" {
  name = "cors.json"
  source = var.cors
  bucket = google_storage_bucket.kcuartero_resume.name
  depends_on = [google_storage_default_object_access_control.public_rule]
}

resource "google_api_gateway_api" "api_gw" {
  provider  = google-beta
  api_id    = local.api_id
  project   = var.project_id
  display_name = local.display_name
}

resource "google_api_gateway_api_config" "api_cfg" {
  provider              = google-beta
  api                   = google_api_gateway_api.api_gw.api_id
  api_config_id_prefix  = local.api_config_id_prefix
  project               = var.project_id
  display_name          = local.display_name

  openapi_documents {
    document {
      path              = "openapi2-run.yaml"
      contents          = filebase64(var.api_cfg)
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}


# Reserve IP address
resource "google_compute_global_address" "default" {
  name = "external-ip"
}
resource "google_api_gateway_gateway" "gw" {
  provider = google-beta
  region   = var.region
  project  = var.project_id

  api_config = google_api_gateway_api_config.api_cfg.id

  gateway_id = local.gateway_id
  display_name = local.display_name

  depends_on = [google_api_gateway_api_config.api_cfg]
}

resource "google_artifact_registry_repository" "kcuartero-repo" {
  location = "us-central1"
  repository_id = "kcuartero-repo"
  format = "DOCKER"
}

#create LB backend buckets
resource "google_compute_backend_bucket" "kcuartero_bucket" {
  name = "kcuartero-backend"
  bucket_name = google_storage_bucket.kcuartero_resume.name
}

resource "google_compute_managed_ssl_certificate" "default" {
  name = "kcuartero-cert"

  managed {
    domains = ["kcuartero.info"]
  }
}

resource "google_compute_target_https_proxy" "default" {
  name = "kcuartero-proxy"
  url_map = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}
#create url map
resource "google_compute_url_map" "default" {
  name = "http-lb"

  default_service = google_compute_backend_bucket.kcuartero_bucket.id

  host_rule {
    hosts =["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.kcuartero_bucket.id

    path_rule {
      paths = ["/*"]
      service = google_compute_backend_bucket.kcuartero_bucket.id
    }
  }
}

resource "google_compute_backend_service" "default" {
  name = "backend-service"
  port_name = "http"
  protocol = "HTTP"
  timeout_sec = "10"

  health_checks = [google_compute_http_health_check.default.id]
}

resource "google_compute_http_health_check" "default" {
  name               = "http-health-check"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
}

#create forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  name = "lb-forwarding-rule"
  ip_protocol = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range = "443"
  target = google_compute_target_https_proxy.default.id
  ip_address = google_compute_global_address.default.id 
}

#create dns managed zone
resource "google_dns_managed_zone" "kcuartero-zone" {
  name = "kcuartero-dns-zone"
  dns_name = "kcuartero.info."
}
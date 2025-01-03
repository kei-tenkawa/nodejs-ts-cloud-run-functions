terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
}

locals {
  project         = "advent-calendar-2024-w"
  region          = "asia-northeast1"
  zone            = "asia-northeast1-a"
  domain          = "api.tenkawa-k.com"
  ESPv2_image_ver = "2.51.0"
}

provider "google" {
  project = local.project
  region  = local.region
}

data "google_project" "project" {
}

# Cloud Storage などの命名で利用するランダムID
resource "random_id" "default" {
  byte_length = 8
}

# functionモジュール
module "functions" {
  source                = "./modules/functions"
  project               = local.project
  region                = local.region
  random_id_hex         = random_id.default.hex
  dist_dir              = "${path.root}/../dist"
  service_account_email = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

# secretモジュール
module "secret" {
  source                = "./modules/secret"
  project               = local.project
  service_account_email = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

# endpointsモジュール
module "endpoints" {
  source                 = "./modules/endpoints"
  project                = local.project
  domain                 = local.domain
  function_uri           = module.functions.function_uri
  service_account_number = data.google_project.project.number
  ESPv2_image_ver        = local.ESPv2_image_ver
}

# gatewayモジュール
module "gateway" {
  source          = "./modules/gateway"
  project         = local.project
  region          = local.region
  domain          = local.domain
  ESPv2_image_ver = local.ESPv2_image_ver
  config_id       = module.endpoints.config_id
  depends_on      = [module.endpoints]
}

# schedulerモジュール
module "scheduler" {
  source                = "./modules/scheduler"
  project               = local.project
  region                = local.region
  function_uri          = module.functions.function_uri
  service_account_email = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

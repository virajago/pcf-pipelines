resource "google_sql_database_instance" "master" {
  region           = "${var.gcp_region}"
  database_version = "MYSQL_5_6"
  name             = "${var.ert_sql_instance_name}"

  settings {
    tier = "db-f1-micro"

    ip_configuration = {
      ipv4_enabled = true

      authorized_networks = [
        {
          name  = "nat-1"
          value = "${google_compute_instance.nat-gateway-pri.network_interface.0.access_config.0.assigned_nat_ip}"
        },
        {
          name  = "nat-2"
          value = "${google_compute_instance.nat-gateway-sec.network_interface.0.access_config.0.assigned_nat_ip}"
        },
        {
          name  = "nat-3"
          value = "${google_compute_instance.nat-gateway-ter.network_interface.0.access_config.0.assigned_nat_ip}"
        },
        {
          name  = "opsman"
          value = "${google_compute_instance.ops-manager.network_interface.0.access_config.0.assigned_nat_ip}"
        },
        {
          name  = "all"
          value = "0.0.0.0/0"
        },
      ]
    }
  }
}

resource "google_sql_database" "uaa" {
  name     = "uaa"
  instance = "${google_sql_database_instance.master.name}"
}

resource "google_sql_database" "ccdb" {
  name     = "ccdb"
  instance = "${google_sql_database_instance.master.name}"
  depends_on = ["google_sql_database.uaa"]
}

resource "google_sql_database" "notifications" {
  name     = "notifications"
  instance = "${google_sql_database_instance.master.name}"
  depends_on = ["google_sql_database.ccdb"]
}

resource "google_sql_database" "autoscale" {
  name     = "autoscale"
  instance = "${google_sql_database_instance.master.name}"
  depends_on = ["google_sql_database.notifications"]
}

resource "google_sql_database" "app_usage_service" {
  name     = "app_usage_service"
  instance = "${google_sql_database_instance.master.name}"
  depends_on = ["google_sql_database.autoscale"]
}

resource "google_sql_database" "console" {
  name     = "console"
  instance = "${google_sql_database_instance.master.name}"
  depends_on = ["google_sql_database.app_usage_service"]
}

resource "google_sql_database" "routing" {
  name     = "routing"
  instance = "${google_sql_database_instance.master.name}"
  depends_on = ["google_sql_database.console"]
}

resource "google_sql_database" "diego" {
  name     = "diego"
  instance = "${google_sql_database_instance.master.name}"
  depends_on = ["google_sql_database.routing"]
}

resource "google_sql_database" "account" {
  name     = "account"
  instance = "${google_sql_database_instance.master.name}"
  depends_on = ["google_sql_database.diego"]
}

resource "google_sql_database" "nfsvolume" {
  name     = "nfsvolume"
  instance = "${google_sql_database_instance.master.name}"
  depends_on = ["google_sql_database.account"]
}

resource "google_sql_database" "networkpolicyserver" {
  name     = "networkpolicyserver"
  instance = "${google_sql_database_instance.master.name}"
  depends_on = ["google_sql_database.nfsvolume"]
}

resource "google_sql_user" "diego" {
  name     = "${var.db_diego_username}"
  password = "${var.db_diego_password}"
  instance = "${google_sql_database_instance.master.name}"
  host     = "%"
}

resource "google_sql_user" "notifications" {
  name     = "${var.db_notifications_username}"
  password = "${var.db_notifications_password}"
  instance = "${google_sql_database_instance.master.name}"
  host     = "%"
  depends_on = ["google_sql_user.diego"]
}

resource "google_sql_user" "autoscale" {
  name     = "${var.db_autoscale_username}"
  password = "${var.db_autoscale_password}"
  instance = "${google_sql_database_instance.master.name}"
  host     = "%"
  depends_on = ["google_sql_user.notifications"]
}

resource "google_sql_user" "uaa" {
  name     = "${var.db_uaa_username}"
  password = "${var.db_uaa_password}"
  instance = "${google_sql_database_instance.master.name}"
  host     = "%"
  depends_on = ["google_sql_user.autoscale"]
}

resource "google_sql_user" "app_usage_service" {
  name     = "${var.db_app_usage_service_username}"
  password = "${var.db_app_usage_service_password}"
  instance = "${google_sql_database_instance.master.name}"
  host     = "%"
  depends_on = ["google_sql_user.uaa"]
}

resource "google_sql_user" "ccdb" {
  name     = "${var.db_ccdb_username}"
  password = "${var.db_ccdb_password}"
  instance = "${google_sql_database_instance.master.name}"
  host     = "%"
  depends_on = ["google_sql_user.app_usage_service"]
}

resource "google_sql_user" "routing" {
  name     = "${var.db_routing_username}"
  password = "${var.db_routing_password}"
  instance = "${google_sql_database_instance.master.name}"
  host     = "%"
  depends_on = ["google_sql_user.ccdb"]
}

resource "google_sql_user" "account" {
  name     = "${var.db_accountdb_username}"
  password = "${var.db_accountdb_password}"
  instance = "${google_sql_database_instance.master.name}"
  host     = "%"
  depends_on = ["google_sql_user.routing"]
}

resource "google_sql_user" "network_policy_server" {
  name     = "${var.db_networkpolicyserverdb_username}"
  password = "${var.db_networkpolicyserverdb_password}"
  instance = "${google_sql_database_instance.master.name}"
  host     = "%"
  depends_on = ["google_sql_user.account"]
}

resource "google_sql_user" "nfs_volume" {
  name     = "${var.db_nfsvolumedb_username}"
  password = "${var.db_nfsvolumedb_password}"
  instance = "${google_sql_database_instance.master.name}"
  host     = "%"
  depends_on = ["google_sql_user.network_policy_server"]
}

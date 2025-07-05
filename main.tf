
resource "google_compute_instance" "postgres_vm" {
  name         = "postgres-vm"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk { initialize_params { image = "debian-cloud/debian-11" } }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y postgresql postgresql-contrib
    systemctl enable postgresql
    systemctl start postgresql

    sudo -u postgres psql <<SQL
    CREATE DATABASE myappdb;
    CREATE SCHEMA myapp AUTHORIZATION postgres;
SQL
  EOT
}

resource "google_compute_instance" "user_vm" {
  name         = "user-vm"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk { initialize_params { image = "debian-cloud/debian-11" } }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y postgresql
    systemctl enable postgresql
    systemctl start postgresql

    sudo -u postgres psql <<SQL
    CREATE USER appuser WITH PASSWORD 'securepass';
    GRANT CONNECT ON DATABASE postgres TO appuser;
SQL
  EOT
}

resource "google_compute_instance" "backup_vm" {
  name         = "backup-vm"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk { initialize_params { image = "debian-cloud/debian-11" } }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y postgresql
    systemctl enable postgresql
    systemctl start postgresql

    mkdir -p /var/backups/pg
    echo "0 2 * * * postgres pg_dumpall > /var/backups/pg/all_$(date +\\%F).sql" >> /etc/crontab
  EOT
}

resource "google_compute_instance" "tuning_vm" {
  name         = "tuning-vm"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk { initialize_params { image = "debian-cloud/debian-11" } }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y postgresql
    systemctl enable postgresql
    systemctl start postgresql

    echo "shared_buffers = 256MB" >> /etc/postgresql/11/main/postgresql.conf
    echo "work_mem = 16MB" >> /etc/postgresql/11/main/postgresql.conf
    systemctl restart postgresql
  EOT
}

resource "google_compute_firewall" "allow_pg_ssh" {
  name    = "allow-pg-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "5432"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["demo-vm"]
}

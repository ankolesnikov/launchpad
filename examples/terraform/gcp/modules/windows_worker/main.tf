resource "google_compute_firewall" "winrm" {
  name        = "${var.cluster_name}-win-worker"
  description = "winrm access for windows workers"
  network     = var.vpc_name
  direction   = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["5985-5990"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-winrm"]
}

resource "google_compute_firewall" "rdp" {
  name        = "${var.cluster_name}-win-rdp"
  description = "rdp access for windows workers"
  network     = var.vpc_name
  direction   = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-rdp"]
}

resource "google_compute_instance" "mke_win_worker" {
  count = var.worker_count

  name         = "${var.cluster_name}-win-worker-${count.index + 1}"
  machine_type = var.worker_type
  zone         = var.gcp_zone
  metadata = tomap({
    role                       = "worker"
    windows-startup-script-ps1 = <<EOF

# Create a user in Administrators group
net user ${var.windows_user} "${var.windows_password}" /ADD /Y
NET LOCALGROUP "Administrators" ${var.windows_user} /ADD
Write-Output "User '${var.windows_user}' created"

# Snippet to enable WinRM over HTTPS with a self-signed certificate
# from https://gist.github.com/TechIsCool/d65017b8427cfa49d579a6d7b6e03c93
Write-Output "Disabling WinRM over HTTP..."
Disable-NetFirewallRule -Name "WINRM-HTTP-In-TCP"
Disable-NetFirewallRule -Name "WINRM-HTTP-In-TCP-PUBLIC"
Get-ChildItem WSMan:\Localhost\listener | Remove-Item -Recurse

Write-Output "Configuring WinRM for HTTPS..."
Set-Item -Path WSMan:\LocalHost\MaxTimeoutms -Value '1800000'
Set-Item -Path WSMan:\LocalHost\Shell\MaxMemoryPerShellMB -Value '1024'
Set-Item -Path WSMan:\LocalHost\Service\AllowUnencrypted -Value 'false'
Set-Item -Path WSMan:\LocalHost\Service\Auth\Basic -Value 'true'
Set-Item -Path WSMan:\LocalHost\Service\Auth\CredSSP -Value 'true'

New-NetFirewallRule -Name "WINRM-HTTPS-In-TCP" `
    -DisplayName "Windows Remote Management (HTTPS-In)" `
    -Description "Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]" `
    -Group "Windows Remote Management" `
    -Program "System" `
    -Protocol TCP `
    -LocalPort "5986" `
    -Action Allow `
    -Profile Domain,Private

New-NetFirewallRule -Name "WINRM-HTTPS-In-TCP-PUBLIC" `
    -DisplayName "Windows Remote Management (HTTPS-In)" `
    -Description "Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]" `
    -Group "Windows Remote Management" `
    -Program "System" `
    -Protocol TCP `
    -LocalPort "5986" `
    -Action Allow `
    -Profile Public

$Hostname = [System.Net.Dns]::GetHostByName((hostname)).HostName.ToUpper()
$pfx = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName $Hostname
$certThumbprint = $pfx.Thumbprint
$certSubjectName = $pfx.SubjectName.Name.TrimStart("CN = ").Trim()

New-Item -Path WSMan:\LocalHost\Listener -Address * -Transport HTTPS -Hostname $certSubjectName -CertificateThumbPrint $certThumbprint -Port "5986" -force

Write-Output "Restarting WinRM Service..."
Stop-Service WinRM
Set-Service WinRM -StartupType "Automatic"
Start-Service WinRM
EOF

  })

  boot_disk {
    initialize_params {
      image = var.image_name
      type  = var.worker_volume_type
      size  = var.worker_volume_size
    }
  }

  network_interface {
    network    = var.vpc_name
    subnetwork = var.subnetwork_name
    access_config {
    }
  }

  tags = [
    var.cluster_name,
    "allow-rdp",
    "allow-winrm",
    "allow-worker",
    "allow-internal"
  ]

  service_account {
    email = var.service_account_email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  provisioner "remote-exec" {
    connection {
      host     = self.network_interface.0.access_config.0.nat_ip
      type     = "winrm"
      user     = var.windows_user
      password = var.windows_password
      timeout  = "10m"
      https    = "true"
      insecure = "true"
      port     = 5986
    }

    inline = [
      "ECHO hello"
    ]
  }
}

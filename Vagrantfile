Vagrant.configure("2") do |config|
  config.vm.define "proxy" do |proxy|
    proxy.vm.box = "bento/ubuntu-16.04"
    proxy.vm.network "public_network", ip: "192.168.87.250"
    proxy.ssh.username = "vagrant"
    proxy.ssh.password = "vagrant"
    proxy.ssh.insert_key = true
    proxy.ssh.pty = false
    proxy.vm.provider "virtualbox" do |v|
      v.gui = false
      v.customize ['modifyvm', :id, '--memory', 512]
      v.customize ["modifyvm", :id, "--cpus", 1]
      v.customize ["modifyvm", :id, "--vram", "128"]
      v.customize ["setextradata", "global", "GUI/MaxGuestResolution", "any"]
      v.customize ["setextradata", :id, "CustomVideoMode1", "1024x768x32"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--rtcuseutc", "on"]
      v.customize ["modifyvm", :id, "--accelerate3d", "on"]
      v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    end
    proxy.vm.provision "shell" do |s|
      s.inline = "/bin/bash /vagrant/proxy/configure-proxy-server.sh"
      s.args = ""
    end
  end
  config.vm.define "centos7test" do |centos7test|
    centos7test.vm.box = "bento/centos-7.3"
    centos7test.vm.network "public_network", ip: "192.168.87.251"
    centos7test.ssh.username = "vagrant"
    centos7test.ssh.password = "vagrant"
    centos7test.ssh.insert_key = true
    centos7test.ssh.pty = false
    centos7test.vm.provider "virtualbox" do |v|
      v.gui = true
      v.customize ['modifyvm', :id, '--memory', 2048]
      v.customize ["modifyvm", :id, "--cpus", 2]
      v.customize ["modifyvm", :id, "--vram", "256"]
      v.customize ["setextradata", "global", "GUI/MaxGuestResolution", "any"]
      v.customize ["setextradata", :id, "CustomVideoMode1", "1024x768x32"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--rtcuseutc", "on"]
      v.customize ["modifyvm", :id, "--accelerate3d", "on"]
      v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    end
    centos7test.vm.provision "shell" do |s|
      s.inline = "PROXY=$1/bin/bash AWM=$2 DESKTOP=$3 /vagrant/ansible/install.sh"
      s.args = "#{ENV['PROXY']} #{ENV['AWM']} #{ENV['DESKTOP']}"
    end
  end
  config.vm.define "centos6test" do |centos6test|
    centos6test.vm.box = "bento/centos-6.8"
    centos6test.vm.network "public_network", ip: "192.168.87.252"
    centos6test.ssh.username = "vagrant"
    centos6test.ssh.password = "vagrant"
    centos6test.ssh.insert_key = true
    centos6test.ssh.pty = false
    centos6test.vm.provider "virtualbox" do |v|
      v.gui = true
      v.customize ['modifyvm', :id, '--memory', 2048]
      v.customize ["modifyvm", :id, "--cpus", 2]
      v.customize ["modifyvm", :id, "--vram", "256"]
      v.customize ["setextradata", "global", "GUI/MaxGuestResolution", "any"]
      v.customize ["setextradata", :id, "CustomVideoMode1", "1024x768x32"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--rtcuseutc", "on"]
      v.customize ["modifyvm", :id, "--accelerate3d", "on"]
      v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    end
    centos6test.vm.provision "shell" do |s|
      s.inline = "PROXY=$1/bin/bash AWM=$2 DESKTOP=$3 /vagrant/ansible/install.sh"
      s.args = "#{ENV['PROXY']} #{ENV['AWM']} #{ENV['DESKTOP']}"
    end
  end
  config.vm.define "ubuntutest" do |ubuntutest|
    ubuntutest.vm.box = "ubuntu16.04"
    ubuntutest.vm.network "public_network", ip: "192.168.87.253"
    ubuntutest.ssh.username = "vagrant"
    ubuntutest.ssh.password = "vagrant"
    ubuntutest.ssh.insert_key = true
    ubuntutest.ssh.pty = false
    ubuntutest.vm.provider "virtualbox" do |v|
      v.gui = true
      v.customize ['modifyvm', :id, '--memory', 2048]
      v.customize ["modifyvm", :id, "--cpus", 2]
      v.customize ["modifyvm", :id, "--vram", "256"]
      v.customize ["setextradata", "global", "GUI/MaxGuestResolution", "any"]
      v.customize ["setextradata", :id, "CustomVideoMode1", "1024x768x32"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--rtcuseutc", "on"]
      v.customize ["modifyvm", :id, "--accelerate3d", "on"]
      v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    end
    ubuntutest.vm.provision "shell" do |s|
      s.inline = "PROXY=$1/bin/bash AWM=$2 DESKTOP=$3 /vagrant/ansible/install.sh"
      s.args = "#{ENV['PROXY']} #{ENV['AWM']} #{ENV['DESKTOP']}"
    end
  end
  config.vm.define "pxe" do |pxe|
    #pxe.vm.box = "ubuntu16.04"
    pxe.vm.box = "bento/ubuntu-16.04"
    pxe.vm.network "public_network", ip: "192.168.87.254"
    pxe.ssh.username = "vagrant"
    pxe.ssh.password = "vagrant"
    pxe.ssh.insert_key = true
    pxe.ssh.pty = false
    pxe.vm.provider "virtualbox" do |v|
      v.gui = false
      v.customize ['modifyvm', :id, '--memory', 512]
      v.customize ["modifyvm", :id, "--cpus", 1]
      v.customize ["modifyvm", :id, "--vram", "128"]
      v.customize ["setextradata", "global", "GUI/MaxGuestResolution", "any"]
      v.customize ["setextradata", :id, "CustomVideoMode1", "1024x768x32"]
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--rtcuseutc", "on"]
      v.customize ["modifyvm", :id, "--accelerate3d", "on"]
      v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    end
    pxe.vm.provision "shell" do |s|
      s.inline = "PROXY=$1/bin/bash /vagrant/pxe_files/configure-pxe-server.sh"
      s.args = "#{ENV['PROXY']}"
    end
  end
end

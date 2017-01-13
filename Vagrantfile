Vagrant.configure("2") do |config|
  config.vm.define "ubuntu_test" do |ubuntu_test|
    ubuntu_test.vm.box = "ubuntu16.04"
    ubuntu_test.vm.network "public_network", ip: "192.168.87.253"
    ubuntu_test.ssh.username = "vagrant"
    ubuntu_test.ssh.password = "vagrant"
    ubuntu_test.ssh.insert_key = true
    ubuntu_test.ssh.pty = false
    ubuntu_test.vm.provider "virtualbox" do |v|
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
    ubuntu_test.vm.provision "shell" do |s|
      s.inline = "PROXY=$1/bin/bash AWM=$2 /vagrant/ansible/install.sh"
      s.args = "#{ENV['PROXY']} #{ENV['AWM']}"
    end
  end
  config.vm.define "pxe" do |pxe|
    pxe.vm.box = "ubuntu16.04"
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
    pxe.vm.provision "shell", path: "script/configure-pxe-server.sh"
  end
end

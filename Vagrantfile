Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"

  # Loki VM
  config.vm.define "loki" do |loki|
    loki.vm.hostname = "loki"
    loki.vm.network "private_network", ip: "192.168.56.10"
    loki.vm.provider "virtualbox" do |vb|
      vb.memory = 512
      vb.cpus = 1
      vb.customize ["modifyvm", :id, "--audio", "none"]
    end
    loki.vm.provision "shell", path: "provision/loki.sh"
  end

  # Grafana VM
  config.vm.define "grafana" do |grafana|
    grafana.vm.hostname = "grafana"
    grafana.vm.network "private_network", ip: "192.168.56.11"
    grafana.vm.network "forwarded_port", guest: 3000, host: 3000
    grafana.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
      vb.cpus = 1
      vb.customize ["modifyvm", :id, "--audio", "none"]
    end
    grafana.vm.provision "shell", path: "provision/grafana.sh"
  end

  # App server VM
  config.vm.define "app" do |app|
    app.vm.hostname = "app-server"
    app.vm.network "private_network", ip: "192.168.56.20"
    app.vm.provider "virtualbox" do |vb|
      vb.memory = 512
      vb.cpus = 1
      vb.customize ["modifyvm", :id, "--audio", "none"]
    end
    app.vm.provision "shell", path: "provision/app.sh"
  end

end
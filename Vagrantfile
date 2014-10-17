Vagrant.configure("2") do |config|
  # pip install needs memory...
  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024"]
  end

  # Start with a base ubuntu box
  config.vm.box = "trusty64"
  config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"

  # Run setup script 
  config.vm.provision "shell", path: "setup.sh", privileged: false

  # Forward ports for amcat and elastic
  config.vm.network :forwarded_port, guest: 8001, host: 8001
  config.vm.network :forwarded_port, guest: 9200, host: 9201
end

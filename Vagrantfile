# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. no tocar a menos que sepas lo que haces!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  
  # todo vagrant necesita  una maquina virtual base para funcionar.
  config.vm.box = "ubuntu/bionic64"

  # se exponen los puertos que se van a utilizar en el desarrollo.
  # - puerto 80 en la VM y se expone en el 8080 en el host
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 443, host: 443
  # - puerto 3306 en la VM y se expone en el 6565 en el host
  config.vm.network "forwarded_port", guest: 3306, host: 6565


  # se comparte los archivos del proyecto para hacer la sincronizacion de las carpetas de el vm y el host.
  # el primer argumento es la ruta local y el segundo es la ruta de la VM. rsync es el tipo de sincronizacion que van a tener las carpetas
  config.vm.synced_folder "./", "/var/www/html"

  # Define un archivo inicial : Un script que se ejecutara despues del primer setup del "BOX" (= provisioning "vagrant provision")
  config.vm.provision :shell, path: "vagrant_config/bootstrap.sh"

  config.vm.provider "virtualbox" do |v|
    v.memory = 2024
    v.cpus = 2
    v.name = "gcrisk"
  end

  # config.vm.provider "vmware_desktop" do |v|
  #   v.vmx["custom-key"]  = "value"
  #   v.vmx["another-key"] = nil
  # end

end

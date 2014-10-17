AmCAT Vagrant files
=============

Installation instructions (ubuntu)
----

The following should install vagrant, download the vagrant script, and install and configure the virtual machine


```
sudo apt-get install vagrant
git clone https://github.com/vanatteveldt/vagrant_amcat
cd vagrant_amcat
vagrant up
```

Installation instructions (windows)
----

1. Install [vagrant](https://www.vagrantup.com/downloads.html) and [virtualbox](https://www.virtualbox.org/wiki/Downloads)
2. Add "c:\program files\oracle\virtualbox" to your system path (e.g. see https://www.youtube.com/watch?v=W9pg2FHeoq8)
3. Create an empty folder named 'vagrant_amcat'
4. Download the [Vagrantfile]() and copy it to the vagrant_amcat folder created in step 2
5. Open the vagrant_amcat folder in explorer, shift+right click, and select 'open command window here'
6. In the command windows, type `vagrant up`

It will take quite a while as the ubuntu virtual system is downloaded, setup, and started, so grab some coffee...

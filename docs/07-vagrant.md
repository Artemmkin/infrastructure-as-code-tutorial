## Vagrant

In this lab, we're going to learn about [Vagrant](https://www.vagrantup.com/) which is another tool that implements IaC approach and is often used for creating development environments.

## Intro

Before this lab, our main focus was on how to create and manage an environment where our application runs and is accessible to the public. Let's call that environment `production` for the sake of simplicity of referring to that later.

But what is about our local environment where we develop the code? Are there any problems with that?

Running our application locally would require us installing all of its dependencies and configuring the local system pretty much the same way as we did in the previous labs.

There are a few reasons why you don't want to do that:

* `This can break your system`. When you change your system configuration there are lot of things that can go wrong. For example, when installing/removing different packages you can easily mess up the work of your system's package manager.
* `When something breaks in your system configuration, it can take a long time to fix`. If you've messed up with you local system configuration, you either need to debug or reinstall your OS. Both of these can take a lot of your time and should be avoided.
* `You have no idea what is your development environment actually looks like`. Your local OS will certainly have its own specific configuration and packages installed, because you use it for every day tasks different than just running your application. For this reason, even if your application works on your local machine, you cannot describe exactly what is required for it to run. This is commonly known as `works on my machine` problem and is often one of the reasons for a conflict between Dev and Ops.

Based on these problems, let's draw some requirements for our local dev environment:

* `We should know exactly what is inside.` This is important, so that we could properly configure other environments for running the application.
* `Isolation from our local system.` This leaves us with choices of a local/remote VM or containers.
* `Ability to quickly and easily recreate when it breaks.`

Vagrant is a tool that allows to meet all of these requirements. Let's find out how.

## Install Vagrant and VirtualBox

NOTE: this lab assumes Vagrant `v2.0.1` is installed. It may not work as expected on other versions.

[Download](https://www.vagrantup.com/downloads.html) and install Vagrant on your system.

Verify that Vagrant was successfully installed by checking the version:

```bash
$ vagrant -v
```

[Download](https://www.virtualbox.org/wiki/Downloads) and install VirtualBox for running virtual machines locally.

Also, make sure virtualization feature is enabled for your CPU. You would need to check BIOS settings for this.

## Create a Vagrantfile

If we compare Vagrant to the previous tools we've already learned, it reminds Terraform. Like Terraform, Vagrant allows you to declaratively describe VMs you want to provision, but it focuses on managing VMs (and containers) exclusively, so it's no good for things like firewall rules or VPC networks in the cloud.

To start a local VM using Vagrant, we need to define its characteristics in a special file called `Vagrantfile`.

Create a file named `Vagrantfile` inside `iac-tutorial` directory with the following content:

```ruby
Vagrant.configure("2") do |config|
  # define provider configuration
  config.vm.provider :virtualbox do |v|
    v.memory = 1024
  end
  # define a VM machine configuration
  config.vm.define "raddit-app" do |app|
    app.vm.box = "ubuntu/xenial64"
    app.vm.hostname = "raddit-app"
  end
end
```

Vagrant, like Terraform, doesn't start VMs itself. It uses a `provider` component to communicate the instructions to the actual provider of infrastructure resources.

In this case, we redefine Vagrant's default provider (VirtualBox) configuration to allocate 1024 MB of memory to each VM defined in this Vagrantfile:

```ruby
# define provider configuration
config.vm.provider :virtualbox do |v|
  v.memory = 1024
end
```

We also specify characteristics of a VM we want to launch: what machine image (`box`) to use (Vagrant downloads a box from [Vagrant Cloud](https://www.vagrantup.com/docs/vagrant-cloud/boxes/catalog.html)), and what hostname to assign to a started VM:

```ruby
# define a VM machine configuration
config.vm.define "raddit-app" do |app|
  app.vm.box = "ubuntu/xenial64"
  app.vm.hostname = "raddit-app"
end
```

## Start a Local VM

With the Vagrantfile created, you can start a VM on your local machine using Ubuntu 16.04 image from Vagrant Cloud.

Run the following command inside the folder with your Vagrantfile:

```bash
$ vagrant up
```

Check the current status of the VM:

```bash
$ vagrant status
```

You can connect to a started VM via SSH using the following command:

```bash
$ vagrant ssh
```

## Configure Dev Environment

Now that you have a VM running on your local machine, you need to configure it to run your application: install ruby, mongodb, etc.

There are many ways you can do that, which are known to you by now. You can configure the environment manually, using scripts or some CM tool like Ansible.

_It's best to use the same configuration and the same CM tools across all of your environments._

As we've already discussed, your application may work in your local environment, but it may not work on a remote VM running in production environment, because of the differences in configuration. But when your configuration is the same across all of your environments, the application will not fail for reasons like a missing package and the system configuration can generally be excluded as a potential cause of a failure when it occurs.

Because we chose to use Ansible for configuring our production environment in the previous lab, let's use it for configuration management of our dev environment, too.

Change your Vagrantfile to look like this:

```ruby
Vagrant.configure("2") do |config|
  # define provider configuration
  config.vm.provider :virtualbox do |v|
    v.memory = 1024
  end
  # define a VM configuration
  config.vm.define "raddit-app" do |app|
    app.vm.box = "ubuntu/xenial64"
    app.vm.hostname = "raddit-app"
    # sync a local folder with application code to the VM folder
    app.vm.synced_folder "raddit-app/", "/srv/raddit-app"
    # use port forwarding make application accessible on localhost
    app.vm.network "forwarded_port", guest: 9292, host: 9292
    # system configuration is done by Ansible
    app.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/configuration.yml"
    end
  end
end
```

We added Ansible provisioning to the Vagrantfile which allows us to run a playbook for system configuration.

```ruby
# system configuration is done by Ansible
app.vm.provision "ansible" do |ansible|
  ansible.playbook = "ansible/configuration.yml"
end
```

In the previous lab, it was given to you as a task to create a `configuration.yml` playbook that provides the same functionality as `configuration.sh` script we had used before. If you did not do that, you can copy the playbook from [here](https://github.com/Artemmkin/infrastructure-as-code-example/blob/master/ansible/configuration.yml) (place it inside `ansible` directory). If you did create your own playbook, make sure you have a `pre_tasks` section as in [this example](https://github.com/Artemmkin/infrastructure-as-code-example/blob/master/ansible/configuration.yml).

Note, that we also added a port forwarding rule for accessing our application and instructed Vagrant to sync a local folder with application code to a specified VM folder (`/srv/raddit-app`):

```ruby
# sync a local folder with application code to the VM folder
app.vm.synced_folder "raddit-app/", "/srv/raddit-app"
# use port forwarding make application accessible on localhost
app.vm.network "forwarded_port", guest: 9292, host: 9292
```

Now run the following command to configure the local dev environment:

```bash
$ vagrant provision
```

Verify the configuration:

```bash
$ vagrant ssh
$ ruby -v
$ bundle version
$ sudo systemctl status mongod
```

## Run Application Locally

As we mentioned, we gave Vagrant the instruction to sync our folder with application to a VM's folder under the specified path. This way we can develop the application on our host machine using our favorite code editor and then run that code inside the VM.

We need to first reload a VM for chages in our Vagrantfile to take effect:

```bash
$ vagrant reload
```

Then connect to the VM to start application:

```bash
$ vagrant ssh
$ cd /srv/raddit-app
$ bundle install
$ puma
```

The application should be accessible to you now at the following URL: http://localhost:9292

Stop the application using `ctrl + C` keys.

## Mess Up Dev Environment

One of our requirements to local dev environment was that you can freely mess it up and recreate in no time.

Let's try that.

Delete Ruby on the VM:
```bash
$ vagrant ssh
$ sudo apt-get -y purge ruby
$ ruby -v
```

Try to run your application again (it should fail):

```bash
$ cd /srv/raddit-app
$ puma
```

## Recreate Dev Environment

Let's try to recreate our dev environment from scratch to see how big of a problem it will be.

Run the following commands to destroy the current dev environment and create a new one:

```bash
$ vagrant destroy -f
$ vagrant up
```

Once a new VM is up and running, try to launch your app in it:

```bash
$ vagrant ssh
$ ruby -v
$ cd /srv/raddit-app
$ bundle install
$ puma
```

The Ruby package should be present and the application should run without problems.

Recreating a new dev environment was easy, took very little time and it didn't affect our host OS. That's exactly what we needed.

## Save and commit the work

Save and commit the Vagrantfile created in this lab into your `iac-tutorial` repo.

## Conclusion

Vagrant was able to meet our requirements for dev environments. It makes creating/recreating and configuring a dev environment easy and safe for our host operating system.

Because we describe our local infrastructure in code in a Vagrantfile, we keep it in source control and make sure all our other colleagues have the same environment for the application as we do.

Destroy the VM:

```bash
$ vagrant destroy -f
```

Next: [Docker](08-docker.md)
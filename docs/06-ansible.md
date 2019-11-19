# Ansible

In the previous lab, you used Terraform to implement Infrastructure as Code approach to managing the cloud infrastructure resources. Yet, we have another type of tooling to discover and that is **Configuration Management** (CM) tools.

When talking about CM tools, we can often meet the acronym `CAPS` which stands for Chef, Ansible, Puppet and Saltstack - the most known and commonly used CM tools. In this lab, we're going to look at Ansible and see how CM tools can help us improve our operations.

## Intro

If you think about our current operations and what else there is to improve, you will probably see the potential problem in the deployment process.

The way we do deployment right now is by connecting via SSH to a VM and running a deployment script. And the problem here is not the connecting via SSH part, but running a script.

_Scripts are bad at long term management of system configuration, because they make common system configuration operations complex and error-prone._

When you write a script, you use a scripting language syntax (Bash, Python) to write commands which you think should change the system's configuration. And the problem is that there are too many ways people can write the code that is meant to do the same things, which is the reason why scripts are often difficult to read and understand. Besides, there are various choices as to what language to use for a script: should you write it in Ruby which your colleagues know very well or Bash which you know better?

Common configuration management operations are well-known: copy a file to a remote machine, create a folder, start/stop/enable a process, install packages, etc. So _we need a tool that would implement these common operations in a well-known tested way and provide us with a clean and understandable syntax for using them_. This way we wouldn't have to write complex scripts ourselves each time for the same tasks, possibly making mistakes along the way, but instead just tell the tool what should be done: what packages should be present, what processes should be started, etc.

This is exactly what CM tools do. So let's check it out using Ansible as an example.

## Install Ansible

NOTE: this lab assumes Ansible v2.4 is installed. It may not work as expected with other versions as things change quickly.

You can follow the instructions on how to install Ansible on your system from [official documentation](http://docs.ansible.com/ansible/latest/intro_installation.html).

I personally prefer installing it via [pip](http://docs.ansible.com/ansible/latest/intro_installation.html#latest-releases-via-pip) on my Linux machine.

Verify that Ansible was installed by checking the version:

```bash
$ ansible --version
```

## Infrastructure as Code project

Create a new directory called `ansible` inside your `iac-tutorial` repo, which we'll use to save the work done in this lab.

## Provision compute resources

Start a VM and create other GCP resources for running your application applying Terraform configuration you wrote in the previous lab:

```bash
$ cd ./terraform
$ terraform apply
```

## Deploy playbook

We'll rewrite our Bash script used for deployment using Ansible syntax.

Ansible uses **tasks** to define commands used for system configuration. Each Ansible task basically corresponds to one command in our Bash script.

Each task uses some **module** to perform a certain operation on the configured system. Modules are well tested functions which are meant to perform common system configuration operations.

Let's look at our `deploy.sh`  script first to see what modules we might need to use:

```bash
#!/bin/bash
set -e

echo "  ----- clone application repository -----  "
git clone https://github.com/Artemmkin/raddit.git

echo "  ----- install dependent gems -----  "
cd ./raddit
sudo bundle install

echo "  ----- start the application -----  "
sudo systemctl start raddit
sudo systemctl enable raddit
```

We clearly see here 3 different types of operations: cloning a git repo, installing gems via Bundler, and managing a service via systemd.

So we'll search for Ansible modules that allow to perform these operations. Luckily, there are modules for all of these operations.

Ansible uses YAML syntax to define tasks, which makes the configuration looks clean.

Let's create a file called `deploy.yml` inside the `ansible` directory:

```yaml
---
- name: Deploy Raddit App
  hosts: raddit-app
  tasks:
    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/Artemmkin/raddit.git'
        dest: /home/raddit-user/raddit
      register: clone

    - name: Install application dependencies
      become: true
      bundler:
        state: present
        chdir: /home/raddit-user/raddit
      when: clone.changed
      notify: restart raddit

  handlers:
  - name: restart raddit
    become: true
    systemd: name=raddit state=restarted
```

In this configuration file, which is called a **playbook** in Ansible terminology, we define 3 tasks:

The `first task` uses git module to pull the code from GitHub.

```yaml
- name: Fetch the latest version of application code
  git:
    repo: 'https://github.com/Artemmkin/raddit.git'
    dest: /home/raddit-user/raddit
  register: clone
```

The `name` that precedes each task is used as a comment that will show up in the terminal when the task starts to run.

`register` option allows to capture the result output from running a task. We will use it later in a conditional statement for running a `bundle install` task.

The second task runs bundler in the specified directory:

```yaml
- name: Install application dependencies
  become: true
  bundler:
    state: present
    chdir: /home/raddit-user/raddit
  when: clone.changed
  notify: restart raddit
```

Note, how for each module we use a different set of module options (in this case `state` and `chdir`). You can find full information about the options in a module's documentation.

In the second task, we use a conditional statement [when](http://docs.ansible.com/ansible/latest/playbooks_conditionals.html#the-when-statement) to make sure the `bundle install` task is only run when the local repo was updated, i.e. the output from running git clone command was changed. This allows us to save some time spent on system configuration by not running unnecessary commands.

On the same level as tasks, we also define a **handlers** block. Handlers are special tasks which are run only in response to notification events from other tasks. In our case, `raddit` service gets restarted only when the `bundle install` task is run.

## Inventory file

The way that Ansible works is simple: it connects to a remote VM (usually via SSH) and runs the commands that stand behind each module you used in your playbook.

To be able to connect to a remote VM, Ansible needs information like IP address and credentials. This information is defined in a special file called [inventory](http://docs.ansible.com/ansible/latest/intro_inventory.html).

Create a file called `hosts.yml` inside `ansible` directory with the following content (make sure to change the `ansible_host` parameter to public IP of your VM):

```yaml
raddit-app:
  hosts:
    raddit-instance:
      ansible_host: 35.35.35.35
      ansible_user: raddit-user
```

Here we define a group of hosts (`raddit-app`) under which we list the hosts that belong to this group. In this case, we list only one host under the hosts group and give it a name (`raddit-instance`) and information on how to connect to the host.

Now note, that inside our `deploy.yml` playbook we specified `raddit-app` host group in the `hosts` option before the tasks:

```yaml
---
- name: Deploy Raddit App
  hosts: raddit-app
  tasks:
  ...
```

This will tell Ansible to run the following tasks on the hosts defined in hosts group `raddit-app`.

## Ansible configuration

Before we can run a deployment, we need to make some configuration changes to how Ansible views and manages our `ansible` directory.

Let's define custom Ansible configuration for our directory. Create a file called `ansible.cfg` inside the `ansible` directory with the following content:

```ini
[defaults]
inventory = ./hosts.yml
private_key_file = ~/.ssh/raddit-user
host_key_checking = False
```

This custom configuration will tell Ansible what inventory file to use, what private key file to use for SSH connection and to skip the host checking key procedure.

## Run playbook

Now it's time to run your playbook and see how it works.

Use the following commands to start a deployment:

```bash
$ cd ./ansible
$ ansible-playbook deploy.yml
```

## Access Application

Access the application in your browser by its public IP (don't forget to specify the port 9292) and make sure application has been deployed and is functional.

## Futher Learning Ansible

There's a whole lot to learn about Ansible. Try playing around with it more and create a `playbook` which provides the same system configuration as your `configuration.sh` script. Save it under the name `configuration.yml` inside the `ansible` folder, then use it inside [ansible provisioner](https://www.packer.io/docs/provisioners/ansible.html) instead of shell in your Packer template.

You can find an example of `configuration.yml` playbook [here](https://github.com/Artemmkin/infrastructure-as-code-example/blob/master/ansible/configuration.yml).

And [here](https://github.com/Artemmkin/infrastructure-as-code-example/blob/master/packer/raddit-base-image-ansible.json) is an example of a Packer template which uses ansible provisioner.

## Save and commit the work

Save and commit the `ansible` folder created in this lab into your `iac-tutorial` repo.

## Idempotence

One more advantage of CM tools over scripts is that commands they implement designed to be **idempotent** by default.

Idempotence in this case means that even if you apply the same configuration changes multiple times the result will stay the same.

This is important because some commands that you use in scripts may not produce the same results when run more than once. So we always want to achieve idempotence for our configuration management system, sometimes applying conditionals statements as we did in this lab.

## Conclusion

Ansible provided us with a clean YAML syntax for performing common system configuration tasks. This allowed us to get rid of our own implementation of configuration commands.

It might not seem like a big improvement at this scale, because our deploy script is small, but it definitely brings order to system configuration management and is more noticeable at medium and large scale.

Destroy the resources created by Terraform.

```bash
$ terraform destroy
```

Next: [Vagrant](07-vagrant.md)

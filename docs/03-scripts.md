# Scripts

In the previous lab, you deployed the [node-svc](https://github.com/dm-academy/node-svc) application by connecting to a VM via SSH and running commands in the terminal one by one. In this lab, we'll try to automate this process a little by using `scripts`.

## Intro

Now think about what happens if your application becomes so popular that one virtual machine can't handle all the load of incoming requests. Or what happens when your application somehow crashes? Debugging a problem can take a long time and it would most likely be much faster to launch and configure a new VM than trying to fix what's broken.

In all of these cases we face the task of provisioning new virtual machines, installing the required software and repeating all of the configurations we've made in the previous lab over and over again.

Doing it manually is boring, error-prone and time-consuming.

The most obvious way for improvement is using Bash scripts which allow us to run sets of commands put in a single file. So let's try this.

## Infrastructure as Code project

Starting from this lab, we're going to use a git repo for saving all the work done in this tutorial.

Go to your Github account and create a new repository called iac-repo. No README or .gitignore. Copy the URL. 

Clone locally: 

```bash
$ git clone <Github URL of your new repository>
```

Create a directory for this lab:

```bash
$ cd iac-repo
$ mkdir 03-script
$ cd 03-script
```

To push your changes up to Github: 

```bash
$ git add . -A
$ git commit -m "first lab 03 commit" # should be relevant to the changes you made
$ git push origin master
```

Always issue these commands several times during each session. 

## Provisioning script

We can automate the process of creating the VM and the firewall rule. 

In the `script` directory create a script `provision.sh`: 

```bash
#!/bin/bash
# add new VM
gcloud compute instances create node-svc \
    --image-family ubuntu-minimal-2004-lts \
    --image-project ubuntu-os-cloud \
    --boot-disk-size 10GB \
    --machine-type f1-micro

# add firewall rule
gcloud compute firewall-rules create allow-node-svc-tcp-3000 \
    --network default \
    --action allow \
    --direction ingress \
    --rules tcp:3000 \
    --source-ranges 0.0.0.0/0
```

Run it in the Google Cloud Shell: 

```bash
$ chmod +x provision.sh  # changing permissions 
$ ./provision.sh # you have to include the './'
```

You should see results similar to: 

```bash
WARNING: You have selected a disk size of under [200GB]. This may result in poor I/O performance. For more information, see: https://developers.google.com/compute/docs/disks#performance.
Created [https://www.googleapis.com/compute/v1/projects/proven-sum-252123/zones/us-central1-c/instances/node-svc].
NAME      ZONE           MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP    EXTERNAL_IP  STATUS
node-svc  us-central1-c  n1-standard-1               10.128.15.202  34.69.206.6  RUNNING
Creating firewall...⠹Created [https://www.googleapis.com/compute/v1/projects/proven-sum-252123/global/firewalls/allow-node-svc-3000].
Creating firewall...done.
NAME                 NETWORK  DIRECTION  PRIORITY  ALLOW     DENY  DISABLED
allow-node-svc-3000  default  INGRESS    1000      tcp:3000        False
```

## Installation script

Before we can run our application, we need to create a running environment for it by installing dependent packages and configuring the OS. Then we copy the application, initialize NPM and download express.js, and start the server.

We are going to use the same commands we used before to do that, but this time, instead of running commands one by one, we'll create a `bash script` to save us some struggle.

In the `03-script` directory create bash script `config.sh` to install node, npm, express, and git. Create a script `install.sh` to download the app and initialize node.

```bash
#!/bin/bash
set -e  # exit immediately if anything returns non-zero. See https://www.javatpoint.com/linux-set-command

echo "  ----- install node, npm, git -----  "
apt-get update
apt-get install -y nodejs npm git
```

```bash
#!/bin/bash
set -e  # exit immediately if anything returns non-zero. See https://www.javatpoint.com/linux-set-command

echo "  ----- download, initialize, and run app -----  "
git clone https://github.com/dm-academy/node-svc-v1
cd node-svc-v1
git checkout 02
npm install
npm install express 
```

NOTE: Why two scripts? Discuss in class.    


## Run the scripts

Copy the script to the created VM:

```bash
$ INSTANCE_IP=$(gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances describe node-svc)
$ scp -r config.sh install.sh node-user@${INSTANCE_IP}:/home/node-user
```

If sucessful, you should see something like: 

```bash
config.sh                                                              100%  214   279.9KB/s   00:00    
install.sh                                                              100%  214   279.9KB/s   00:00    
```

NOTE: If you get an `offending ECDSA key` error, use the suggested removal command. 

NOTE: If you get the error `Permission denied (publickey).`, this probably means that your ssh-agent no longer has the node-user private key added. This easily happens if the Google Cloud Shell goes to sleep and wipes out your session. Check via issuing `ssh-add -l`. 

If you get a message to the effect that your agent is not running, type ``eval `ssh-agent` `` and then `ssh-add -l`.

You should see something like `2048 SHA256:bII5VsQY3fCWXEai0lUeChEYPaagMXun3nB9U2eoUEM /home/betz4871/.ssh/node-user (RSA)`. If you do not, re-issue the command `ssh-add ~/.ssh/node-user` and re-confirm with `ssh-add -l`.


Connect to the VM via SSH:
```bash
$ ssh node-user@${INSTANCE_IP}
```
Have a look at what's in the directory (use `ls` and `cat`). Do you understand exactly how it got there? If you do not, ask. 

Run the script and launch the server:
```bash
$ chmod +x *.sh
$ sudo ./config.sh && ./install.sh # running 2 commands on one line
$ sudo nodejs node-svc-v1/server.js &
```
The last output should be `Running on 3000`. You may need to hit Return or Enter to get a command prompt. 

To test that the server is running locally, type:
```bash
$ curl localhost:3000
```
You should receive this:

```bash
Successful request.
```
## Access the Application

Access the application in your browser by its public IP (don't forget to specify the port 3000).

Open another terminal and run the following command to get a public IP of the VM:

```bash
$ gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances describe node-svc
```
## Destroy (de-provision) the resources by script

In the `provision` directory create a script `deprovision.sh`. 

```bash
#!/bin/bash
gcloud compute instances delete -q node-svc
gcloud compute firewall-rules delete -q allow-node-svc-tcp-3000
```

Set permissions correctly (see previous) and execute. You should get results like:

```bash
Deleted [https://www.googleapis.com/compute/v1/projects/proven-sum-252123/zones/us-central1-c/instances/node-svc].
Deleted [https://www.googleapis.com/compute/v1/projects/proven-sum-252123/global/firewalls/allow-node-svc-tcp-3000].```

## Save and commit the work

Save and commit the scripts created in this lab into your `iac-tutorial` repo.

## Conclusion

Scripts helped us to save some time and effort of manually running every command one by one to configure the system and start the application.

The process of system configuration becomes more or less standardized and less error-prone, as you put commands in the order they should be run and test it to ensure it works as expected.

It's also a first step we've made in the direction of automating operations work.

But scripts are not suitable for every operations task and have many downsides. We'll discuss more on that in the next labs.


Next: [Packer](04-packer.md)

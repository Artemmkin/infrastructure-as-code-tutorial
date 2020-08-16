# Manual Operations

To better understand the `Infrastructure as Code` (`IaC`) concept, we will first define the problem we are facing and deal with it with manually to get our hands dirty and see how things work overall.

## Intro

Imagine you have developed a new cool application called [node-svc](https://github.com/dm-academy/node-svc-v1).

You want to run your application on a dedicated server and make it available to the Internet users.

You heard about the `public cloud` thing, which allows you to provision compute resources and pay only for what you use. You believe it's a great way to test your idea of an application and see if people like it.

You've signed up for a free tier of [Google Cloud Platform](https://cloud.google.com/) (GCP) and are about to start deploying your application.

## Provision Compute Resources

First thing we will do is to provision a virtual machine (VM) inside GCP for running the application.

Use the following gcloud command in your terminal to launch a VM with Ubuntu 16.04 distro:

```bash
$ gcloud compute instances create  node-svc\
    --image-family ubuntu-minimal-2004-lts  \
    --image-project ubuntu-os-cloud \
    --boot-disk-size 10GB \
    --machine-type f1-micro
```

## Create an SSH key pair

Generate an SSH key pair for future connections to the VM instances (run the command exactly as it is):

```bash
$ ssh-keygen -t rsa -f ~/.ssh/node-user -C node-user -P ""
```

Create an SSH public key for your project:

```bash
$ gcloud compute project-info add-metadata \
    --metadata ssh-keys="node-user:$(cat ~/.ssh/node-user.pub)"
```

Check your ssh-agent is running:

```bash
$ echo $SSH_AGENT_PID
```
If you get a number, it is running. If you get nothing, then run: 

```bash
$ eval `ssh-agent`
```

Add the SSH private key to the ssh-agent:

```
$ ssh-add ~/.ssh/node-user
```

Verify that the key was added to the ssh-agent:

```bash
$ ssh-add -l
```

## Install Application Dependencies

To start the application, you need to first configure the environment for running it.

Connect to the started VM via SSH using the following two commands:

```bash
$ INSTANCE_IP=$(gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances describe node-svc)
$ ssh node-user@${INSTANCE_IP}
```

Install Node and npm:

```bash
$       
$ sudo apt-get install -y nodejs npm 
```

Check the installed version of Node:

```bash
$ node -v
```

Install `git`:
```bash
$ sudo apt -y install git
```

Clone the application repo into the home directory of `node-user` user (reminder, how do you clone to the right location?):

```bash
$ git clone https://github.com/dm-academy/node-svc-v1
```
Navigate to the repo (`cd node-svc-v1`) and check out the 02 branch (matching this lesson)

```bash
$ git checkout 02
Branch 02 set up to track remote branch 02 from origin.
Switched to a new branch '02'
```

Initialize npm (Node Package Manager) and install express:

```bash
$ npm install
$ npm install express
```

## Start the Application

Look at the server.js file (`cat`). We will discuss in class. 

Start the Node web server: 

```bash
$ nodejs server.js &
Running on 3000
```

Test it: 

```bash
$ curl localhost:3000
Successful request.
```


## Access the Application

Open a firewall port the application is listening on (note that the following command should be run on the Google Cloud Shell):

```bash
$ gcloud compute firewall-rules create allow-node-svc-tcp-3000 \
    --network default \
    --action allow \
    --direction ingress \
    --rules tcp:3000 \
    --source-ranges 0.0.0.0/0
```

Get the public IP of the VM:

```bash
$ gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances describe node-svc-instance
```

Now open your browser and try to reach the application at the public IP and port 3000.

For example, I put in my browser the following URL http://104.155.1.152:3000, but note that you'll have your own IP address.

## Conclusion

Congrats! You've just deployed your application. It is running on a dedicated set of compute resources in the cloud and is accessible by a public IP. Now Internet users can enjoy using your application.

Now that you've got the idea of what sort of steps you have to take to deploy your code from your local machine to a virtual server running in the cloud, let's see how we can do it more efficiently.

Destroy the current VM and firewall rule and move to the next step:

```bash
$ gcloud compute instances delete -q node-svc
$ gcloud compute firewall-rules delete -q allow-node-svc-tcp-9292 
```

Next: [Scripts](03-scripts.md)

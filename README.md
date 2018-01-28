# Infrastructure As Code Tutorial

[![GitHub contributors](https://img.shields.io/github/contributors/Artemmkin/infrastructure-as-code-tutorial.svg)](https://github.com/Artemmkin/infrastructure-as-code-tutorial/graphs/contributors)

This tutorial is intended to show what the **Infrastructure as Code** (**IaC**) is, why we need it, and how it can help you manage your infrastructure more efficiently.

It is practice-based, meaning I don't give much theory on what Infrastructure as Code is in the beginning of the tutorial, but instead let you feel it through the practice first. At the end of the tutorial, I summarize some of the key points about Infrastructure as Code based on what you learn through the labs.

This tutorial is not meant to give a complete guide on how to use a specific tool like Ansible or Terraform, instead it focuses on how these tools work in general and what problems they solve.

> The tutorial was inspired by [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) tutorial. I used it as an example to structure this one.

## Target Audience

The target audience for this tutorial is anyone who loves or/and works in IT.

## Tools Covered

* Packer
* Terraform
* Ansible
* Vagrant
* Docker
* Docker Compose

## Results of completing the tutorial

By the end of this tutorial, you'll make your own repository looking like [this one](https://github.com/Artemmkin/infrastructure-as-code-example).

NOTE: you can use this [example repository](https://github.com/Artemmkin/infrastructure-as-code-example) in case you get stuck in some of the labs.

## Labs

This tutorial assumes you have access to the Google Cloud Platform. While GCP is used for basic infrastructure requirements the lessons learned in this tutorial can be applied to other platforms.

* [Introduction](docs/00-introduction.md)
* [Prerequisits](docs/01-prerequisites.md)
* [Manual Operations](docs/02-manual-operations.md)
* [Scripts](docs/03-scripts.md)
* [Packer](docs/04-packer.md)
* [Terraform](docs/05-terraform.md)
* [Ansible](docs/06-ansible.md)
* [Vagrant](docs/07-vagrant.md)
* [Docker](docs/08-docker.md)
* [Docker Compose](docs/09-docker-compose.md)
* [What is Infrastructure as Code](docs/50-what-is-iac.md)
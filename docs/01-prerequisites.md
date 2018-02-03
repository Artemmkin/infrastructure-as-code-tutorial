# Prerequisites

## Red Hat Linux Variant

The tutorial uses an RPM-based Linux, which can be RHEL (Red Hat Enterprise Linux), Fedora or CentOS. You must have root access to the platform. It can be a physical system, or a virtual machine.

## Google Cloud Platform

In this tutorial, we use the [Google Cloud Platform](https://cloud.google.com/) to provision the compute infrastructure. You can [sign up](https://cloud.google.com/free/) for $300 in free credits (good for 1 year), which will be more than sufficient to complete all of the labs in this tutorial.

## Google Cloud Platform SDK

### Install the Google Cloud SDK

Follow the Google Cloud SDK [documentation](https://cloud.google.com/sdk/) to install and configure the `gcloud` command line utility for your platform.

Verify the Google Cloud SDK version is 183.0.0 or higher:

```bash
$ gcloud version
```

### Set Application Default Credentials

This tutorial assumes Application Default Credentials (ADC) were set to authenticate to Google Cloud Platform API.

Use the following gcloud command to acquire new user credentials to use for ADC.

```bash
$ gcloud auth application-default login
```

### Set a Default Project, Compute Region and Zone

This tutorial assumes a default compute region and zone have been configured.

Set a default compute region:

```bash
$ gcloud config set compute/region europe-west1
```

Set a default compute zone:

```bash
$ gcloud config set compute/zone europe-west1-b
```

Verify the configuration settings:

```bash
$ gcloud config list
```

Next: [Manual operations](02-manual-operations.md)

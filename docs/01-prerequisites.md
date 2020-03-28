# Prerequisites

## Google Cloud Platform

In this tutorial, we use the [Google Cloud Platform](https://cloud.google.com/) to provision the compute infrastructure. You have already signed up. 

Start in the Google Cloud Shell. [(review)](https://cloud.google.com/shell/docs/using-cloud-shell)

## Google Cloud Platform
### Set a Default Project, Compute Region and Zone

This tutorial assumes a default compute region and zone have been configured.

Set a default compute region appropriate to your location ([GCP regions and zones](https://cloud.google.com/compute/docs/regions-zones)):

```bash
$ gcloud config set compute/region us-central1
```

Set a default compute zone appropriate to the zone:

```bash
$ gcloud config set compute/zone us-central1-c
```

Verify the configuration settings:

```bash
$ gcloud config list
```

Next: [Manual operations](02-manual-operations.md)

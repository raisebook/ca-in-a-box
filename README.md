# CA in a box!

CA in a box provides an easy-to-use way of generating SSL/TLS certificates for use with your local development projects.
 
It creates a Root Certificate Authority (CA), which is then used for generating certificates for your services.

The data is stored and synced with an AWS S3 bucket, so anyone on your team (with permissions), can create certificates, and anyone can download and use them.
 
It is simply then a case of installing the root certificate on your development machines, and all your local services will be able to use HTTPS without any more irritating warnings!


## Setup

### Prerequisites

1. Docker and `docker-compose`
1. An Amazon S3 bucket for storage
1. An AWS KMS Key to encrypt the bucket

## Usage

## Installing the Root Certificate

### OSX

### Linux

### Windows

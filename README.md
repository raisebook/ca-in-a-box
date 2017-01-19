# CA in a box!

CA in a box provides an easy-to-use way of generating SSL/TLS certificates for use with your local development projects.
 
It creates a Root Certificate Authority (CA), which is then used for generating certificates for your services.

The data is stored and synced with an AWS S3 bucket, so anyone on your team (with permissions), can create certificates, and anyone can download and use them.
 
It is simply then a case of installing the root certificate on your development machines, and all your local services will be able to use HTTPS without any more irritating warnings!

Don't use these certificates in production! Bad robot!

## Setup

### Prerequisites

1. Docker and `docker-compose`, and have `make` available on your system
1. An Amazon S3 bucket for storage
1. An AWS KMS Key to encrypt the bucket

### Instructions
 
1. Clone the repo
1. run `make setup` - This will copy the config example file, and open it in $EDITOR. 
  If you are setting up the CA for the _first time_ then fill out all the values, otherwise just set the CA_BUCKET and CA_KMS_KEY
  1. `CA_BUCKET` is the name of the S3 bucket where the CA files will be uploaded
  1. `CA_KMS_KEY` is the KMS key-id which will be used to encrypt the stored files. This can be the ID, or in the `alias/KeyName` form
  1. The remaining fields will be what's used to produce the root and intermediate certificates


## Usage

1. run `make`

If it is the first-time setup, the root and intermediate certificates will be automatically generated, based on the configuration set above.

`ca-in-a-box` will prompt you for the Server CA Password. This is the password for the CA itself, and should be kept securely.

Once the initial setup is done, `ca-in-a-box` will prompt for a Server Common Name. 
This is the CN for the actual certificate  for the project you are working on, e.g. _myservice.mydomain.dev_
  
This will generate, and once accepted, will ask you if you want to commit the new certificate to shared storage. 
Saying yes to this will upload the newly generated certificate and key (in the output/ dir), to S3, so that others may use it.  

## Installing the Root Certificate

In order to have these generated certificates accepted on development machines (again, don't use these in production!), you must install the 
root certificate chain. Luckily, the above process will put it in  `output/ca-chain.cert.pem`. This can then be imported and trusted as below:
 

### OSX

1. `open output/ca-chain.cert.pem`
1. This will open the Keychain Manager.
1. Select the System Keychain, and then Certificates
1. Double-click on your _root_ certificate. It should be the one with the little red mark next to it
1. Select "always trust" from the "When using this certificate" option. It should be the topmost dropdown.
1. The icon for the certificate should change to a blue plus sign
1. Close the Keychain Manager, and you should be ready to go!

### Linux

TBD

### Windows

TBD

#!/bin/bash

source hcp.env

packer init .
packer fmt .
packer validate .
packer build boundary-worker.pkr.hcl
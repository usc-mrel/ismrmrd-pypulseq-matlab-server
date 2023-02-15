# FIRE Matlab Server

## **Please use kSpaceKelvin's matlab server for new development, this repo is only for interaction during the talk and will not be maintained.**

A lightweight ISMRMRD-compatible image reconstruction server written in MATLAB, inspired by Kristoffer Knudsen's [Gadgetron Python ISMRMRD Server](https://github.com/kristofferknudsen/gadgetron-python-ismrmrd-server).

## Getting Started

Begin by cloning the repository

```
git clone git@github.com:usc-mrel/mrel-talk-matlab-server.git
```

The server can either be run as a simple MATLAB-script

```
matlab -nodesktop -nosplash -r fire_matlab_ismrmrd_server(9002)
```

or in Octave.

```
octave-cli --eval "fire_matlab_ismrmrd_server(9002)"
```

It is also designed to be run from a Docker container

```
cd docker
docker build --tag=fire_matlab_ismrmrd_server .
docker run -p 9002:9002 -t --name fire_matlab --detach fire_matlab_ismrmrd_server
```

If you are using the matlab-server together with the FIRE WIP, the Application Guide contains information on creating a chroot-image which can be deployed on the scanner.


## Authors

* **Alexander Fyrdahl** (alexander.fyrdahl@gmail.com) - *Initial work* - 
* **Prakash Kumar** (prakashk@usc.edu) - *Simple modifications for MREL talk* -

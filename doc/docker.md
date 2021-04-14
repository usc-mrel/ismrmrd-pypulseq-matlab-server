# MATLAB and Docker
MATLAB code can be compiled into a standalone application and run inside a Docker container, allowing for easy sharing and deployment without requiring a MATLAB license.  Starting in R2020b, MATLAB [supports](https://www.mathworks.com/help/compiler/package-matlab-standalone-applications-into-docker-images.html) the automatic creation of a Docker image.  A [Dockerfile](../docker/MATLAB_R2021a/Dockerfile) is provided here that creates a Docker image with (licensed) MATLAB installed, enabling the creation of (unlicensed) standalone MATLAB applications in Docker images.

## Creating the MATLAB Docker Image
Obtain the MATLAB installer for Linux from either your license administrator or directly from the MathWorks webpage at https://www.mathworks.com/downloads/.  If you are an administrator for your MATLAB license, there is the option of downloading an installation .iso file for all toolboxes.  If not, download the regular web installer appropriate for your operating system.  Run the installer and log into your MathWorks account.  Click on "Advanced Options" on the top right and select "I want to download without installing".  Select "Linux" as the platform to download files for and select options for at least MATLAB, Instrument Control Toolbox, and MATLAB Compiler.  Determine what additional product licenses are required by individual programs by using [matlab.codetools.requiredfilesandproducts](https://www.mathworks.com/help/matlab/ref/matlab.codetools.requiredfilesandproducts.html).

In both cases, create a folder in the root of the Docker build context named ``R2021a`` and copy the contents of the installer inside.  This folder should contain files such as ``install`` and ``installer_input.txt``.

## MATLAB License Types
Standalone MATLAB licenses are usually associated with the network card MAC address.  The MAC address of a Docker container can be set during ``docker run``:
```
docker run --mac-address DE:AD:BE:EF:00:00 ...
```

Network MATLAB licenses are usually associated with a username/hostname combination.  The hostname can be set during ``docker run``:
```
docker run --hostname computername ...
```

The username can be set by uncommenting the following lines in the Dockerfile and modifying with the appropriate username:
```
RUN useradd -ms /bin/bash username
USER username
```

If a username-based MATLAB license file is used, then the Docker container is run as a non-root user.  If so, the default permissions of ``/var/run/docker.sock`` may not allow for non-root users to run Docker.  Test this case by starting this Docker container (as a non-root user), then attempting to run another nested Docker container:
```
docker run --rm hello-world
```

If the error ``Got permission denied ... /var/run/docker.sock: connect: permission denied"``
appears, then the permissions must be changed.  Stop the Docker container and start a new container with a root user:
```
docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock ubuntu
```

Check the current permissions:
```
root@4452a07646c8:/# ls -la /var/run/docker.sock
srwxr-xr-x 1 root root 0 Apr  8 02:11 /var/run/docker.sock
```

Add write permissions for all users:
```
chmod go+w /var/run/docker.sock
```

Verify that the permissions have been changed:
```
root@4452a07646c8:/# ls -la /var/run/docker.sock
srwxrwxrwx 1 root root 0 Apr  8 02:11 /var/run/docker.sock
```

Exit the Docker container, start a non-root user Docker container, and verify that ``docker run --rm hello-world`` runs without errors,.

## Additional installer files
Create and place the following files in the root of the build context:
1. ``installer_input_docker.txt``
    - MATLAB is installed without interactive user input during the Docker build process.  Installer options are configured using this text file.  Create a copy of the ``installer_input.txt`` file from the base folder of the MATLAB installer named ``installer_input_docker.txt`` and set the following fields:
        - ``fileInstallationKey`` (corresponding to the license)
        - ``agreeToLicense=yes``
        - ``licensePath=/tmp/license.lic``
    - At the bottom of the file, select the toolboxes to be installed.  Any toolboxes required for the MATLAB reconstruction code must be installed and the following 3 licenses are required:
        - ``product.MATLAB``
        - ``product.MATLAB_Compiler``
        - ``product.Instrument_Control_Toolbox``

2. ``license.lic``
    - Create a copy the MATLAB license file and name it ``license.lic``

3. ``MATLAB_Runtime_R2021a_glnxa64.zip`` (optional)
    - During the build process, the MATLAB Runtime is downloaded and installed.  It is approximately 3.9 GB in size and it may be desirable to download this file separate from the build process, such as when debugging Docker build issues or when running on a computer with limited bandwidth.  The MATLAB Runtime installation files can be found at https://www.mathworks.com/products/compiler/matlab-runtime.html.  Download the Linux version corresponding to the MATLAB version that is being installed, then uncomment the following lines in the Dockerfile:
        ```
        RUN mkdir /root/MCRInstaller9.10
        COPY MATLAB_Runtime_R2021a_glnxa64.zip /root/MCRInstaller9.10/
        RUN /usr/local/MATLAB/R2021a/bin/matlab -r "compiler.internal.runtime.utils.setInstallerLocation('/root/MCRInstaller9.10/MATLAB_Runtime_R2021a_glnxa64.zip'); quit"
        ```
    - If a username-based MATLAB license file is used, then replace ``/root/`` in the above commands (3 instances) with ``/home/username/``, where ``username`` is the licensed username.
    - If adapting for other MATLAB versions, the path ``/root/MCRInstaller9.10`` must also be adapted to the appropriate MATLAB Runtime version (listed on the download webpage)

## Create the MATLAB Compiler Docker Image
In the folder containing the MATLAB installer folder and above files, open a command prompt and run the following command:
```
docker build --no-cache -t fire-matlab-compiler -f matlab-ismrmrd-server/docker/MATLAB_R2021a/Dockerfile ./
```

## Compiling the MATLAB MRD Server Into a Docker Image
This Docker image can be used to compile the MATLAB MRD server code and build a Docker image where it can run without a MATLAB license.

Start Docker with the following options:
```
docker run                                                \
            -it --rm                                      \ # Create an interactive terminal and delete the container when done
            --mac-address DE:AD:BE:EF:00:00               \ # Set the MAC address, if required by the MATLAB license
            --hostname computername                       \ # Set the hostname, if required by the MATLAB license
            -v /var/run/docker.sock:/var/run/docker.sock  \ # Enable Docker within Docker functionality
            -v /code:/code                                \ # Share a folder where code can accessed
            -p 9002:9002                                  \ # Forward the MRD network port if testing the server
            fire-matlab-compiler
```

In the MATLAB Command Prompt, change to the folder containing the server code:
```
cd /code/matlab-ismrmrd-server
```

Verify that the server runs correctly and is able to process data by starting the server:
```
fire_matlab_ismrmrd_server
```

Compile the server as a standalone application and build the Docker image:
```
res = compiler.build.standaloneApplication('fire_matlab_ismrmrd_server.m', 'TreatInputsAsNumeric', 'on')
opts = compiler.package.DockerOptions(res, 'ImageName', 'fire-matlab-server')
compiler.package.docker(res, 'Options', opts)
```

Quit MATLAB and exit the Docker container when complete.  The new MRD Server Docker image should be visible on the host computer with the name ``fire-matlab-server``.  It can be started with:
```
docker run --rm -p 9002:9002 fire-matlab-server
```

## Adding Toolboxes to the MATLAB Compiler Docker Image
If additional MATLAB toolboxes are required after the compiler Docker image has been made, it is possible to add toolboxes to the image.

Use the modified ``installer_input_docker.txt`` file above, but select only the new toolboxes to be installed.  In a folder, collect the ``R2021a`` installer folder, ``installer_input_docker.txt``, ``license.lic``.  In this folder, create a file named ``Dockerfile`` with the following contents:
```
FROM fire-matlab-compiler
COPY installer_input_docker.txt /tmp/
COPY license.lic                /tmp/
RUN --mount=type=bind,source=R2021a,target=/tmp/R2021a /tmp/R2021a/install -inputFile /tmp/installer_input_docker.txt
```

In this folder, open a command prompt and build the new Docker image:
```
docker build --no-cache -t fire-matlab-compiler-new ./
```
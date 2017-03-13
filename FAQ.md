# Frequently Asked Questions about the Repo

1. We need root to start OpenVPN connections.

    OpenVPN connections do not require root access; the GNOME network manger allows standard users to add and start VPN connection profiles. Edit the profile once loaded and remove the default setting to route all traffic over the VPN if you are using split tunneling, and deselect "Available to all users".

1. We need users to be added to the Docker group so that can run docker commands.

    Allowing users to run docker locally would enable them to start privileged containers, this in turn would give them root access on the base machine which is a break in the security of the platform. As such only the docker client can run locally against either a remote docker target or the local minikube instance.


1. The install script encounters an exception at the step `pip install docker-py==1.9.0`.

    If you are using a proxy, try destroying and rebuilding the cache:

    ``` 
    docker stop cache
    docker rm cache
    docker rmi cache
    docker build -t cache .
    ```

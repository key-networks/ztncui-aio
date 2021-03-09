# ztncui-aio
## ZeroTier network controller user interface in a Docker container

This is to build a Docker image that contains **[ZeroTier One](https://www.zerotier.com/download.shtml)** and **[ztncui](https://key-networks.com/ztncui)** to set up a **standalone ZeroTier network controller** with a web user interface in a container.

Follow us on [![alt @key_networks on Twitter](https://i.imgur.com/wWzX9uB.png)](https://twitter.com/key_networks)

Licensed Under GNU GPLv3

## Credit
Thanks to @kmahyyg for https://github.com/kmahyyg/ztncui-aio from which this build process is forked.

## Further information
Refer to https://github.com/key-networks/ztncui-containerized for the original documentation.

## Usage

```bash
$ git clone https://github.com/key-networks/ztncui-aio # to get a copy of denv file, otherwise make your own
$ docker pull keynetworks/ztncui
$ docker run -d -p3443:3443 -p3180:3180 \
    -v /mydata/ztncui:/opt/key-networks/ztncui/etc \
    -v /mydata/zt1:/var/lib/zerotier-one \
    --env-file ./denv <CHANGE HERE ACCORDING TO NEXT PART> \
    --name ztncui \
    keynetworks/ztncui
```

## Supported Configuration via persistent storage

For ZTNCUI: https://github.com/key-networks/ztncui

| REQUIRED | Name | Explanation | Default Value |
|:--------:|:--------:|:--------:|:--------:|
| YES | NODE_ENV | https://pugjs.org/api/express.html | production |
|  no  | HTTPS_HOST | Only Listen on HTTPS_HOST:HTTPS_PORT | NO DEFAULT |
| no | HTTPS_PORT | HTTPS_PORT | 3443 |
| no | HTTP_PORT | HTTP_PORT | 3000 |
| no | HTTP_ALL_INTERFACES | Listen on all interfaces | NO DEFAULT |

This image additional specific:

| REQUIRED | Name | Explanation | Default Value |
|:--------:|:--------:|:--------:|:--------:|
| no | MYDOMAIN | generate TLS certs on the fly (if not exists) | ztncui.docker.test |
| no | ZTNCUI_PASSWD | generate admin password on the fly (if not exists) | password |
| YES | MYADDR | your ip address, public ip address preferred | NO DEFAULT |

Also, this image exposed an http server at port 3180, you could save file in `/mydata/ztncui/myfs/` to serve it. (You could use this to build your own root server and distribute planet file)

**WARNING: IF YOU DO NOT SET PASSWORD, YOU HAVE TO USE `docker exec -it <CONTAINER NAME> bash`, and then `cat /var/log/docker-ztncui.log` to get your random password. This is gatekeeper.**

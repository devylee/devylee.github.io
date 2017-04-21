---
title     : Mac下Docker的使用
date      : "2017-04-17 14:00:00"
categories: devy
tags      : 
  - Docker
  - macOS
  - MacPorts
layout    : post
class     : "post tag-docker tag-macos tag-macports"
comments  : true
---

> 自从接触了[Docker](https://www.docker.com/)，我就深深的觉得：**Docker的使用应该是一个开发人员，尤其是基于Linux的Web服务端开发人员应该具备的基本技能之一！**其实Docker的使用也并不复杂，熟悉两个命令`docker`、`docker-machine`和一个`Dockerfile`就可以在你的本机开发环境中跑起来了。

<!--more-->

Docker最具价值的功能在于它可以实现将应用部署完全的程序化，由此，我们创建一个主机、部署一个应用不再需要重复的人工操作，基于它背后庞大的镜像社区[Docker Hub](https://hub.docker.com/)，一行命令就可以搞定一台虚拟机，一个Dockerfile就可以部署一个应用……这样不但提高了部署效率也大大降低人工操作的出错风险。更重要的是，这也让更多自动化的需求成为可能，比如：在系统负载过高时自动部署应用镜像来均衡负载，提高系统稳定性！

## 安装

我是一个忠实的Mac用户，在Mac下安装使用Docker也不止一种途径，比如官方提供的：[Docker for Mac](https://www.docker.com/docker-mac)和[Docker Toolbox](https://www.docker.com/products/docker-toolbox)。
> 如果你的系统版本够高，我其实更推荐使用Docker for Mac，因为Docker Toolbox需要另外安装[VirtualBox](https://www.virtualbox.org/)。

我是个[MacPorts](https://www.macports.org/)的重度用户，在电脑的使用上还有严重的洁癖！所以我的Docker环境是用MacPorts维护的（当然你也可以选择[homebrew](https://brew.sh/)）。其实这差不多就是在用Docker Toolbox了，也就是说，你还是要有VirtuaBox或者[VMWare Fusion](http://www.vmware.com/products/fusion.html)。不多说了，还是放码吧，安装：

```shell
$ sudo port install docker docker-machine docker-compose
```

## docker-machine

> 要运行docker，首先得有可用的Docker Machine，本地环境中的Machine可以由`docker-machine`命令来维护。

先来ls一下：

```shell
$ docker-machine ls
NAME      ACTIVE   DRIVER         STATE     URL   SWARM   DOCKER    ERRORS
```

没有machine，所以还是要自己动手先来创建，其实就是一个VirtualBox或者VMWare Fusion驱动的VM，命令如下：

```shell
$ docker-machine create --driver virtualbox default
```

再ls：

```shell
$ docker-machine ls
NAME      ACTIVE   DRIVER         STATE     URL   SWARM   DOCKER    ERRORS
default   -        virtualbox     Stopped                 Unknown 
```

OK有了，来启动这个machine：

```shell
$ docker-machine start default
Starting "default"...
Machine "default" was started.
Waiting for SSH to be available...
Detecting the provisioner...
Started machines may have new IP addresses. You may need to re-run the `docker-machine env` command.

$ docker-machine env default
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://192.168.85.135:2376"
export DOCKER_CERT_PATH="/Users/yourname/.docker/machine/machines/default"
export DOCKER_MACHINE_NAME="default"
# Run this command to configure your shell: 
# eval $(docker-machine env)

$ eval "$(docker-machine env default)"

```

好了，我们的Docker Machine算是启动了，如果要ssh连接到这个主机，需要用`docker-machine ssh default`。

> 在Docker主机中如果要切换su，执行`sudo -i`就可以了。

*常用的docker-machine命令：*

- `docker-machine create`  创建
- `docker-machine start` 启动
- `docker-machine stop` 停止
- `docker-machine env` 查看环境参数
- `docker-machine ip` 查看IP
- `docker-machine ssh` ssh连接
- `docker-machine ls` machines 列表

## docker

下面该`docker`登场了！`docker info`可以查看当前接入的Docker Machine的信息，我们先来run一个mysql试试：

```shell
$ docker run --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=mysqlpwd -d mysql
```

这个命令会创建一个运行mysql的容器，容器的3306端口（也就是mysql的服务端口）会被映射到docker主机的3306端口，mysql的root用户密码是`MYSQL_ROOT_PASSWORD`指定的`mysqlpwd`。我们可以用下面的命令连接这个mysql服务看看：

```shell
$ mysql 192.168.85.135 -u root -p
```

可以了吧，好了，关于run命令的更多信息可以`docker run --help`查阅。如果要停止上面那个容器可以用`docker stop mysql`。run过之后，这个容器（Container）和镜像（Image）都已经保存在本地了，下次再运行这个容器可以直接运行`docker start mysql`而不需要再`docker run`了。

*常用的docker命令：*

- `docker build` 通过Dockerfile构建镜像
- `docker run` 运行容器
- `docker ps` 显示当前运行的容器（加`-a`参数可以列出本地所有容器，包括未运行的容器）
- `docker start` 启动容器
- `docker stop` 停止容器
- `docker rm` 删除容器
- `docker rmi` 删除镜像


## Dockerfile & `docker build`

> [Dockerfile](https://docs.docker.com/engine/reference/builder/)文件用于声明自动构建镜像的一系列命令，`docker build`使用这个文件来构建镜像。*在我之前的文章“[用SAE Docker一个Ghost博客]({% post_url 2017/04/2017-04-06-docker-a-ghost-blog-by-sae %})”中，我就是用Dockerfile来构建的[Ghost](https://ghost.org)应用。*

当你编写好了Dockerfile之后，你就可以使用`docker build`命令了：

```shell
$ cd /path/to/workdir/
$ docker build .
```

我们也可以在build的时候为镜像命名，另外，在build的时候，docker还会为每一个步骤（命令）生成缓存，我们可以加`--no-cache`参数取消缓存，如下：

```shell
$ docker build -t image_name --no-cache .
```

build成功后，执行`docker images`就可以看到本地的镜像列表，如果是第一次执行可以用`docker run`，如果已经作为容器运行了（`docker ps -a`查看）则可以用`docker start`来启动容器。另外`docker run`时也可以指定环境变量，例如：我在“[用SAE Docker一个Ghost博客]({% post_url 2017/04/2017-04-06-docker-a-ghost-blog-by-sae %})”中的Dockerfile，因为用到了SAE的环境变量，所以，在本地测试环境中，我就把本地环境配置放到一个名为env-dev.list的文件中，内容类似这样：

```
MYSQL_HOST=192.168.85.135
MYSQL_PORT=3306
ACCESSKEY=ghost
SECRETKEY=ghost
APPNAME=ghost
GHOST_URL=http://192.168.85.135:7000/
PORT=2467
```

然后`docker run`：

```shell
$ docker run --name ghost -p 7000:2467 --env-file=./env-dev.list -v /var/storage/ghost:/var/storage/ghost ghost_image
```

这条命令使用ghost_image镜像启动容器并将容器的2467端口映射到主机的7000端口，同时将主机的`/var/storage/ghost`目录挂载到容器的`/var/storage/ghost`。

没什么问题的话，我们就可以通过在浏览器输入`http://192.168.85.135:7000/`来访问这个Ghost应用了。



---

*参考：*

1. [Get started with Docker for Mac](https://docs.docker.com/docker-for-mac/)
2. [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
3. [Best practices for writing Dockerfiles](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/)
4. [How to Use Docker on OS X: The Missing Guide](https://www.viget.com/articles/how-to-use-docker-on-os-x-the-missing-guide)
5. [How to Optimize Your Dockerfile](https://blog.tutum.co/2014/10/22/how-to-optimize-your-dockerfile/)

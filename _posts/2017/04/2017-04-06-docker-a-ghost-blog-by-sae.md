---
title     : 用SAE Docker一个Ghost博客
date      : "2017-04-06 09:00:00"
categories: devy
tags      : 
  - docker
  - ghost
  - sae
layout    : post
class     : "post tag-docker tag-ghost tag-sae"
comments  : true
---

> 其实这是之前在SAE部署Ghost之后写下的，迁移至此仅供参考，只是我已改投[Jekyll](https://jekyllrb.com)和[Github Pages](https://pages.github.com/)。

<!--more-->

首先我们先来认识一下本文即将出场的几位主角（其实它们都在标题里了）：

* [Ghost](https://ghost.org/)：基于NodeJS的开源博客系统
* [Docker](https://www.docker.com/)：应该是时下最流行的容器技术了吧，我们要基于它来构建Ghost服务
* [SAE](http://www.sinacloud.com/sae.html)：新浪云的云应用，也就是我们要用新浪云的云应用服务来运行我们的博客

> 新浪云的[云市场](http://sae.sina.com.cn/?m=appmarket&a=index)里是有Ghost镜像的，你完全可以点击几下鼠标就可以用它来很轻松的部署一个Ghost实例，但对于我这种喜欢自己鼓捣的人来说，当然是不愿意在这方面节省时间的。

好了，言归正传！

### 第1步 创建云应用SAE

盖房子要先买地的，所以，首先我们要申请一个SAE（当然你要先保证自己的账户中有足够的云豆，其实就是充值啦）：进入云应用SAE控制台，在*"应用管理"*中点击*"+创建新应用"*，然后就会进入如下应用创建页面

![创建云应用](/uploads/2017/04/create-sae.png)

> 开发语言选*“自定义”*，部署环境选*“Dockerfile”*，环境配置和实例个数我建议先选1个基础配置就可以了，这个配置可以在部署成功以后随时根据实际需求来调整的，当然越多越高的配置也相应会有更多的支出。

云应用创建成功，进入云应用管理，接下来我们要申请数据库和存储，虽然容器有5G的空间，你完全可以使用sqlite作为数据库，把内容数据和文件都保存在这个容器中，但问题是，只要你更新Dockerfile，容器就会重新构建，你的数据也就没了！所以就不要吝啬这点投入了，在*“数据库与缓存服务”*中，创建一个*“共享型MySQL”*，当然，够豪的话，你也可以创建独享型MySQL；在*“存储与CDN服务”*中新建一个*“共享存储”*，容量视个人需求而定吧，反正也是随时可以调整的。这个存储在后续的步骤中是要挂载到容器上的。

### 第2步 编写Dockerfile

> 考验你的时刻到了，这里你要用到Git、Dockerfile、nodejs、bash等等相关知识

首先我们要git迁出代码，在SAE控制台的“应用”>>“代码管理”中，可以看到你的Git仓库及代码部署说明，可以参照他的sample来操作，也可以clone迁出，当然不管哪种方式，你看到的是一个空仓库，我们要自己来创建必要的Dockerfile文件、ENTRYPOINT文件和Ghost的config.js配置文件。

> 其实[Docker Hub](https://hub.docker.com/)中也有Ghost官方提供的镜像的([点这里](https://hub.docker.com/_/ghost/))，你可以参考他的Dockerfile，我并没有试过这个镜像是否可以直接在SAE上运行

我的Dockerfile大概是下面这样的（*GHOST_CONTENT参考注[^1]*）：

```docker
FROM node:4-slim

ENV GHOST_SOURCE=/var/www/ghost 
# 参考注1.
ENV GHOST_CONTENT=/path/to/your/content
ENV NODE_ENV=production
ENV GOSU_VERSION=1.10 
ENV GHOST_VERSION=0.11.5

VOLUME $GHOST_CONTENT

RUN set -x \
    && apt-get update \
    && apt-get install -y curl unzip rsync ca-certificates --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
	&& curl -L "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)"  -o /usr/local/bin/gosu \
	&& curl -L "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" -o /usr/local/bin/gosu.asc \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
    && mkdir -p "$GHOST_SOURCE" \
    && curl -L "https://github.com/TryGhost/Ghost/releases/download/$GHOST_VERSION/Ghost-$GHOST_VERSION.zip" -o /var/www/ghost.zip \
    && unzip -uo /var/www/ghost.zip -d "$GHOST_SOURCE" \
    && rm -f /var/www/ghost.zip \
    && cd "$GHOST_SOURCE" \
    && npm install -g npm@latest \
    && npm install --production \
    && npm cache clean \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false curl unzip ca-certificates \
    && rm -rf /tmp/* \
    && groupadd ghost \
    && useradd --create-home --home-dir /home/ghost -g ghost ghost \
    && chown -R ghost:ghost "$GHOST_CONTENT"

WORKDIR $GHOST_SOURCE

COPY ghost-config.js "$GHOST_SOURCE/config.js"

COPY docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["npm", "start"]
```

docker-entrypoint.sh是这个样子：

```bash
#!/bin/bash
set -e

rsync -r "$GHOST_SOURCE/content/" "$GHOST_CONTENT/"

if [[ "$*" == npm*start* ]] && [ "$(id -u)" = '0' ]; then
	chown -R ghost:ghost "$GHOST_CONTENT"
    exec gosu ghost "$@"
fi

exec "$@"
```

ghost-config.js大概是这个样子（*url配置参考注[^2]*）：


```javascript
var path = require('path'),
    config;

config = {
    production: {
        url: 'http://yourdomain.com/', // 参考注2
        mail: {},
        logging: true,
        database: {
            client: "mysql",
            connection: {
                host: process.env.MYSQL_HOST,
                port: process.env.MYSQL_PORT,
                user: process.env.ACCESSKEY,
                password: process.env.SECRETKEY,
                database: 'app_' + process.env.APPNAME,
                charset: "utf8"
            }
        },
        paths: {
            contentPath: path.join(process.env.GHOST_CONTENT, '/')
        },
        server: {
            host: '0.0.0.0',
            port: process.env.PORT
        }
    }
};

module.exports = config;
```


### 第3步 构建你的Ghost

其实这一步就是git comit & push你的代码，然后你就静待花开吧，如果一切顺利，在push收到成功的信息后，你的blog就在那里了。

哦，别忘了把你的*"共享存储"*挂载到Dockerfile中`$GHOST_CONTENT`所指定的路径上并重启你的容器。

Enjoy!

> **后记 2017-04-17**
>
> 已经整理了示例代码项目上传到Github，可以[戳这里](https://github.com/devylee/ghost-sae)！


---

*注：*

[^1]: GHOST_CONTENT 就是你在第1步中申请的“共享存储”的挂载路径

[^2]: 这是你博客的网址，你可以用SAE的二级网址，比如这样：`url: 'http://' + process.env.APPNAME + '.applinzi.com/'`；或者像我，先在SAE控制台的“应用”>“环境变量”中添加一个环境变量，例如：SITEURL，值为：`http://yourdomain.com/`，然后你的配置就可以这样写： `url: process.env.SITEURL` 。
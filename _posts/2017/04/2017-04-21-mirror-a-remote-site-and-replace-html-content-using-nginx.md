---
title     : 用Nginx镜像远程站点并替换HTML
date      : "2017-04-21 9:30:00"
categories: devy
tags      : 
  - nginx
  - docker
  - sae
layout    : post
class     : "post tag-nginx tag-docker tag-sae"
comments  : true
---

> Nginx可以做很多事，除了我们最常用的做Web服务器和反向代理，它其实还可以让我们做很多的“小动作”，比如本文要介绍的镜像一个站点、替换HTTP的响应内容。

<!--more-->

**来，容我先描述一下需求：** [devylee.github.io](http://devylee.github.io)是我的Github Page；[devylee.me](http://devylee.me)是我的一个域名，而且经过一系列的波折，在[新浪云](http://sinacloud.com/)终于通过了工信部的备案，可以在国内用了。so，那就不要让这个域名闲着了，但我又并不想直接把这域名绑定在我的Github Page上（GH上只能绑定一个独立域名，而且不支持HTTPS），所以，我就用SAE部署一个Docker容器并绑定[devylee.me](http://devylee.me)这个域名，然后用Nginx把请求都proxy到[devylee.github.io](http://devylee.github.io)，顺便在返回的HTML页面中注入备案号。

需求很简单吧，来，让我们撸起袖子干吧！

首先上Dockerfile（SAE上如何部署Dockerfile可以参考我之前的文章“[用SAE Docker一个Ghost博客]({% post_url 2017/04/2017-04-06-docker-a-ghost-blog-by-sae %})”）：

> 我这里监听的端口是5050，这个要看你的SAE应用中环境变量`PORT`的具体值。

```docker
FROM nginx:alpine

COPY nginx-default.conf /etc/nginx/conf.d/default.conf

EXPOSE 5050
```

nginx-default.conf：

```conf
server {
    listen 5050;

    location / {
        proxy_pass http://devylee.github.io;
        proxy_redirect off;

        sub_filter 'All Rights Reserved.' 'All Rights Reserved. <a href="http://www.miitbeian.gov.cn">辽ICP备16011865号</a>';
    }

}
```

如此，push并确认成功后，在浏览器输入devylee.me，哦，没错，这就是我的Github Page！不过，备案号呢？貌似sub_filter并未起作用啊！

经过各种尝试（甚至是更换镜像源，从头编译nginx，然并卵！），最终找到原因原来是因为`Accept-Encoding`！

怎么回事？因为现在几乎所有的Web服务器都支持gzip压缩的，也就是`Accept-Encoding: gzip`，而且默认情况下就是启用的，当然Github Page也不例外！于是乎，我们的Nginx
通过proxy_pass得到的响应内容其实是被gzip过的，所以，sub_filter就根本不起作用！找到问题所在，接下来就简单了，我们只要对nginx-default.conf稍加改造（增加一行`proxy_set_header Accept-Encoding ""`）就可以了：

```conf
server {
    listen 5050;

    location / {
        proxy_pass http://devylee.github.io;
        proxy_redirect off;
        proxy_set_header Accept-Encoding "";

        sub_filter 'All Rights Reserved.' 'All Rights Reserved. <a href="http://www.miitbeian.gov.cn">辽ICP备16011865号</a>';
    }

}
```

OK！再次push，刷新浏览器~ 

嗯！有没有觉得so easy啊！

---

*参考：*

1. [Nginx `ngx_http_sub_module` Module](http://nginx.org/en/docs/http/ngx_http_sub_module.html)
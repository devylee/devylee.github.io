---
layout: post
title: '用Javascript检测跨站资源(CORS)的可用性'
class: 'post tag-javascript tag-cors tag-disqus'
date: '2017-04-10 15:30:00'
categories: devy
tags: 'Javascript CORS Disqus'
excerpt_separator: <!--more-->
comments: true
---

> 我相信和国外的程序猿比起来，国内的同行们至少要比他们多了解一个概念，那就是“翻墙”！其实这项技术本身而言，也并没有多复杂，尤其现在的工具也简单易用了很多，但在翻的过程中，还是会激发我们很多的idea，比如本文要说的，用js检测CORS资源的可用性。
<!--more-->

其实我之所以会冒出这个想法，也是源于我的自身需求，因为要在博客中集成[Disqus](https://disqus.com)评论。但是正如你所知，Disqus在国内是被墙的，这样会导致一个问题，就是页面加载后，因为Disqus的资源（js）始终加载不进来，浏览器就始终在那里loading...，虽然不影响页面内容的阅读，但我是无法接受的！所以我的需求很简单：**要在页面加载后检测Disqus的资源是否能够加载，如果不能，那就停止对这些资源的请求。** 
> 是的，在国内不翻墙的情况下，你是看不到我博客有评论功能的！

先来看看Disqus官方提供的通用集成代码：
```javascript
    /**
    *  RECOMMENDED CONFIGURATION VARIABLES: EDIT AND UNCOMMENT THE SECTION BELOW TO INSERT DYNAMIC VALUES FROM YOUR PLATFORM OR CMS.
    *  LEARN WHY DEFINING THESE VARIABLES IS IMPORTANT: https://disqus.com/admin/universalcode/#configuration-variables
    */
    var disqus_config = function () {
        this.page.url = PAGE_URL;  // Replace PAGE_URL with your page's canonical URL variable
        this.page.identifier = PAGE_IDENTIFIER; // Replace PAGE_IDENTIFIER with your page's unique identifier variable
    };
    (function(){ // DON'T EDIT BELOW THIS LINE
        var d = document, s = d.createElement('script');

        s.src = '//EXAMPLE.disqus.com/embed.js';  // IMPORTANT: Replace EXAMPLE with your forum shortname!

        s.setAttribute('data-timestamp', +new Date());
        (d.head || d.body).appendChild(s);
    })();
```

其实很简单，就是在页面中加载`//EXAMPLE.disqus.com/embed.js`这个js文件，所以，我只要判断这个js是否可以访问。我第一个想到了[XMLHttpRequest](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest)，我只要向这个资源发一个HEAD请求，然后判断状态码就可以知道这个资源是否可用。于是，第一个方案诞生：
```javascript
...

    var r = new ( window.ActiveXObject || XMLHttpRequest )( 'Microsoft.XMLHTTP' );
    r.open('HEAD', '//EXAMPLE.disqus.com/embed.js?data-timestamp=' + new Date(), true);
    r.timeout = 3000;
    r.onreadystatechange = function() {
        if (r.readyState == 4 && 
                (r.status == 200 || r.status == 301 || r.status == 302 || r.status == 304 || r.status == 307)) {
            (function() {  // REQUIRED CONFIGURATION VARIABLE: EDIT THE SHORTNAME BELOW
                var d = document, s = d.createElement('script');
                
                s.src = '//EXAMPLE.disqus.com/embed.js';  // IMPORTANT: Replace EXAMPLE with your forum shortname!
                
                s.setAttribute('data-timestamp', +new Date());
                (d.head || d.body).appendChild(s);
            })();
        }
    }
    r.send();
```

事实证明，很多事情并没有我们想的那么简单，这个方案遇到了CORS的安全策略限制，提示：`XMLHttpRequest has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.` [^1] 这个问题的解决办法有两种：
1. Disqus在response的header中提供`Access-Control-Allow-Origin： *`；
2. 换一种方案！

想来要Disqus在header中加入Access-Control-Allow-Origin也并非是件容易的事，所以还是自己动手丰衣足食吧！Google了一通，得知jQuery的ajax方法，在`dataType`是`jsonp`或者`script`的时候，不会有这个Access-Control-Allow-Origin的问题，于是，我的第二个方案诞生了：
```javascript
...

    (function(){
        document.addEventListener('DOMContentLoaded', function() {
            $.ajax({
                url: '//EXAMPLE.disqus.com/embed.js', // IMPORTANT: Replace EXAMPLE with your forum shortname!
                dataType: 'script', // jsonp 会有parseerror
                jsonp: false,
                timeout: 3000,
                error: function(xhr, status) {
                    xhr.abort(status);
                },
                success: function() {
                    var d = document, s = d.createElement('script');
                    s.src = '//EXAMPLE.disqus.com/embed.js';  // IMPORTANT: Replace EXAMPLE with your forum shortname!
                    s.setAttribute('data-timestamp', +new Date());
                    (d.head || d.body).appendChild(s);
                }
            });
        });
    })();
```

这个方案成功绕开了CORS的安全策略问题，但新的问题又来了：即使是timeout了，ajax请求也无法被abort，浏览器还会在不停的loading...！分析原因：jQuery的ajax其实也是对XMLHttpRequest的封装，但貌似`dataType`在`jsonp`或`script`的情况下并不是走的XMLHttpRequest，而是通过向页面吐script标签来实现，也正因此，才不会受CORS策略的限制。

所以，看来还是要自己借助页面script或者img标签的加载来实现。不过，历史证明：**大多数的轮子人家已经造好了的！**这不，我就找到了这个[pingjs](https://github.com/jdfreder/pingjs)。不过，pingjs也不会在超时后停止对资源的请求，所以我们要对这个js做点hack，第43行，在timeout时将img.src置空，如下：
```javascript
...

setTimeout(function() { img.src = ''; img = null; reject(Error('Timeout')); }, 3000);

...

```

如此，我的最终方案就变成这样：
```javascript
...

    (function(){
        document.addEventListener('DOMContentLoaded', function() {
            ping('https://EXAMPLE.disqus.com/count.js')
                .then(function(delta) {
                var d = document, s = d.createElement('script');
                s.src = '//EXAMPLE.disqus.com/embed.js';  // IMPORTANT: Replace EXAMPLE with your forum shortname!
                s.setAttribute('data-timestamp', +new Date());
                (d.head || d.body).appendChild(s);
            });
        });
    })();
```

问题解决！不知道大家注意到没有，我ping的是`https://EXAMPLE.disqus.com/count.js`而不是`//EXAMPLE.disqus.com/embed.js`。其实原因很简单，count.js(1.5k)要远远小于embed.js(18k)！直接使用https也是因为这样省去了远端的redirect。


*** 其实，我还试过另外一种不奏效的方案：*

```javascript
...

(function(){
        var d = document, s = d.createElement('script'),
            t = setTimeout(function(){ s.src = ''; s.remove(); }, 3000); // 定义一个定时器用于在超时后移除这个script
        s.src = '//EXAMPLE.disqus.com/embed.js';  // IMPORTANT: Replace EXAMPLE with your forum shortname!
        s.setAttribute('data-timestamp', +new Date());
        s.async = true;
        s.onload = function(){ clearTimeout(t); }; // 成功加载后移除定时器
        (d.head || d.body).appendChild(s);
    })();

```

貌似`<script />`只要append就无法停止加载（直到努力加载到无能为力），也许正是因此，上述的第二种ajax检测方案在timeout时abort操作会不起作用吧。

---

*注：*

[^1]: [CORS访问控制](https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS)
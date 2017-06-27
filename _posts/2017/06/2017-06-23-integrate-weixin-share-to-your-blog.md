---
title     : 在你的博客中集成微信分享
date      : "2017-06-23 17:00:00"
categories: devy
layout    : post
tags      : 
  - Javascript
  - Weixin
layout    : post
class     : "post tag-javascript tag-weixin"
comments  : true
---

> 如今差不多是全民微信的时代了，朋友圈已经是非常重要的信息获取途径，也是很多人分享信息的重要途径，那不如我们就来聊聊集成微信分享的那点事吧~

<!--more-->

# 为什么要集成微信分享？

其实我们已经很容易通过手机和微信来分享一个网页，只要手机中安装了微信，现在大多的手机浏览器都有分享功能，在浏览网页时都可以选择分享到微信、QQ、推特、微博等等这些常用的社交平台。只是在不做处理的情况下，通常分享出来的样子并不那么令人满意，我们更希望有更吸引人的图片和标题、描述神马的。其实不用想，鹅场当然早就提供了解决这类需求的方案的，那就是[JS-SDK](https://mp.weixin.qq.com/wiki?t=resource/res_main&id=mp1421141115)。所以本文其实就是介绍如何在最小化改动博客代码的情况下，将这个SDK集成进来。

其实思路很简单，就是将[JS-SDK](https://mp.weixin.qq.com/wiki?t=resource/res_main&id=mp1421141115)中关于分享的接口封装到一个JS函数或者对象中，然后再通过JS获取网页中的相关信息（标题、描述……），并将这些信息作为参数传递给这个函数，完成对相关分享接口的引用。

# 那就开始吧

首先，我们来封装JS-SDK，创建一个js文件`wxshare.js`，为了让这个JS看起来更通用一些，我用了[UMD](https://github.com/umdjs/umd)：

```javascript
(function (root, factory) {
        if (typeof define === 'function' && define.amd) {
            define([], factory);
        } else if (typeof module === 'object' && module.exports) {
            module.exports = factory();
        } else {
            root.weixin_share = factory(); // 对象的名称是"weixin_share"
        }
    }
)(this, function () {
    'use strict';

    var isWeixin = navigator.userAgent.toLowerCase().indexOf("micromessenger") >= 0;

    /**
     * 此方法用于加载JS-SDK
     */
    function load_wx_jssdk(sdk) {
        var s = document.createElement('script');

        return new Promise(function (resolve, reject) {
            s.onload = function () {
                resolve(s);
            };
            s.onerror = function () {
                reject('failed to load ' + sdk);
            };
            s.async = 1;
            s.src = sdk;
            document.getElementsByTagName("head")[0].appendChild(s);
        });
    }

    /**
     * 这个方法用于加载JS-SDK的权限验证配置
     * 具体说明，请参考https://mp.weixin.qq.com/wiki?t=resource/res_main&id=mp1421141115
     * 其中的 1.1.3 步骤三：通过config接口注入权限验证配置
     */
    function load_config(config) {
        return new Promise(function (resolve, reject) {
            if (!isWeixin) {
                reject('not weixin');
            }

            if (typeof config === 'object') { // config 可以是json对象，比如{appId:'xxx', signature:'xxx' ...}
                resolve(config);
            } else if (typeof config === 'string') { // 或者是通过网址异步获取，这是本文推荐的方式！
                $.ajax({
                    url: config,
                    data: {
                        l: window.location.href
                    },
                    type: "GET",
                    dataType: "json",
                    success: function (data) {
                        resolve(data);
                    },
                    error: function (r, s) {
                        reject(s);
                    }
                });
            } else {
                reject('unknown config');
            }
        });
    }

    /**
     * 这个方法就是调用JS-SDK的API方法初始化分享属性
     */
    function init_share(options) {
        return new Promise(function (resolve, reject) {
            if (!isWeixin) {
                reject('not weixin');
            }

            load_wx_jssdk('//res.wx.qq.com/open/js/jweixin-1.2.0.js').then(function () {
                wx.config({
                    debug: false,
                    appId: options.appId, //需要后端传入
                    signature: options.signature, //需要后端传入
                    timestamp: options.timestamp, //需要后端传入
                    nonceStr: options.nonceStr, //需要后端传入
                    jsApiList: ['onMenuShareTimeline', 'onMenuShareAppMessage']
                });

                wx.error(function (res) {
                    reject(res);
                });
                wx.ready(function () {
                    // 对话消息
                    wx.onMenuShareAppMessage({
                        title: options.title, // 分享标题
                        desc: options.desc, // 分享描述
                        link: options.link, // 分享链接，该链接域名或路径必须与当前页面对应的公众号JS安全域名一致
                        imgUrl: options.imgUrl, // 分享图标
                        //type: '', // 分享类型,music、video或link，不填默认为link
                        //dataUrl: '', // 如果type是music或video，则要提供数据链接，默认为空
                        success: function () {
                            // 用户确认分享后执行的回调函数
                        },
                        cancel: function () {
                            // 用户取消分享后执行的回调函数
                        }
                    });
                    // 朋友圈
                    wx.onMenuShareTimeline({
                        title: options.title, // 分享标题
                        link: options.link, // 分享链接，该链接域名或路径必须与当前页面对应的公众号JS安全域名一致
                        imgUrl: options.imgUrl, // 分享图标
                        success: function () {
                            // 用户确认分享后执行的回调函数
                        },
                        cancel: function () {
                            // 用户取消分享后执行的回调函数
                        }
                    });
                });
                resolve(wx);
            }).catch(function (m) {
                reject(m);
            });

        });
    }

    /**
     * 我们的weixin_share对象将有两个方法：config和init，分别对应load_config和init_share
     */
    return {
        config: load_config,
        init: init_share
    };
});
```

接下来，我们要处理上面代码中提到的[JS-SDK的权限验证配置](https://mp.weixin.qq.com/wiki?t=resource/res_main&id=mp1421135319#buzhou3)。我的建议是用后端程序写一个接口并单独部署，比如下面这个使用[Slim](https://www.slimframework.com/)框架的PHP程序：

```php
<?php
// Routes
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Message\ResponseInterface;

$app->get('/path/to/wxconfig', function (ServerRequestInterface $request, ResponseInterface $response, $args) {
    $settings = $this->get('settings');
    $app_id = '你的微信公众号开发者ID：AppID';
    $app_secret = '你的微信公众号开发者密码：AppSecret';
    $timestamp = time();
    $url = $request->getQueryParam('l');
    $noncestr = md5(time());
    try {
        if (($access_token = get_wxmp_access_token($settings['datafile']['access_token'], $app_id, $app_secret))
                && ($ticket = get_wxmp_jsapi_ticket($settings['datafile']['jsapi_ticket'], $access_token))) {
            return $response->withJson(array(
                'appId'=>$app_id,
                'timestamp'=>$timestamp,
                'nonceStr'=>$noncestr,
                'signature'=>sha1(sprintf("jsapi_ticket=%s&noncestr=%s&timestamp=%d&url=%s", $ticket, $noncestr, $timestamp, $url))
            ));
        }
    } catch (\Exception $e) {
        if ($settings['displayErrorDetails']) {
            return $response->withJson(array('error'=>$e->getCode(), 'message'=>$e->getMessage(), 'trace'=>$e->getTraceAsString()));
        }
    }
    return $response->withJson(array());
});

/**
 * 获取access_token
 * https://mp.weixin.qq.com/wiki?t=resource/res_main&id=mp1421140183
 */
function get_wxmp_access_token($datafile, $app_id, $app_secret) {
    if ($fp = fopen($datafile, 'w+')) {
        if ($filesize = filesize($datafile) && $data = fread($fp, $filesize) && $token_data = explode($data, '#')) {
            if ($token_data[1] > time()) {
                fclose($fp);
                return $token_data[0];
            }
        }
        if (($result = curl_json("https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid={$app_id}&secret={$app_secret}"))
                && isset($result['access_token'], $result['expires_in'])) {
            $access_token = $result['access_token'];
            $expires_in = $result['expires_in'];
            fwrite($fp, implode('#', array($access_token, time() + $expires_in - min(300, $expires_in))));
            fclose($fp);
            return $access_token;
        }
        fclose($fp);
    }
    return null;
}

/**
 * 获取jsapi_ticket
 * https://mp.weixin.qq.com/wiki?t=resource/res_main&id=mp1421141115#f11
 */
function get_wxmp_jsapi_ticket($datafile, $access_token) {
    if ($fp = fopen($datafile, 'w+')) {
        if ($filesize = filesize($datafile) && $data = fread($fp, $filesize) && $ticket_data = explode($data, '#')) {
            if ($ticket_data[1] > time()) {
                fclose($fp);
                return $ticket_data[0];
            }
        }
        if (($result = curl_json("https://api.weixin.qq.com/cgi-bin/ticket/getticket?access_token={$access_token}&type=jsapi"))
                && isset($result['ticket'], $result['expires_in'])) {
            $ticket = $result['ticket'];
            $expires_in = $result['expires_in'];
            fwrite($fp, implode('#', array($ticket, time() + $expires_in - min(300, $expires_in))));
            fclose($fp);
            return $ticket;
        }
        fclose($fp);
    }
    return null;
}

function curl_json($url){
    $ci = curl_init();
        
    curl_setopt($ci, CURLOPT_CONNECTTIMEOUT, 30);
    curl_setopt($ci, CURLOPT_TIMEOUT, 30);
    curl_setopt($ci, CURLOPT_RETURNTRANSFER, TRUE);
    curl_setopt($ci, CURLOPT_SSL_VERIFYPEER, FALSE);
    curl_setopt($ci, CURLOPT_HEADER, FALSE);
    curl_setopt($ci, CURLOPT_POST, FALSE);
        
    curl_setopt($ci, CURLOPT_URL, $url);
    curl_setopt($ci, CURLINFO_HEADER_OUT, TRUE);

    $response = curl_exec($ci);

    curl_close($ci);

    return json_decode($response, true) ?: $response;
}

```

然后，我们要在页面中调用上面定义的`weixin_share`，其中`path/to/wxconfig`就是上述权限验证配置的部署路径：

```javascript
(function (root) {
    var s = document.createElement('script');
    s.onload = function () {
        root.weixin_share.config("/path/to/wxconfig").then(function (c) {
            root.weixin_share.init($.extend({
                title: $('meta[property="og:title"]').attr('content'),
                desc: $('meta[property="og:description"]').attr('content'),
                link: $('meta[property="og:url"]').attr('content'),
                imgUrl: $('meta[property="og:image"]').attr('content')
            }, c));
        });
    };
    s.async = 1;
    s.src = '/path/to/wxshare.js';
    document.getElementsByTagName("head")[0].appendChild(s);
})(this);
```

> 大家可能注意到了，我是从页面的meta元素中提取相关的标题、描述以及图片等信息，这样做的目的主要是尽可能小的改动博客代码。当前主流的博客系统貌似都使用了这种叫[Open Graph protocol](http://ogp.me/)的东西。当然，如果不嫌麻烦，也可将上述提取meta的代码进行改造一番（比如，使用后端程序直接将相关信息输出到页面代码中）。


好了，一切就绪！下面，你要确认一下，你的微信开发者接口权限了，在没有通过微信认证的情况下，上述分享功能的接口的权限都是“未获得”！而不论你是个人还是企业，这认证都是要每年花￥300元的，呵呵~
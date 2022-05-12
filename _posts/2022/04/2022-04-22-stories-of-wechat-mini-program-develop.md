---
title     : 微信小程序开发二三事
category  : devy
layout    : post
date      : 2022-04-22
tags      : 
  - miniprogram
  - wechat
class     : post tag-miniprogram tag-wechat
comments  : true
---

> 最近江湖救急，帮朋友做了个微信小程序。之前也有做过几个小程序项目，不过基本上都是内容展示类的，顶多再就是有点表单交互。这次这个不太一样，除了常规的内容展示、还要通过小程序实现扫码、人脸识别、拍照和视频录制功能，这让我对微信小程序的摄像头相关API有了更深入的了解和使用感受。

<!--more-->

坦白说，对于微信小程序，我想吐槽的东西还是挺多的，但是呢，我们也要认识到，任何事物都不可能对所有人做到完美，所以我们应该接受它的不足（虽然本人也是极不情愿），拥抱它优秀的一面，如果你足够强大，那就去推动完善它。本文，我只说camera组件使用过程中遇到的几个问题以及如何解决。包括：

- Camera实时帧数据的base64编码转换问题；
- 视频录制的30秒限制问题；

这里我们会用到小程序的[camera组件](https://developers.weixin.qq.com/miniprogram/dev/component/camera.html)、[canvas组件](https://developers.weixin.qq.com/miniprogram/dev/component/canvas.html)和下面相关的API：
- [wx.setKeepScreenOn](https://developers.weixin.qq.com/miniprogram/dev/api/device/screen/wx.setKeepScreenOn.html)
- [wx.createCameraContext](https://developers.weixin.qq.com/miniprogram/dev/api/media/camera/wx.createCameraContext.html)
- [wx.initFaceDetect](https://developers.weixin.qq.com/miniprogram/dev/api/ai/face/wx.initFaceDetect.html)
- [wx.faceDetect](https://developers.weixin.qq.com/miniprogram/dev/api/ai/face/wx.faceDetect.html)
- [CameraContext.onCameraFrame](https://developers.weixin.qq.com/miniprogram/dev/api/media/camera/CameraContext.onCameraFrame.html)
- [CameraContext.startRecord](https://developers.weixin.qq.com/miniprogram/dev/api/media/camera/CameraContext.startRecord.html)
- [CameraContext.stopRecord](https://developers.weixin.qq.com/miniprogram/dev/api/media/camera/CameraContext.stopRecord.html)
- [wx.canvasPutImageData](https://developers.weixin.qq.com/miniprogram/dev/api/canvas/wx.canvasPutImageData.html)
- [wx.canvasToTempFilePath](https://developers.weixin.qq.com/miniprogram/dev/api/canvas/wx.canvasToTempFilePath.html)
- [FileSystemManager.readFile](https://developers.weixin.qq.com/miniprogram/dev/api/file/FileSystemManager.readFile.html)
- [FileSystemManager.saveFile](https://developers.weixin.qq.com/miniprogram/dev/api/file/FileSystemManager.saveFile.html)


因为这个小程序进入后首先有个刷脸验证的环节，我们就先来说说小程序的人脸识别吧。本来的想法还是比较简单的，用户进入刷脸环节，调起手机前置摄像头（UI通过camera组件显示实时画面并指导用户调整距离、角度和姿态等等），通过监听`CameraContext.onCameraFrame`将图像数据传递给`wx.faceDetect`接口进行检测，如果成功检测到有效的人脸信息就将该帧的图像做base64转码并通过业务接口提交到服务器做人脸比对。所以最初的实现差不多是类似这样的：

首先wxml要声明camera组件：`<camera device-position="front" />`，（可以通过样式表或者行内样式定义高度/宽度等），然后js大概就是这样：

```javascript
const { encode } = require('upng-js')
const { Base64 } = require('js-base64')

Page({
    onLoad(options) {
        wx.initFaceDetect({
            success: () => {
                const context = wx.createCameraContext()
                const listener = context.onCameraFrame((frame) => {
                    wx.faceDetect({
                        frameBuffer: frame.data,
                        width: frame.width,
                        height: frame.height,
                        success: () => {
                            // const pngBase64 = wx.arrayBufferToBase64(frame.data) 
                            const pngBuffer = encode([frame.data], frame.width, frame.height)
                            const strBuffer = String.fromCharCode(...new Uint8Array(pngBuffer))
                            const pngBase64 = Base64.btoa(strBuffer)
                            console.log(pngBase64)
                        }
                    })
                })
                listener.start()
            }
        })
    }
})
```

因为[wx.arrayBufferToBase64](https://developers.weixin.qq.com/miniprogram/dev/api/base/wx.arrayBufferToBase64.html)接口从基础库2.4.0开始停止维护，所以使用了两个第三方库[UPNG](https://github.com/photopea/UPNG.js)和[js-base64](https://github.com/dankogai/js-base64)，用于将CameraContext.onCameraFrame帧数据(ArrayBuffer)转成base64编码。但这个方法在iOS下实测速度很慢（甚至卡死[^1]）！于是乎就有了下面这个使用canvas画布来获取base64的方案：

首先在wxml中要声明canvas画布`<canvas canvas-id="faceCapture"></canvas>`，（当然你可能要想办法把这个画布“藏起来”，比如用绝对定位把它放到屏幕之外看不到的地方或者用其他组件遮盖，直接隐藏是不行的），然后js这样：

```javascript

Page({

    camera: {
        context: null,
        listener: null,
        free: true
    },

    onLoad(options) {
        wx.initFaceDetect({
            success: () => {
                const context = wx.createCameraContext()
                const listener = context.onCameraFrame((frame) => {
                    wx.faceDetect({
                        frameBuffer: frame.data,
                        width: frame.width,
                        height: frame.height,
                        success: () => {
                            if (this.camera.free) { // 加个状态开关，避免产生大量的处理任务
                                this.handleFrame(frame)
                            }
                        }
                    })
                })
                listener.start()
                this.camera.context = context
                this.camera.listener = listener
            }
        })
    },

    handleFrame(frame) {
        this.camera.free = false
        const data = new Uint8Array(frame.data)
        const clamped = new Uint8ClampedArray(data)
        wx.canvasPutImageData({
            canvasId: 'faceCapture',
            data: clamped,
            height: frame.height,
            width: frame.width,
            x: 0,
            y: 0,
            success: () => {
                wx.canvasToTempFilePath({
                    canvasId: 'faceCapture',
                    fileType: 'png',
                    success: (result) => {
                        wx.getFileSystemManager().readFile({
                            filePath: result.tempFilePath,
                            encoding: 'base64',
                            success: (file) => {
                                console.log(file.data) // base64 string
                            }
                        })
                    },
                    completed: () => {
                        this.camera.free = true
                    }
                }, this)
            }
        }, this)
    }
})

```

OK, 刷脸照片转base64的问题算是解决了！接下来我们来看看视频录制，我们的需求是，用户点击录制按钮就开始持续录制视频并上传的服务器，直到用户点击停止录制。这个过程，我们首先要解决几个问题：1、保持手机不能熄屏，避免应用被杀死；2、长时间录制时不能把手机存储空间占满。

对于第1个问题，微信小程序可以通过`wx.setKeepScreenOn`API来实现：

```javascript
wx.setKeepScreenOn({
  keepScreenOn: true
})
```

对于第2个问题，首先我们要知道微信小程序的两个限制：一个是单次录制视频时间不能超过30秒，否则就会触发`timeoutCallback`；另一个是小程序有10m的本地存储空间限制[^2]。所以，如果不是采用实时推流（小程序是可以用[LivePusherContext](https://developers.weixin.qq.com/miniprogram/dev/api/media/live/LivePusherContext.html)做推流的，这也是比较理想的方式，但是需要先通过类目审核，再在小程序管理后台，「开发」-「接口设置」中自助申请开通相关权限）的话，那只能是采用一段一段录制、一个一个的上传，并且及时清理已经完成上传的视频文件。当然这样做，两段视频之间会断录百十来毫秒，如果业务场景对视频连续性要求并不是很高的话，应该也是可以接受的（或者说也只能如此了）。

另外，要特别注意`CameraContext.stopRecord`方法的`compressed`参数，在Android设备中当`compressed=true`时会很慢（就是要很久才能收到`complete`回调，当然这也有可能是我的Android测试设备配置不高吧？），不过iOS也没有好到哪里去，因为[wx.compressVideo](https://developers.weixin.qq.com/miniprogram/dev/api/media/video/wx.compressVideo.html)接口在iOS下不起作用[^3]！所以，如果你的视频需要压缩的话，是需要做程序兼容处理的。

好了，该放码了～

`CameraRecorder.js`（这里我把录制操作做了简单的封装）

```js

/**
 * CameraRecorder
 * @param {*} options 
 */
function CameraRecorder(options) {
  this.options = Object.assign({
    onError: null, // 出错时的回调函数
    onRecorded: null // 有录制文件产生时的回调函数
  }, options)
  this.context = wx.createCameraContext()
  this.isRecording = false
}

/**
 * 开始录制
 */
CameraRecorder.prototype.start = function () {
  return new Promise((resolve, reject) => {
    this.context.startRecord({
      success: () => {
        this.isRecording = true
        resolve(this)
      },
      fail: (err) => {
        this.isRecording = false
        this._handleError('startRecord fail', err)
        reject(err)
      },
      timeoutCallback: (res) => {
        console.log('startRecord timeout', res)
        this.isRecording = false
        this._handleFile(res)
        this.start() // 循环录制
      }
    })
  })
}

/**
 * 停止录制
 */
CameraRecorder.prototype.stop = function () {
  return new Promise((resolve) => {
    this.context.stopRecord({
      success: (res) => {
        console.log('stopRecord success', res)
        this.isRecording = false
        this._handleFile(res)
      },
      fail: (err) => {
        this._handleError('stopRecord fail', err)
      },
      complete: () => {
        resolve(this)
      }
    })
  })
}

/**
 * 文件处理
 * @param {*} res 
 */
CameraRecorder.prototype._handleFile = function (res) {
  if (this.options.onRecorded) {
    this.options.onRecorded(res, this)
  }
}

/**
 * 错误处理
 * @param {String} msg 
 * @param {*} err 
 */
CameraRecorder.prototype._handleError = function (msg, err) {
  console.error(msg, err)
  if (this.options.onError) {
    this.options.onError(err, this)
  }
}

module.exports = CameraRecorder

```

`wxml`（这里只做个简单的view，至于样式大家可以自己发挥一下）

{% raw %}
```xml

<view>
  <camera device-position="back" />
  <view>
    <button type="primary" bindtap="onRecordTap" wx:if="{{ !recording }}">
      开始录制
    </button>
    <button type="primary" bindtap="onStopTap" wx:if="{{ recording }}">
      停止录制
    </button>
  </view>
</view>

```
{% endraw %}

`js`

```js

const CameraRecorder = require('path/to/CameraRecorder')

Page({

  /**
   * 页面的初始数据
   */
  data: {
    recording: false
  },

  cameraRecorder: null, // 录制器

  /**
   * 生命周期函数--监听页面加载
   */
  onLoad(options) {
    try {
      wx.setKeepScreenOn({
        keepScreenOn: true,
      })
    } catch (error) {
      console.log('wx.setKeepScreenOn error', error)
    }
    // Recorder
    this.cameraRecorder = new CameraRecorder({
      onError: (error) => {
        console.log(error)
      },
      onRecorded: (video, recorder) => {
        console.log(video)
        // 视频文件处理
      }
    })
  },


  /**
   * 点击录制
   * @param {*}} e 
   */
  onRecordTap(e) {
    this.cameraRecorder.start().then(() => {
      this.setData({
        recording: true
      })
    })
  },

  /**
   * 点击停止
   * @param {*}} e 
   */
  onStopTap(e) {
    this.cameraRecorder.stop().then(() => {
      this.setData({
        recording: false
      })
    })
  }
}

```

抛砖引玉，本文就先写这么多吧。

---

参考：

1. [小程序AR识别，三行代码实现Camera数据毫秒级转base64图片](https://developers.weixin.qq.com/community/develop/article/doc/0002082db805b04e7d4af1f6a56013)


---

*注：*

[^1]: <https://developers.weixin.qq.com/community/develop/doc/0000eaf449cde0eeff9ae0f8852000>; <https://developers.weixin.qq.com/community/develop/doc/0006822c32056849489a3489654400>;

[^2]: <https://developers.weixin.qq.com/community/develop/doc/000e8458a986b85a5148667035b400>；<https://developers.weixin.qq.com/community/develop/doc/000448c5ea074042e3f8d326056800>;

[^3]: <https://developers.weixin.qq.com/community/develop/issue/346>
---
title     : 一个基于Android TV的多媒体播放器
category  : devy
layout    : post
date      : 2022-06-02
tags      : 
  - Android
class     : post tag-android
comments  : true
---

> 前些日子去朋友那里拜访，聊了很多关于他所做项目和一些技术的应用，席间提到了Android TV Box，朋友还送了我一个。于是乎闲来无事我就花了点时间做了些开发尝试。

<!--more-->

说到电视盒子，我相信大部分人应该也不陌生，市面上这种产品也挺多的，消费级产品多是用来接电视，代替有线电视联网看视频和网络电视，也有应用商店，应用也还蛮多的，应该说生态比较成熟。我拿到的这个盒子，看起来像是个外贸产品，或者也许是厂家并没有做太多的定制开发，基本上就是个接近原生的Android TV环境，1G内存，8G内置存储……，太适合做开发测试用了。

拿到这个盒子我也在想能做点什么？也巧，朋友处有一个展厅项目有几块拼接大屏，想要做一些多媒体内容的联动播放展示，问我有没有解决方案，我突然就想到这个Box应该是可以作为屏幕的播放终端，通过联网接入一个中控系统来进行集中播放控制的。只可惜客户的需求也一直在变，最终这个方案被简化成每块大屏只要能有设备插个U盘单机播放就可以了！好吧，我也是无话可说，谁让人家是甲方爸爸！

这样一来似乎也就不需要我做什么了，因为这种单机播放软件挺多的，他随便弄个闲置的PC机装个播放软件就可以了，这种软件设备供应商也有提供，而且免费！呵呵～

不过既然是有了这个方案的想法，就不要让这个盒子闲着了，先写个单机的多媒体播放试试吧！

功能需求很简单：

1. 循环播放图片（包括GIF动图）和视频；
2. 插入U盘，自动读取U盘内容，从指定的目录中获取文件列表并自动开始播放；
3. 拔出U盘，播放自动停止。

所以其实这个应用，关键解决两个问题就可以了：

1. 图片和视频播放；
2. USB设备事件监听处理。

先来说说第一个，图片和视频播放的问题。其实也蛮简单的，思路就是用ViewPager，如果是静态图片，则停留3秒，如果是动图或视频就停留到播放完毕，然后自动跳到下一个文件播放。

首先我们定义一个Media类，来处理多媒体文件（这里图片的加载用到了[Glide 4](http://bumptech.github.io/glide/)）：

```java

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.AttributeSet;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.VideoView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.bumptech.glide.Glide;
import com.bumptech.glide.gifdecoder.GifDecoder;
import com.bumptech.glide.gifdecoder.GifHeaderParser;
import com.bumptech.glide.gifdecoder.StandardGifDecoder;
import com.bumptech.glide.load.DataSource;
import com.bumptech.glide.load.engine.DiskCacheStrategy;
import com.bumptech.glide.load.engine.GlideException;
import com.bumptech.glide.load.resource.gif.GifBitmapProvider;
import com.bumptech.glide.load.resource.gif.GifDrawable;
import com.bumptech.glide.request.RequestListener;
import com.bumptech.glide.request.target.Target;

import java.io.File;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.file.Files;

/**
 * 多媒体文件
 */
public class Media extends RelativeLayout {

    private File file = null;
    private boolean isImage = false;
    private boolean isGif = false;
    private GifDrawable gif = null;
    private boolean isVideo = false;
    private boolean isPlaying = false;
    private ImageView image = null;
    private VideoView video = null;
    private MediaPlayListener listener = null;
    private final int MESSAGE_PLAY_DONE = 0;
    private int duration = 3000;

    private final Handler handler = new Handler(Looper.myLooper()) {
        @Override
        public void handleMessage(@NonNull Message msg) {
            super.handleMessage(msg);
            handler.removeMessages(MESSAGE_PLAY_DONE);
            onPlayDone();
        }
    };

    public Media(Context context) {
        super(context);
    }

    public Media(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public Media(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    public void setMedia(File file) {
        this.file = file;
        String fileType = "";
        try {
            fileType = Files.probeContentType(file.toPath());
        } catch (IOException e) {
            e.printStackTrace();
        }
        Log.d(TAG, fileType);
        if (fileType.startsWith("image/")) {
            isImage = true;
            if (fileType.equals("image/gif")) {
                isGif = true;
            }
            image = new ImageView(getContext());
            image.setScaleType(ImageView.ScaleType.CENTER_INSIDE);
            image.setBackgroundColor(Color.WHITE);
            if (isGif) {
                Glide.with(getContext()).load(file.getAbsolutePath())
                        .diskCacheStrategy(DiskCacheStrategy.RESOURCE)
                        .listener(new RequestListener<Drawable>() {
                            @Override
                            public boolean onLoadFailed(@Nullable GlideException e, Object model, Target<Drawable> target, boolean isFirstResource) {
                                return false;
                            }

                            @Override
                            public boolean onResourceReady(Drawable resource, Object model, Target<Drawable> target, DataSource dataSource, boolean isFirstResource) {
                                gif = (GifDrawable) resource;
                                gif.stop();
                                gif.setLoopCount(1);
                                ByteBuffer buffer = gif.getBuffer();
                                GifBitmapProvider provider = new GifBitmapProvider(Glide.get(getContext()).getBitmapPool());
                                GifDecoder decoder = new StandardGifDecoder(provider);
                                decoder.setData(new GifHeaderParser().setData(buffer).parseHeader(), buffer);
                                int _duration = 0;
                                for (int i = 0; i < gif.getFrameCount(); i ++) {
                                    _duration += decoder.getDelay(i);
                                }
                                if (duration < _duration) {
                                    duration = _duration;
                                }
                                return false;
                            }
                        }).into(image);
            } else {
                Glide.with(getContext()).load(file.getAbsolutePath())
                        .diskCacheStrategy(DiskCacheStrategy.RESOURCE)
                        .into(image);
            }
            addView(image, new RelativeLayout.LayoutParams(-1, -1));
        } else if (fileType.startsWith("video/")) {
            isVideo = true;
        }
    }

    /**
     * 播放
     */
    public void play() {
        if (!isPlaying()) {
            if (isVideo) {
                video = new VideoView(getContext());
                //video.setVideoPath(file.getAbsolutePath()); // MediaPlayer java.io.FileNotFoundException: No content provider
                video.setVideoURI(Uri.fromFile(file));
                video.setOnCompletionListener(mp -> {
                    onPlayDone();
                });
                video.setOnErrorListener((mp, what, extra) -> {
                    mp.stop();
                    return false;
                });
                video.setOnPreparedListener(mp -> {
                    mp.setLooping(false);
                    mp.start();
                });
                addView(video, new RelativeLayout.LayoutParams(-1, -1));
            } else if (isImage) {
                if (isGif && (null != gif)) {
                    try {
                        gif.startFromFirstFrame();
                    } catch (Exception ex) {
                        gif.start();
                    }

                }
                waiting();
            }
        }
    }

    /**
     * 停止
     */
    public void stop() {
        isPlaying = false;
        handler.removeMessages(MESSAGE_PLAY_DONE);
        if (isVideo && (null != video)) {
            video.stopPlayback();
            video.setOnCompletionListener(null);
            video.setOnPreparedListener(null);
            video.setOnErrorListener(null);
            video.suspend();
            video = null;
        } else if (isGif && (null != gif)) {
            gif.stop();
        }
    }

    /**
     * 播放状态
     * @return
     */
    public boolean isPlaying() {
        return (isVideo && (null != video)) ? video.isPlaying() : isPlaying;
    }

    private void waiting() {
        if (!handler.hasMessages(MESSAGE_PLAY_DONE)) {
            isPlaying = true;
            handler.sendEmptyMessageDelayed(MESSAGE_PLAY_DONE, duration);
        }
    }

    private void onPlayDone() {
        isPlaying = false;
        if (null != listener) {
            listener.onPlayDone(this);
        }
    }

    /**
     * 媒体类型
     * @return
     */
    public Type getType() {
        return isVideo ? Type.Video : isImage ? Type.Image : Type.Unknown;
    }

    /**
     * 注册事件监听器
     * @param listener
     */
    public void addMediaPlayListener(MediaPlayListener listener) {
        this.listener = listener;
    }

    /**
     * 多媒体文件类型
     */
    public enum Type {
        Image,
        Video,
        Unknown
    }

    /**
     * 媒体播放监听器
     */
    public interface MediaPlayListener {
        void onPlayDone(Media media);
    }
}

```

然后MediaAdapter（PagerAdapter）是这样：

```java

import android.annotation.SuppressLint;
import android.content.Context;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.viewpager.widget.PagerAdapter;
import androidx.viewpager.widget.ViewPager;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class MediaAdapter extends PagerAdapter {

    private final List<Media> items = new ArrayList<>();
    private final Context context;
    private final ViewPager pager;
    private int position = 0;

    private int getPosition() {
        return position;
    }
    private void setPosition(int position) {
        this.position = position;
    }

    public MediaAdapter(Context context, ViewPager pager) {
        this.context = context;
        pager.addOnPageChangeListener(new ViewPager.OnPageChangeListener() {
            @Override
            public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {
              
            }

            @Override
            public void onPageSelected(int position) {
                Media previous = items.get(getPosition() % items.size());
                if (null != previous) {
                    previous.stop();
                }
                setPosition(position);
                Media media = items.get(position % items.size());
                if (null != media) {
                    media.play();
                }
            }

            @Override
            public void onPageScrollStateChanged(int state) {
              
            }
        });
        this.pager = pager;
    }

    /**
     * 设置播放文件列表
     * @param files
     */
    public void setMedias(List<File> files) {
        items.clear();
        for (File file : Objects.requireNonNull(files)) {
            Media media = new Media(context);
            media.setMedia(file);
            if (media.getType().equals(Media.Type.Image)
                    || media.getType().equals(Media.Type.Video)) {
                media.addMediaPlayListener(m -> next());
                items.add(media);
            }
        }
    }

    /**
     * 播放
     */
    public void play() {
        Media media = getCurrentMedia();
        if (media != null) {
            media.play();
        }
    }

    /**
     * 当前播放的文件
     * @return
     */
    private Media getCurrentMedia() {
        return items.get(pager.getCurrentItem() % items.size());
    }

    /**
     * 下一个
     */
    private void next() {
        if (items.size() > 1) {
            pager.setCurrentItem((pager.getCurrentItem() < Integer.MAX_VALUE) ? (pager.getCurrentItem() + 1) : 0);
        }
    }

    @Override
    public int getCount() {
        return Integer.MAX_VALUE;
    }

    @Override
    public int getItemPosition(@NonNull Object object) {
        return POSITION_NONE;
    }

    @Override
    public boolean isViewFromObject(@NonNull View view, @NonNull Object object) {
        return view == object;
    }
    @Override
    public void destroyItem(@NonNull ViewGroup container, int position, @NonNull Object object) {
        container.removeView(items.get(position % items.size()));
    }

    @NonNull
    @Override
    public Object instantiateItem(@NonNull ViewGroup container, int position) {
        View view = items.size() > 0 ? items.get(position % items.size()) : null;
        if (null != view) {
            container.addView(view);
        }
        return view;
    }
}

```

MediaView也很简单：

```java

import android.content.Context;
import android.util.AttributeSet;
import android.widget.RelativeLayout;

import androidx.viewpager.widget.ViewPager;

import java.io.File;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

/**
 * MediaView
 */
public class MediaView extends RelativeLayout {
    private ViewPager pager;
    private MediaAdapter adapter;

    public MediaView(Context context) {
        super(context);
        initView();
    }

    public MediaView(Context context, AttributeSet attrs) {
        super(context, attrs);
        initView();
    }

    public MediaView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView();
    }

    private void initView() {
        pager = new ViewPager(getContext());
        adapter = new MediaAdapter(getContext(), pager);
        pager.setAdapter(adapter);
        pager.setOffscreenPageLimit(1);
        addView(pager, new LayoutParams(-1, -1));
    }

    /**
     * 文件列表
     * @param files
     */
    public void setMedias(List<File> files) {
        adapter.setMedias(files);
    }

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        adapter.play(); // 自动开始播放
    }
}

```

第二个问题，USB事件的处理，首先我们定义一个UsbBroadcastReceiver类，继承BroadcastReceiver并重写onReceive方法：

```java

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.widget.Toast;

/**
 * USB事件监听
 */
public class UsbBroadcastReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        String path;
        switch (intent.getAction()) {
            case Intent.ACTION_MEDIA_MOUNTED: // 插入U盘
                Toast.makeText(context, intent.getData().getPath() + " mounted", Toast.LENGTH_LONG).show();
                // 播放处理
                break;
            case Intent.ACTION_MEDIA_UNMOUNTED: // 拔出U盘
                Toast.makeText(context, intent.getData().getPath() + " unmounted", Toast.LENGTH_LONG).show();
                // 停止播放
                break;
        }
    }
}

```

然后我们要在AndroidManifest.xml中声明权限并注册监听器：

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.READ_MEDIA_STORAGE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.USB_PERMISSION" />

    ...

    <application>

        ...

        <receiver
            android:name=".UsbBroadcastReceiver"
            android:enabled="true"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_MOUNTED" />
                <action android:name="android.intent.action.MEDIA_UNMOUNTED" />
            </intent-filter>
        </receiver>

        ...

    </application>

</manifest>
```


完整的项目代码已经推到Github，感兴趣的朋友可以到仓库拉取代码：[mas-client](https://github.com/devylee/mas-client)
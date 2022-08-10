---
title     : 将Flash转换成HTML5 Canvas
category  : devy
layout    : post
date      : 2022-08-09
tags      : 
  - Flash
  - Animate
  - HTML5
  - CreateJS
class     : post tag-flash tag-html5 tag-animate tag-createjs
comments  : true
---

> 又是救急，一位多年没什么联系的旧同事突然联系到我，他的客户有一批Flash动画要转成HTML5，因为知道我曾经在Flash/Flex技术领域有着丰富的经验和造诣，希望我可以帮他们完成这批动画的转换。也恰好最近手里项目空档期，也就应许下来，不成想，原本以为三五天就可以搞定的事，竟成了我两周来的噩梦！今天就来说说我在Flash转HTML5时遇到的几处坑吧……

<!--more-->

想想我上一次用Flash/Flex大概是2010年的事了，当时是主导一个前端基于Flash/Flex技术的棋牌游戏平台项目开发。想当年的Flash/Flex技术还是相当成熟的，即便是在浏览器必须安装Flash控件的情况下，依然不影响这项技术的大量应用。但是当HTML5标准出来之后，Adobe并没有第一时间拥抱它，加之日益普及的智能手机也无法支持Flash，当时我就预感到这项技术势必走向没落。所以，从那时至今的10多年时间，我没有再关注这项技术的发展。然而在2020年底Adobe停止更新之后，令我没想到的是，Flash竟然换了一个身份，变成了现在的[Animate](https://www.adobe.com/products/animate.html)还继续存活着！但如果说是时代成就了Flash，那不得不说Animate在这个时代也略显尴尬了！

项目的整个过程中，从Animate 2017到2022，除了2020，其他版本我都用了，每个版本都有它的问题，比如：有的版本调整画布大小，个别剪辑发布后会变形窜位，有的版本在缺少字体的时候，文字显示不全，有的版本则深陷于发布时的“JavaScript Error”……好在最终2018、2019两个版本还算令我满意，也不是说这两个版本不存在上述问题，只是至少这两个版本也算能稳定的支撑我把项目做下来（这也足见Adobe在Animate上的用心程度了！）。

不同版本的Animate在界面布局、菜单和格式转换支持上有些许差异，但就我的需求（将Flash转换成HTML5 Canvas）而言，并没有对版本的特别依赖。总体上，Animate也延续了Flash的功能和能力，对于一个熟悉Flash的人来说，非常容易上手（我相信对于一个新手来说，也依然很容易上手）。Animate可以直接打开编辑Flash源文件（.fla文件，事实上，这也是Animate的源文件扩展名，可见它与Flash一衣带水的联系）。

我们言归正传吧！

首先，将Flash转换成HTML5，要转换一下文档格式，这在Animate中有两种方式：
1. 通过菜单：File > Convert To > HTML5 Canvas（2017版本这个功能在Commands菜单下）；
2. 新建一个HTML5 Canvas文档，然后将Flash中所需的图层和剪辑复制到新建的文档中。

这两种方法我都在用，这个步骤通常也不会有什么问题，但这个步骤选择哪种方式，确实会对后续操作产生一些影响。第一种方式很简单，但输出的HTML5 Canvas动画更容易出现问题，比如：剪辑窜位变形（在Animate的编辑模式下，是看不到这个问题的，但是发布的动画会有问题），或者发布时遇到“JavaScript Error”。相比下来，第二种方式操作上会比较繁琐一些，但是后续出现的问题则要少得多。

第二步，就是调整动画尺寸，因为源动画尺寸是1024 * 576，按客户的要求，需要调整为1920 * 1080，这一步绝大部分情况下，直接在文档属性面板中修改画布尺寸，并勾选“Scale Content”选项即可，但这种方式并不总是奏效，因为毫无规律的在某些情况下，动画发布后会出现个别剪辑元件还是保持着原来的尺寸，或者有窜位的情况发生，所以，当这种情况发生时，我就要回到上述第一个步骤，换一种方式来尝试，还不行的话，就换一个Animate版本（比如从2019换成2018），问题通常就会得到解决。

第三步，要将剪辑库中的资源导出为文件，这一步比较简单，直接发布（或：Command/Ctrl + Enter），Animate会将引用的图片、音视频等资源以文件形式导出到images、sounds等文件夹中，第一次导出成功后，就可以将剪辑库中的所有音频元件删除了，这些音频元件有时也是导致发布时出现“JavaScript Error”的原因之一。

接下来要检查时间轴中的命名元件的命名是否有冲突，Flash中，时间轴的不同的原件在不同的关键帧中可以使用同一个命名，比如：两个Button，在第一个关键帧中用了Button A，命名为“btn”，第二个关键帧中，用了Button B，同样命名为“btn”，这在Flash时代，在各自的关键帧中通过ActionScript进行对象引用，并不会出现问题。但在HTML5 Canvas中，这会导致引用异常（当然有时候它也会如你期望的那样正常工作），所以，严谨的方式是，我们把第一个“btn”改为“btnA”，第二个“btn”改为“btnB”，这样可以避免引用的混乱。

再接下来就是Animate文档中的ActionScript了，Flash转成HTML5 Canvas后，其中所有的ActionScript代码都被注释掉了，因为实际上在HTML5 Canvas中，你不能再使用ActionScript，而是基于[CreateJS](https://createjs.com/)库的JavaScript。如果你的动画足够简单，比如只有用到诸如：stop、gotoAndStop、gotoAndPlay这类控制动画流程的脚本，那处理起来就简单很多，这些方法在CreateJS中依然存在，只不过，Flash中的帧是从1开始的，而CreateJS中是从0开始。比如：原来`gotoAndStop(1)`表示停止在第一帧，现在你要换成`this.gotoAndStop(0)`，这里要特别注意`this`，如果你有自定义的函数，比如下面这样：

```javascript
function replay() {
    this.gotoAndPlay(0);
}
```

上述代码中，`this`并不是对时间轴对象的引用，所以我们必须对变量进行声明，像下面这样：

```javascript
const _this = this;
function replay() {
    _this.gotoAndPlay(0);
}
```

如果你的ActionScript足够复杂，那我建议，就不要在Animate文档中重新编写脚本了，因为Animate实在不是一个方便的“代码编辑器”，尤其对我们这些码农而言！我们可以在关键帧中定义一些事件（Event），然后通过在javascript中监听Canvas事件来进行交互处理。举个例子，在时间轴的最后一帧加一个`complete`事件，当捕获到这个事件，动画就跳到第1帧重新播放，我们可以这样做：

首先我们在时间轴的最后一帧加上脚本：

```javascript
this.stop();
this.dispatchEvent(new createjs.Event('complete')); // 触发事件
```

然后我们在发布后的html文件中的适当位置修改相应的javascript：

```javascript
...

// 监听事件
exportRoot.addEventListener('complete', onMovieComplete);

...

// 事件回调
function onMovieComplete(e) {
    exportRoot.gotoAndPlay(0);
}

...

```

好啦，进行到这里，我们基本上可以离开Animate（除非你还需要对动画里的内容进行调整），剩下的就是基于CreateJS的javascript编程了。animate发布的HTML5文件包括一个HTML文件和一个js文件，js文件你就不要动了，它是对Animate时间轴动画和元件的描述，我们主要还是来看html文件，通常发布出来，它是下面这个样子的：

```html
<!DOCTYPE html>
<!--
	NOTES:
	1. All tokens are represented by '$' sign in the template.
	2. You can write your code only wherever mentioned.
	3. All occurrences of existing tokens will be replaced by their appropriate values.
	4. Blank lines will be removed automatically.
	5. Remove unnecessary comments before creating your template.
-->
<html>
<head>
<meta charset="UTF-8">
<meta name="authoring-tool" content="Adobe_Animate_CC">
<title>indexgame</title>
<!-- write your code here -->
<script src="https://code.createjs.com/createjs-2015.11.26.min.js"></script>
<script src="indexgame.js?1660103482948"></script>
<script>
var canvas, stage, exportRoot, anim_container, dom_overlay_container, fnStartAnimation;
function init() {
	canvas = document.getElementById("canvas");
	anim_container = document.getElementById("animation_container");
	dom_overlay_container = document.getElementById("dom_overlay_container");
	var comp=AdobeAn.getComposition("97D94CEC1018413B9C73A09A74E98D32");
	var lib=comp.getLibrary();
	var loader = new createjs.LoadQueue(false);
	loader.addEventListener("fileload", function(evt){handleFileLoad(evt,comp)});
	loader.addEventListener("complete", function(evt){handleComplete(evt,comp)});
	var lib=comp.getLibrary();
	loader.loadManifest(lib.properties.manifest);
}
function handleFileLoad(evt, comp) {
	var images=comp.getImages();	
	if (evt && (evt.item.type == "image")) { images[evt.item.id] = evt.result; }	
}
function handleComplete(evt,comp) {
	//This function is always called, irrespective of the content. You can use the variable "stage" after it is created in token create_stage.
	var lib=comp.getLibrary();
	var ss=comp.getSpriteSheet();
	var queue = evt.target;
	var ssMetadata = lib.ssMetadata;
	for(i=0; i<ssMetadata.length; i++) {
		ss[ssMetadata[i].name] = new createjs.SpriteSheet( {"images": [queue.getResult(ssMetadata[i].name)], "frames": ssMetadata[i].frames} )
	}
	exportRoot = new lib.indexgame();
	stage = new lib.Stage(canvas);
	stage.enableMouseOver();	
	//Registers the "tick" event listener.
	fnStartAnimation = function() {
		stage.addChild(exportRoot);
		createjs.Ticker.setFPS(lib.properties.fps);
		createjs.Ticker.addEventListener("tick", stage);
	}	    
	//Code to support hidpi screens and responsive scaling.
	AdobeAn.makeResponsive(false,'both',false,1,[canvas,anim_container,dom_overlay_container]);	
	AdobeAn.compositionLoaded(lib.properties.id);
	fnStartAnimation();
}
</script>
<!-- write your code here -->
</head>
<body onload="init();" style="margin:0px;">
	<div id="animation_container" style="background-color:rgba(255, 255, 255, 1.00); width:1920px; height:1080px">
		<canvas id="canvas" width="1920" height="1080" style="position: absolute; display: block; background-color:rgba(255, 255, 255, 1.00);"></canvas>
		<div id="dom_overlay_container" style="pointer-events:none; overflow:hidden; width:1920px; height:1080px; position: absolute; left: 0px; top: 0px; display: block;">
		</div>
	</div>
</body>
</html>
```

我就不对上述代码进行翻译了，我就说说，这里可能出现的问题以及如何解决吧。

首先，我遇到的第一个问题，因为原始的flash文件是1024 * 576，现在放大成了1920 * 1080，部分动画在浏览器中的播放速度明显变慢（也可能是因为动画元件过于复杂导致的？因为动画播放的过程中，浏览器的cpu和内存的资源占用明显升高，甚至风扇都开启了“狂躁”模式）！这个问题纠结了我两天，改变Animate文档的帧率（FPS）也不见任何效果！后来，尝试在代码中指定`exportRoot`的帧率，就是下面这样的：

```javascript
...

function handleComplete(evt,comp) {
	//This function is always called, irrespective of the content. You can use the variable "stage" after it is created in token create_stage.
	var lib=comp.getLibrary();
	var ss=comp.getSpriteSheet();
	var queue = evt.target;
	var ssMetadata = lib.ssMetadata;
	for(i=0; i<ssMetadata.length; i++) {
		ss[ssMetadata[i].name] = new createjs.SpriteSheet( {"images": [queue.getResult(ssMetadata[i].name)], "frames": ssMetadata[i].frames} )
	}
	exportRoot = new lib.indexgame();
	exportRoot.framerate = lib.properties.fps; // 指定exportRoot的帧率为Animate文档中设定的FPS帧率
	stage = new lib.Stage(canvas);
	stage.enableMouseOver();	
    ...
}
...
```

动画播放的速度可以了（不过似乎动画的丝滑程度似乎是有所下降），我也怀疑`createjs.Ticker.setFPS(lib.properties.fps)`这行代码的作用是什么？不过眼下我并不想在这个问题上再继续耗费时间了！

因为每套动画包含一部主动画和若干部子动画或视频，原来的Flash是通过`loadSWF`来实现的，现在需要调整一下，倒也不难，可以通过监听动画中的按钮点击事件，然后向`animation_container`注入iframe或者VideoPlayer来实现。这里我就不多说了，我想说说这里我遇到的一个坑，就是音频的自动播放问题（基于CreateJS的SoundJS实现）。

我的Mac一直以来默认的浏览器都是Safari，有一些子动画是带有音频的，动画播放的时候需要自动播放音频，但是我发现怎么都没办法让这些音频自动播放，而且Safari也没有任何提示，直到我用Chrome尝试，并发现了一条警告：`The AudioContext was not allowed to start. It must be resumed (or created) after a user gesture on the page. https://goo.gl/7K7WLu`。好吧，音频的播放需要有一个有效的用户行为来触发！这个问题其实在Chrome和Firefox中还好说，因为这是个子动画，用户是需要点击主动画中的按钮才会进入子动画，而点击动作就是一个有效的用户行为，所以，当子动画被打开，其中的音频是可以自动播放，子动画中类似下面的代码是有效的：

```javascript
function initSounds() {
	createjs.Sound.alternateExtensions = ["mp3"];
 	createjs.Sound.on("fileload", onSoundLoaded);
	createjs.Sound.registerSound("sounds/1.mp3", "s1");
	createjs.Sound.registerSound("sounds/2.mp3", "s2");
	createjs.Sound.registerSound("sounds/3.mp3", "s3");
	createjs.Sound.registerSound("sounds/4.mp3", "s4");
}
var flag = 0;
function onSoundLoaded(e) {
	if (e.id == 's1') {
		playSound();
	}
}
function playSound() {
	if (flag < 4) {
		flag++;
		var instance = createjs.Sound.play('s' + flag);
		instance.on("complete", playSound);
	}
}
```

但是对于Safari而言，这一切就不那么幸运了，所以，我需要对它做一些兼容处理，也就是要将音频的播放放在主动画中，就类似下面这样：

```javascript
var isMacSafari = /Mac.*Safari/i.test(navigator.userAgent); // Safari浏览器检测
var flag = 0;
...

function initMovie() {
	exportRoot.stop();
	var btn = exportRoot.btn1;
	btn.addEventListener('click', onBtn1Click);
}

function onBtn1Click(e) {
	showSubMovie('part1/index.html'); // 显示子动画
	if (isMacSafari) { // Safari浏览器Autoplay Policy问题fix
		playSound();
	}
}

function initSounds() {
	createjs.Sound.alternateExtensions = ["mp3"];
	if (isMacSafari) { // Safari浏览器Autoplay Policy问题fix
		createjs.Sound.registerSound("part1/sounds/1.mp3", "s1");
		createjs.Sound.registerSound("part1/sounds/2.mp3", "s2");
		createjs.Sound.registerSound("part1/sounds/3.mp3", "s3");
		createjs.Sound.registerSound("part1/sounds/4.mp3", "s4");
	}
}

function playSound() {
	if (flag < 4) {
		flag++;
		var instance = createjs.Sound.play('s' + flag);
		instance.on("complete", playSound);
	}
}
...
```

OK，音频播放问题算是解决了。但其实，如果动画中没有互动，我倒是更倾向直接把这些动画转成视频，但是我不清楚为什么这些Flash动画当初的设计者不是将动画放到主场景（Scene）的时间轴，而是将动画做成了剪辑元件（MovieClip），然后再将元件放到主场景（第一帧），这样的做法，结果就是使用Animate直接导出的视频只有一帧！除非我将元件中的所有图层拷贝到主场景，但是因为元件中的动画坐标原点与主场景的坐标原点不同，这导致复制出来的图层在主场景中，元件都是错位的！额～看着还有几十部动画要转换，我已经没有耐心挨个关键帧去调整了！所以动画的设计制作遵循一定的规范，也是有必要的。

再接下来就是动画中的交互了，包括拖拽、Tween动画、遮罩（Mask）以及滤镜，其中Tween动画可以用CreateJSs的TweenJS来实现；关于遮罩，则需要注意一点，就是作为遮罩的元件不要`addChild`到场景中，否则遮罩无效！至于拖拽，Flash中可以很方便的用`startDrag()`和`stopDrag()`实现，但现在，我们需要用到几个事件，分别是`mousedown`、`pressmove`和`pressup`，大概像下面这样：

```javascript
...

function initMovie(e) {
	exportRoot.stop();
	exportRoot.addEventListener('pressmove', onPressMove);
	exportRoot.addEventListener('pressup', onPressUp);
	for (let i = 1; i < 5; i++) {
		var mc = exportRoot['mc' + i];
		mc.cursor = 'pointer';
		mc.pos = { x : mc.x, y : mc.y}; // 保存剪辑元件的初始位置
		mc.addEventListener('mousedown', onMcMouseDown);
	}
}

var dragging = {};

/**
 * 鼠标按下
 */
function onMcMouseDown(e) {
	dragging = { mc: e.currentTarget, x : e.stageX, y : e.stageY};
}

/**
 * 拖动
 */
function onPressMove(e) {
	var x = e.stageX - dragging.x;
	var y = e.stageY - dragging.y;
	if (dragging.mc) {
		dragging.mc.x += x;
		dragging.mc.y += y;
		dragging.x = e.stageX;
		dragging.y = e.stageY;
	}
}

var flag = [];
/**
 * 放下
 */
function onPressUp(e) {
	if (dragging.mc) {
		dragging.x = e.stageX;
		dragging.y = e.stageY;

		// TODO 根据当前推拽位置进行相应处理

		...

		// 对象位置还原
		dragging.mc.x = dragging.mc.pos.x;
		dragging.mc.y = dragging.mc.pos.y;
		dragging = {};
	}
}
```

这里需要注意一点，就是如果动画是被拉伸的（放大或者缩小），在`onPressMove`的时候，`x`和`y`的偏移量要进行拉伸比例换算，否则，它的移动速度和鼠标的移动速度会不匹配。

哦，对了，对于那些`alpha=0`的元件，在createjs中是响应不到任何用户事件（比如`click`）的，一个简单的办法是，让alpha大于0，比如：`alpha=0.01`。

这几天紫外线过敏，我的胳膊和腿暴露在阳光下的的部分都起了疹子，此刻愈发的痒，上了年纪，免疫力几乎是以肉眼可见的速度在下降！就先整理这么多吧。




参考：

1. [CreateJS Docs](https://createjs.com/docs)

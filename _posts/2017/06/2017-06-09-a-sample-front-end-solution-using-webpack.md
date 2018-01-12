---
title     : 在Web前端开发中使用Node和webpack
date      : "2017-06-09 9:30:00"
categories: devy
tags      : 
  - webpack
  - nodejs
layout    : post
class     : "post tag-webpack tag-nodejs"
comments  : true
---

> 标题说的很明白，本文我只介绍使用[Node](https://nodejs.org)和[webpack](https://webpack.js.org/)来实现的一个Web前端的构建方案，而不是一个Node实现的全栈方案。至于后端，其实我个人觉得有很多比Node更好的选择，但这不是本文的重点。

<!--more-->

## 写在前面

Node火了，似乎你不用Node都不好意思说自己是个全栈！但你确定要在你的项目中使用一个前后端都是JS的全栈？任何一种技术都有它值得推崇的地方，但同样也有它适合和不适的领域，所以我个人在项目的技术体系和方案选择上会综合很多因素来选择**相对适合**{:.highlight}的，从不会撕逼于各种技术社区和流派！

Well，你可能要问，我**选择Node+webpack做前端的理由是什么**{:.highlight}呢？好吧，我承认这是个问题，但其实，我也只是在尝试组合了几种方案之后觉得这个还蛮简单的！因为我的需求本就不复杂：

- 首先，我需要一个前端资源的bundler；
- 其次，要兼容当下主流的JS模块化规范（[CommonJS](http://www.commonjs.org/)、[AMD](https://github.com/amdjs/amdjs-api/wiki/AMD)之类）；
- 最后，就是要有一个方便本地开发调试的服务。

好啦，废话说的有点多，该放码了！

## 那就开始吧

[Node的安装](https://nodejs.org/en/download/)我不想赘述，很容易就可以寻到针对不同系统的安装Guide，我就当你的系统里已经有Node了，至于webpack的版本，当然是2.x！首先，我们来初始化一个项目，你可以手动或者像我一样使用`npm init`创建一个`package.json`，内容大概会是这个样子：

```json
{
  "name": "using-webpack",
  "version": "1.0.0",
  "description": "a sample about using webpack",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "license": "MIT"
}
```

接下来，我们要安装几个依赖：

```bash
$ npm install --save-dev webpack webpack-dev-server
```

如果你的js要用到lodash、jQuery之类，可以继续安装它们：

```bash
$ npm install --save lodash jquery
```

这些依赖默认都会安装到node_modules目录下，我们看下`package.json`，多了`devDependencies`和`dependencies`（当然你也可以手动编写`package.json`然后运行`npm install`命令来安装这些依赖）：

```json
{
  ...
  "devDependencies": {
    "webpack": "^2.6.1",
    "webpack-dev-server": "^2.4.5"
  },
  "dependencies": {
    "jquery": "^3.2.1",
    "lodash": "^4.17.4"
  }
}

```

下面，我们来创建一个static文件夹用来存放所有的前端资源文件（JS、CSS、图片、字体等等）和一个webpack配置文件`webpack.config.js`：

```javascript
var path = require('path');

var config = {
  context: path.resolve(__dirname, 'static/'),
  entry: {
    'app': path.resolve(__dirname, 'static/js/main.js')
  },
  output: {
    filename: path.posix.join('js', '[name].bundle.js'),
    publicPath: '/'
  }
}

module.exports = config;
```

我们需要一个简单的HTML文件`static/sample.html`：

```html
<!DOCTYPE html>
<html>

<head>
    <meta charset="utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />

    <title>Sample Page</title>

</head>
<body>
    <div class="wrapper">
        <h1>Sample Page</h1>

        <p>
            This is a sample html page.
        </p>
    </div>
    <script type="text/javascript" src="js/app.bundle.js"></script>
</body>
</html>
```

接下来我们要在`static/js/main.js`里写点东西（在页面中追加“Hello World”）：

```javascript
(function(){
    var hello = document.createElement('p');
    hello.innerText = 'Hello World';
    document.getElementsByTagName('div').item(0).appendChild(hello);
})();
```

我们可以用[webpack-dev-server](https://webpack.js.org/configuration/dev-server/)来启动一个开发服务，测试我们的代码，不过，在此之前，我们要来完善一下`webpack.config.js`，增加`devServer`相关的配置：

```javascript
...
var config = {
...
  devServer: {
    contentBase: path.resolve(__dirname, 'static/'),
    publicPath: '/'
  }
}
...
```

然后，我们就可以通过命令行`node_modules/.bin/webpack-dev-server --config ./webpack.config.js`来启动DevServer，默认地址是`http://localhost:8080/`。浏览`http://localhost:8080/sample.html`就可以看到效果了。

> 我们可以把上面这个命令配置在`package.json`的`scripts`中[^1]，例如下面的配置，这样启动DevServer，只要执行`npm start`就可以了：
```json
{
...
  "scripts": {
    "start": "node_modules/.bin/webpack-dev-server --config ./webpack.config.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
...
}
```

JS可以加载并工作了，但对于Web前端而言还远远不够，至少我们还需要个样式表！

## 加载样式

样式表的加载就需要用到webpack的loaders[^2]了，对于CSS的加载，我们要用到两个Loader：[style-loader](https://webpack.js.org/loaders/style-loader/)和[css-loader](https://webpack.js.org/loaders/css-loader/)（*如果你的项目用到[LESS](http://lesscss.org/)或者[SASS](http://sass-lang.com/)，那你还需要用到[less-loader](https://webpack.js.org/loaders/less-loader/)或者[sass-loader](https://webpack.js.org/loaders/sass-loader/)*）。

安装相关依赖

```bash
$ npm install --save-dev style-loader css-loader
```

`webpack.config.js`增加相关的配置

```javascript
var path = require('path');

var config = {
  ...
  module: {
    rules: [
      {
        test: /\.css$/,
        use: [ 'style-loader', 'css-loader' ]
      }
    ]
  }
}

module.exports = config;
```

增加CSS文件`static/css/app.css`，定义一些样式，例如：

```css
body {
    margin: 0;
    padding: 0
}

.wrapper {
    width: 80%;
    margin: 20px auto;
    min-width: 320px;
}
```

然后在`static/js/main.js`中要import这个CSS：

```javascript

import '../css/app.css';

...
```

`npm start`并访问`http://localhost:8080/sample.html`，是的，我们写的样式生效了，但用浏览器的开发工具看一下你就会发现，这些样式是被webpack打包到`app.bundle.js`然后由JS写到页面中。如果我们要把样式输出到相应的css文件，那么我们还需要做一点工作，这个时候就要用到[ExtractTextWebpackPlugin](https://webpack.js.org/plugins/extract-text-webpack-plugin/)。首先，我们当然要先安装这个插件：

```bash
$ npm install --save-dev extract-text-webpack-plugin
```

然后，配置我们的`webpack.config.js`（注意css rule中的`publicPath: '../'`，这是根据你的项目来配置的，会影响到css文件中url()函数所引用资源的生成路径）：

```javascript
var path = require('path');
var ExtractTextPlugin = require("extract-text-webpack-plugin");

var config = {
  ...
  module: {
    rules: [{
        test: /\.css$/,
        use: ExtractTextPlugin.extract({
          fallback: "style-loader",
          use: "css-loader",
          publicPath: '../'
        })
      }
    ]
  },
  plugins: [
    new ExtractTextPlugin({
      filename: path.posix.join('css', '[name].bundle.css')
    }),
  ],
  ...
}

module.exports = config;
```

最后我们要在HTML中引入CSS：

```html
<!DOCTYPE html>
<html>

<head>
    ...
    <link rel="stylesheet" type="text/css" href="css/app.bundle.css" />
    ...
</head>

...
```

再`npm start`并浏览`http://localhost:8080/sample.html`，嗯！Nice~ 

## 图片资源

接下来，我们该为页面加上几张图来美化一下了，首先，还是先来安装相应的[Loaders](https://webpack.js.org/loaders/#files)，在本例中，我就用[file-loader](https://webpack.js.org/loaders/file-loader/)了，因为这个比较简单！执行安装命令：`npm install --save-dev file-loader`，然后修改`webpack.config.js`：

```javascript
...
var config = {
  ...
  module: {
    rules: [
      ...
      {
        test: /\.(png|gif|jpe?g)$/,
        loader: 'file-loader',
        options: {
          name: 'img/[name].[ext]'
        }
      }
    ]
  },
  ...
}

module.exports = config;
```

现在，把要用到的图片放到`static/img`目录下，就可以在CSS或者HTML中引用图片了。实际的开发中可能还会遇到字体、视频等静态资源的加载，这些都可以通过配置相应的rules来实现。

写到这里，我们已经可以开始基本的Web前端开发工作了。但实际的项目中我们似乎才只是迈出第一步而已！

## Build

> 通常项目发布的时候，我们要将前端资源打包输出，在这个过程中，通常用到的javascript和样式表会被compile或者minify。如果是用到less、sass，会被编译成css，或者用到[CoffeeScript](http://coffeescript.org/)之类，也要被编译成javascript。

webpack为我们提供了方便的`webpack -p`[^3]命令。还是之前的`webpack.config.js`，稍作修改，增加关于输出路径的配置，我们将发布文件输出到`dist/static/`：

```javascript
...
output: {
    filename: path.posix.join('js', '[name].bundle.js'),
    path: path.resolve(__dirname, 'dist/static/'),
    publicPath: '/'
  },
...
```

然后执行`node_modules/.bin/webpack -p --config ./webpack.config.js`，当然，你也可以把这个命令配置到到`package.json`的`scripts`中：

```json
...
"scripts": {
    "build": "node_modules/.bin/webpack -p --config ./webpack.config.js",
    ...
  },
...
```

这样，我们只需要执行`npm run build`就可以了。

不过你可能会发现一个问题：css中用url()引用的图片可以正常的被输出到dist，但是html中直接引用的图片就不行。解决这个问题的一种办法是在js中声明，比如`import '../img/sample-pic.jpg'`或者`require('../img/sample-pic.jpg')`；或者使用[html-loader](https://webpack.js.org/loaders/html-loader/)来处理引用图片的html文件，即：`npm install --save-dev html-loader`然后在js中`require('html-loader!../sample.html')`。

不过直接使用html-loader的一个问题是，html文件内容会被一起打包到js中，这并不是我们想要的结果。我们可以利用file-loader和extract-loader将其单独输出：

安装依赖：

```bash
npm install --save-dev extract-loader
```

配置`webpack.config.js`：

```javascript
...
var config = {
  ...
  module: {
    rules: [
      ...
      {
        test: /\.html?$/,
        use: [{
            loader: 'file-loader',
            options: {
              name: '[name].[ext]',
            },
          },
          {
            loader: 'extract-loader',
          },
          {
            loader: 'html-loader'
          }
        ]
      }
    ]
  },
  ...
}

module.exports = config;
```

现在，再次`webpack -p`，文件已经可以正确的输出到dist了。不过因为使用了require()，所生成的js中依然会有类似`e.exports='module.exports = __webpack_public_path__ + "sample.html";'`这种代码。如果你像我一样对代码有着严重的洁癖，可以把相关的require()移出，比如像我把他放到`webpack.config.js`中另外指定了一个叫html的entry：

```javascript
var path = require('path');
...
var config = {
  context: path.resolve(__dirname, 'static/'),
  entry: {
    'app': [
      path.resolve(__dirname, 'static/js/main.js'),
      path.resolve(__dirname, 'static/css/app.css')
    ],
    'html': path.resolve(__dirname, 'static/sample.html')
  },
  ...
}

module.exports = config;
```

当然这还是会输出一个`html.bundle.js`，不过我们完全可以忽略或者删除这个文件！

## 关于加载第三方库

实际项目中我们通常还会用到一些第三方的库资源，比如[lodash](https://lodash.com/)、[jQuery](http://jquery.com/)。只要是npm仓库中有的，都可以通过`npm install`来安装，并在代码中import或者require()来使用，或者通过`webpack.config.js`配置将这些库单独打成vendor包：

```javascript
var path = require('path');

var config = {
  context: path.resolve(__dirname, 'static/'),
  entry: {
    'vendor': ['lodash', 'jquery'],
    ...
  },
  ...
}

module.exports = config;
```

然后在HTML文件中通过script标签引用：

```html
<!DOCTYPE html>
<html>

<head>
    ...
    <script type="text/javascript" src="js/vendor.bundle.js"></script>
    ...

</head>
...
```

**需要注意**{:.highlight}的是有些类库的使用可能会有一些问题（不过这类问题大多通过webpack或者类库官方的文档就可以找到说明和解决的办法），比如jQuery会出现`Uncaught ReferenceError: jQuery is not defined`问题，这个问题是由于webpack打包和minify的过程会对js类库中的变量进行混淆，这会导致jQuery库的$和jQuery全局定义丢失，这个问题可以用[ProvidePlugin](https://webpack.js.org/plugins/provide-plugin/)来解决，`webpack.config.js`配置：

```javascript
var webpack = require("webpack");
...
var config = {
  ...
  plugins: [
    ...
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery"
    })
    ...
  ],
  ...
}

module.exports = config;
```

好了，现在你可以放心的在代码中使用$了。我们可以将之前写的那段测试代码改造一下试试效果：

```javascript
(function(){
    $('.wrapper').append($('<p>Hello World</p>'));
})();
```

嗯，看起来，没什么问题了！

当我们项目有多个entry points，而且又有重复引用类库的时候，你会发现类库被重复的打包在各个js中！这一点webpack也为我们想到了，就是[CommonsChunkPlugin](https://webpack.js.org/plugins/commons-chunk-plugin/)插件，使用也并不复杂，就是在`webpack.config.js`中增加配置，在本例中可以这样：

```javascript
var path = require('path');
var webpack = require("webpack");
...

var config = {
  entry: {
    'vendor': ['jquery'],
    'app': [
      path.resolve(__dirname, 'static/js/main.js'),
      path.resolve(__dirname, 'static/css/app.css')
    ]
  },
  ...
  plugins: [
    ...
    new webpack.optimize.CommonsChunkPlugin({
      name: "vendor",
      minChunks: Infinity,
    })
  ],
  ...
}

module.exports = config;
```

## 最后

好了，这个sample算是写完了，完整的代码放在Github上，需要的同学可以[戳这里](https://github.com/devylee/using-webpack)。欢迎交流！



---


*参考：*


[^1]: [npm-run-script \: Run arbitrary package scripts](https://docs.npmjs.com/cli/run-script); [npm-scripts \: How npm handles the \"scripts\" field](https://docs.npmjs.com/misc/scripts)

[^2]: [Webpack Loaders](https://webpack.js.org/concepts/loaders/)

[^3]: [Building for Production](https://webpack.js.org/guides/production-build/)
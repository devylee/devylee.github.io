---
title     : macOS下PHP与Python的多版本环境共存
date      : 2018-01-11 9:00:00
category  : devy
layout    : post
tags      : 
  - Multiple-Version
  - php
  - python
  - macos
  - homebrew
class     : post tag-multiple-version tag-php tag-python tag-macos
comments  : true
---

> 对于一个开发人员来说，经常要面对不同的开发环境、测试环境、线上环境……很多时候这些环境的配置并不一致，原因太多就不赘述了。要是能在一台机器上配置多个不同的环境，需要的时候可以方便的在这些环境中进行切换，至少不是件坏事，而且这在很多系统上，实现起来并不难。

<!--more-->

macOS是自带了php、python和ruby的，升级到High Sierra后，php的版本是7.1.7，python的版本是2.7.10，ruby的版本是2.3.3。我猜大部分的程序开发者都像我一样，不会使用系统自带的运行环境，我们更多的会选择手动安装，或者选择另外的包管理工具，比如[MacPorts](https://www.macports.org/)或者[Homebrew](https://brew.sh/)。

> 其实我本来是MacPorts的粉儿，升级到High Sierra后，我转粉了Homebrew。很难说两者孰优孰劣，我改投Homebrew的最主要原因是它不需要sudo。至于Homebrew的安装，我想应该就不用我说了。好啦，Talk is cheap！放码～

## PHP

“PHP是世界上最好的编程语言！”作为LNMP的忠实粉儿，这句话总是在我提到PHP时余音绕梁般浮现在我脑中！果然是真爱啊！公司的项目后端主要是PHP栈，虽然现在PHP的版本已经7.2了，但是由于历史原因，当前线上环境还是跑的5.6，我们还用的[Phalcon](https://phalconphp.com)框架，它的Release版本已经是3.3，但我们线上还停留在2时代。于是乎，我也会纠结于安装哪个版本？PHP56+Phalcon2吧，无法体验到PHP新版本的特性，技术总要面向未来啊；PHP7+Phalcon3吧，项目代码的执行就会有问题了！所以，对我来说，最理想的还是两个环境都有，只要彼此不冲突，可以随时切换就好。好在，Homebrew是可以实现这个需求的！

### 先tap：

```
$ brew tap homebrew/homebrew-php
```

### 然后我们先来安装PHP72：

```
$ brew install php72 php72-phalcon
```

\* *当然这里你可以安装其他你需要的PHP扩展。*

### 接下来我们安装PHP56

安装之前要unlink php72

```
$ brew unlink php72
```

安装php56

```
$ brew install php56
```

安装Phalcon2扩展（由于Homebrew自带的php56-phalcon扩展版本是3.3，所以这里我选择从代码编译安装）：

```
$ git clone git://github.com/phalcon/cphalcon.git
$ cd cphalcon
$ git checkout 2.0.x
$ cd ext
$ ./install 
```

\* *这里我用cphalcon/ext替换了官方文档中使用的cphalcon/build进行安装，因为使用build运行时会出现一些难以预料的问题，可能是某些编译参数不同的原因。*

install成功最后会看到这样的信息：

```
Build complete.
Don't forget to run 'make test'.

Password:
Installing shared extensions:     /usr/local/Cellar/php56/5.6.xx_x/lib/php/extensions/no-debug-non-zts-20131226/
Installing header files:           /usr/local/Cellar/php56/5.6.xx_x/include/php/
```


添加php扩展：

```
$ vi /usr/local/etc/php/5.6/conf.d/ext-phalcon.ini
```
内容如下：

```ini
[phalcon]
extension="/usr/local/Cellar/php56/5.6.xx_x/lib/php/extensions/no-debug-non-zts-20131226/phalcon.so"
```

> 当然其实我们还可以用`brew create`来新建一个phalcon2的Formula，这种方式更方便用homebrew来维护：

```
$ brew create https://github.com/phalcon/cphalcon/archive/phalcon-v2.0.13.tar.gz --tap homebrew/homebrew-php
```

上面命令会创建一个`/usr/local/Homebrew/Library/Taps/homebrew/homebrew-php/Formula/cphalcon.rb`文件，我们可以把这个文件重命名：

```
$ mv /usr/local/Homebrew/Library/Taps/homebrew/homebrew-php/Formula/cphalcon.rb /usr/local/Homebrew/Library/Taps/homebrew/homebrew-php/Formula/php56-phalcon2.rb 
```

然后修改这个文件：

```
$ vi /usr/local/Homebrew/Library/Taps/homebrew/homebrew-php/Formula/php56-phalcon2.rb
```

内容如下：

```ruby
require File.expand_path("../../Abstract/abstract-php-extension", __FILE__)
  
class Php56Phalcon2 < AbstractPhp56Extension
  init
  desc "High performance, full-stack PHP framework delivered as a C extension."
  homepage "https://phalconphp.com"
  url "https://github.com/phalcon/cphalcon/archive/phalcon-v2.0.13.tar.gz"
  sha256 "0a1bd6afe902c6f2f68cf5e2f2785503f5ad95d1d2cf1b66c77154c483a08a35"

  depends_on "pcre"

  def install
    Dir.chdir "build/64bits"

    safe_phpize
    system "./configure", "--prefix=#{prefix}",
                          phpconfig,
                          "--enable-phalcon"
    system "make"
    system "mv", "modules/phalcon.so", "modules/phalcon2.so"
    prefix.install "modules/phalcon2.so"
    write_config_file if build.with? "config-file"
  end
end
```

然后执行`brew install php56-phalcon2`，大概会看到类似如下的输出：

```
==> Installing php56-phalcon2 from homebrew/php
==> Downloading https://github.com/phalcon/cphalcon/archive/phalcon-v2.0.13.tar.gz
Already downloaded: /Users/devylee/Library/Caches/Homebrew/php56-phalcon2-2.0.13.tar.gz
==> /usr/local/opt/php56/bin/phpize
==> ./configure --prefix=/usr/local/Cellar/php56-phalcon2/2.0.13 --with-php-config=/usr/local/opt/php56/bin/php-config --enable-phalcon
==> make
==> mv modules/phalcon.so modules/phalcon2.so
==> Caveats
To finish installing phalcon2 for PHP 5.6:
  * /usr/local/etc/php/5.6/conf.d/ext-phalcon2.ini was created,
    do not forget to remove it upon extension removal.
  * Validate installation via one of the following methods:
  *
  * Using PHP from a webserver:
  * - Restart your webserver.
  * - Write a PHP page that calls "phpinfo();"
  * - Load it in a browser and look for the info on the phalcon2 module.
  * - If you see it, you have been successful!
  *
  * Using PHP from the command line:
  * - Run `php -i "(command-line 'phpinfo()')"`
  * - Look for the info on the phalcon2 module.
  * - If you see it, you have been successful!
==> Summary
🍺  /usr/local/Cellar/php56-phalcon2/2.0.13: 5 files, 3.4MB, built in 1 minute 9 seconds
```

phalcon2已经成功安装了。

好了，执行`php -v`:

```
$ php -v
PHP 5.6.33 (cli) (built: Jan  7 2018 11:14:18) 
Copyright (c) 1997-2016 The PHP Group
Zend Engine v2.6.0, Copyright (c) 1998-2016 Zend Technologies
```

切到PHP7：

```
$ brew unlink php56
$ brew link php72
$ php -v
PHP 7.2.0 (cli) (built: Dec  3 2017 21:46:44) ( NTS )
Copyright (c) 1997-2017 The PHP Group
Zend Engine v3.2.0, Copyright (c) 1998-2017 Zend Technologies
```

也就是需要的时候，只要使用brew的unlink和link命令在不同的php版本间切换即可。方便多了吧？！


## Python

> Homebrew中的python2和python3并无冲突，也就是可以执行`$ brew install python2 python3`就可以同时安装这两个版本。而且python2有virtualenv；python3有pyvenv，都可以用来维护虚拟运行环境。但是python2如果要使用ipython或者pythonw就会出现错误，会提示找不到Framework。好在我们还有另一个选择，那就是[pyenv](https://github.com/pyenv/pyenv)。

首先我们安装pyenv，用homebrew就可以了：

```
$ brew install pyenv
```

然后初始化一下pyenv的运行环境参数，其实也就是在你的.bash_profile中做了些配置，执行`$ pyenv init`就可以了。

查看可用的python版本：

```
$ pyenv install --list
```

安装你需要的python版本，比如2.7.14、3.6.3，注意安装之后（或者pip安装了带有可执行命令的包之后）要执行rehash：

```
$ pyenv install 2.7.14
$ pyenv install 3.6.3
$ pyenv rehash
```

需要注意的是，如果需要支持Framework，要加上--enable-framework参数：

```
$ env PYTHON_CONFIGURE_OPTS="--enable-framework" pyenv install 2.7.14
```

设置python的版本，可以设置全局global，也可以使用local设置当前目录的：

```
$ pyenv global 3.6.3
$ pyenv local 2.7.14
```

`pyenv version` 查看当前的python版本，`pyenv versions`列出系统已安装的的python版本。更多的pyenv命令和配置可以参考：

* [Wiki](https://github.com/pyenv/pyenv/wiki)
* [Command Reference](https://github.com/pyenv/pyenv/blob/master/COMMANDS.md)

还是很简单方便的是吧！

## Ruby

对于这货，其实只要安装了[RVM](https://rvm.io/)就OK了！
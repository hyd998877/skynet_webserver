# skynet_webserver
A (very) simple web server written on skynet

## Build

For Linux, install autoconf first for jemalloc:

```
git clone https://github.com/hyd998877/skynet_webserver.git
cd skynet_webserver
make
./skynet/skynet config
```

then you can do in brower:

```
http://127.0.0.1:8080
![image](https://github.com/hyd998877/skynet_webserver/blob/master/doc/pic.jpg)

```
the example is in test/main.lua

You can register one url:

```
	skynet.call(handle, "lua", "register_url", "/login",{handle=skynet.self(), callback="login"})
```

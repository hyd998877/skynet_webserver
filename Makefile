.PHONY: all skynet clean

PLAT ?= linux
SHARED := -fPIC --shared
LUA_CLIB_PATH ?= luaclib

CFLAGS = -g -O2 -Wall -I$(LUA_INC)

LUA_CLIB =
LUA_INC = skynet/3rd/lua

SKYNET_PATH = skynet

all : skynet


skynet/Makefile :
	git clone https://github.com/cloudwu/skynet.git
	
skynet : skynet/Makefile
	cd skynet && $(MAKE) $(PLAT) && cd ..

all : \
  $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)


clean :
	cd skynet && $(MAKE) clean
	

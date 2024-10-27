# Xdebug Manager
This tools helps quickly managing xdebug on Ubuntu for installed php version.
You can use it to:
- toggle xdebug
- change mode
- change port

# Installation
You might install this file within /usr/local/bin on ubuntu and make it executable using `chmod +x /usr/local/bin/xdebug`. You can rename the executable to anything else than "xdebug".

# Available Commands

```
xdebug --enable --php 8.2
xdebug --disable --php 8.2
xdebug --mode coverage --php 8.3
xdebug --mode debug --php 8.4
xdebug --port 8003 --php 8.2
```

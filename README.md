## 镜像说明

**构建版本：** V008R006C007B0024 X86（64位）

**暴露端口：** 54321

### 环境变量

#### `KINGBASE_SYSTEM_PASSWORD`

> 初始system用户密码，默认值`123456`

#### `EXTEND_INIT_PARAM`

> 扩展人大金仓数据库初始化参数 ，`Dockerfile`中默认值为`--locale=en_US.UTF-8 -m oracle --enable-ci`，默认用户名称，密码文件和容器中数据存储目录不能修改（我写死了，方便统一文件挂载）；具体参数请参考 https://help.kingbase.com.cn/v8/admin/reference/ref-server/initdb.html?highlight=init#admin-reference-ref-server-initdb--page-root

#### `ORA_INPUT_EMPTYSTR_ISNULL`

> 输入空字符串时的处理措施。on表示将输入的空字符串作为null值处理。off表示不处理。在pg模式下，以下参数默认为off状态，且禁止将其打开

### 文件夹挂载

- /opt/Kingbase/ES/V8 该文件夹必须拥有777权限，或者你不挂载数据出来
- /home/kingbase/license.dat 授权文件，必须挂载

#### 授权文件下载地址

https://www.kingbase.com.cn/sqwjxz/index.htm

## 使用说明

> 下面的案例采用`docker-compose`部署，挂载了数据目录和授权文件，并暴露了端口出来，默认用户`system`的密码设置为`123456`

### docker-compose.yml

```dockerfile
version: '3'
services:
  kingbase-v8r6:
    image: cloudlessa/kingbase:v8r6
    container_name: kingbase-v8r6
    networks:
      - default
    environment:
      - "KINGBASE_SYSTEM_PASSWORD=123456"
    volumes:
      - "自己磁盘的挂载目录:/opt/Kingbase/ES/V8"
      - "自己磁盘的挂载目录/license.dat:/home/kingbase/license.dat"
    ports:
      - 54321:54321
networks:
  default:
    external:
      name: cloudlessa
```

### 启动停止

- 启动

> ```sh
> docker-compose up -d
> ```

- 查看日志

>  ```sh
>  docker ps -a
>  docker log 容器id
>  ```

> 如果出现如下日志则启动成功

```
fixing permissions on existing directory /opt/Kingbase/ES/V8/data ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... Asia/Shanghai
creating configuration files ... ok
Begin setup encrypt device
initializing the encrypt device ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
create security database ... ok
load security database ... ok
syncing data to disk ... ok


Success. You can now start the database server using:

    /home/kingbase/Server/bin/sys_ctl -D /opt/Kingbase/ES/V8/data -l logfile start

initdb: warning: enabling "trust" authentication for local connections
You can change this by editing sys_hba.conf or using the option -A, or
--auth-local and --auth-host, the next time you run initdb.
2023-02-08 09:22:07.127 CST [27] LOG:  sepapower extension initialized
2023-02-08 09:22:07.130 CST [27] LOG:  starting KingbaseES V008R006C007B0012 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 4.1.2 20080704 (Red Hat 4.1.2-46), 64-bit
2023-02-08 09:22:07.130 CST [27] LOG:  listening on IPv4 address "0.0.0.0", port 54321
2023-02-08 09:22:07.130 CST [27] LOG:  listening on IPv6 address "::", port 54321
2023-02-08 09:22:07.131 CST [27] LOG:  listening on Unix socket "/tmp/.s.KINGBASE.54321"
2023-02-08 09:22:07.168 CST [27] LOG:  redirecting log output to logging collector process
2023-02-08 09:22:07.168 CST [27] HINT:  Future log output will appear in directory "sys_log".
```

## 镜像构建过程

### linux源文件准备

> `kingbase.tar.gz`该压缩文件包含了`Server`端所有的东西；我是先在`Centos7`上安装了一次，然后把`Server`目录复制出来压缩的。

### 注意 
```
#或者直接从服务器上压缩
cd /opt/Kingbase/ES/V8/KESRealPro/V008R006C007B0024/Server
tar -czvf kingbase.tar.gz Server/
#压缩成kingbase.tar.gz
#人大金仓版本不一样安装位置可能不一样,自己找下就行了。
```

### `docker-entrypoint.sh`

```
#! /bin/bash

chmod -R +x /home/kingbase/Server

if [ ! -e "/opt/Kingbase/ES/V8/data/SYS_VERSION" ];then
  mkdir -p /opt/Kingbase/ES/V8/data
  echo ${KINGBASE_SYSTEM_PASSWORD-123456} > /home/kingbase/password
  echo "init param --> /home/kingbase/Server/bin/initdb -U SYSTEM --pwfile=/home/kingbase/password -E UTF8 -D /opt/Kingbase/ES/V8/data ${EXTEND_INIT_PARAM}"
  /home/kingbase/Server/bin/initdb -U SYSTEM --pwfile=/home/kingbase/password -E UTF8 -D /opt/Kingbase/ES/V8/data ${EXTEND_INIT_PARAM}
  if [ -n "${ORA_INPUT_EMPTYSTR_ISNULL}" ]; then
    sed -i "s/ora_input_emptystr_isnull.*/ora_input_emptystr_isnull = ${ORA_INPUT_EMPTYSTR_ISNULL}/" /opt/Kingbase/ES/V8/data/kingbase.conf
  fi
fi

/home/kingbase/Server/bin/kingbase -D /opt/Kingbase/ES/V8/data/
```

## `Dockerfile`

```dockerfile
FROM centos:7
MAINTAINER cloudlessa

RUN groupadd kingbase && useradd -g kingbase -m -d /home/kingbase -s /bin/bash kingbase
RUN mkdir -p /opt/Kingbase/ES/V8
ADD kingbase.tar.gz /home/kingbase
ADD docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh
RUN chown -R kingbase:kingbase /opt/Kingbase/ES/V8
RUN chown -R kingbase:kingbase /home/kingbase

ENV KINGBASE_SYSTEM_PASSWORD=123456
ENV EXTEND_INIT_PARAM="--locale=en_US.UTF-8 -m oracle --enable-ci"
EXPOSE 54321
USER kingbase

ENTRYPOINT ["sh","-c","/docker-entrypoint.sh"]
```

## 构建镜像

```
kingbase-es-v8-r6-docker
├── docker-entrypoint.sh
├── Dockerfile
├── kingbase.tar.gz
├── license.dat
```

```sh
docker build -t kingbase:v8r6 .
```


## 参考地址
> https://hub.docker.com/r/huzhihui/kingbase

> https://github.com/chyidl/kingbase-es-v8-r6-docker
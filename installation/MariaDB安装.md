# MariaDB 安装
MariaDB 官方确实提供了适用于多种操作系统的二进制分发版，包括适用于 macOS 的版本。你可以通过以下几种方式在 macOS 上安装 MariaDB：

### 1. 使用 Homebrew 安装

Homebrew 是 macOS 上非常流行的包管理器，使用它可以很方便地安装 MariaDB。

- **安装 MariaDB**:
  安装完 Homebrew 后，可以通过以下命令安装 MariaDB：
  ```bash
  brew install mariadb
  ```

- **启动 MariaDB**:
  安装完成后，可以使用以下命令启动 MariaDB 服务：
  ```bash
  brew services start mariadb
  ```
  或者如果你不想要它开机自启，可以使用：
  ```bash
  mysql.server start
  ```

初次登录 MariaDB: 刚安装完后，你可以用以下命令以 root 用户身份无需密码登录：
```shell
mysql
```
登录到 MariaDB shell 后，创建和赋权用户即可。

### 2. 下载官方二进制文件

你也可以直接从 MariaDB 官方网站下载适用于 macOS 的二进制文件。访问 [MariaDB 下载页面](https://mariadb.org/download/) 并选择适合 macOS 的版本进行下载和安装。

### 3. 使用 Docker 安装

如果你的开发环境支持 Docker，那么也可以考虑使用 Docker 来运行 MariaDB。这提供了一个隔离的环境，并且易于管理多个数据库实例。

- **拉取 MariaDB 镜像**:
  ```bash
  docker pull mariadb
  ```

- **运行容器**:
  ```bash
  docker run --name some-mariadb -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mariadb:tag
  ```
  请将 `my-secret-pw` 替换为你自己的密码，`some-mariadb` 替换为你的容器名称，`tag` 替换为所需的版本标签。


## 一. 使用configdrive(cdrom)
&emsp;&emsp;直接将metadata、user_data等数据通过cdrom的形式挂载到虚拟机上，cloudinit和cloudbaseinit可以很方便的通过读取本地文件的方式根据metadata执行相关配置工作
1. openstack配置  
&emsp;&emsp;配置/etc/nova/nova.conf中DEFAULT块`force_config_drive=true`，使每个虚拟机创建过后，都能挂载一个包含metadata的cdrom
2. 使cloudinit（cloudbaseinit)配置实现读取cdrom，而非169.254.169.254
    - cloudinit默认会优先使用cdrom配置，不需要特殊配置
    - cloudbaseinit配置
    - cloudbaseinit metadata_services可配置项：
    - cloudbase init现在所有的支持的services

services name | description
---|---
cloudbaseinit.metadata.services.httpservice.HttpService | 通过http(169.254.169.254）得到metadata
cloudbaseinit.metadata.services.configdrive.ConfigDriveService | cdrom方式
cloudbaseinit.metadata.services.ec2service.EC2Service |
cloudbaseinit.metadata.services.maasservice.MaaSHttpService |
cloudbaseinit.metadata.services.cloudstack.CloudStack |
cloudbaseinit.metadata.services.opennebulaservice.OpenNebulaService |
&emsp;&emsp;因此在cloudbaseinit的conf配置文件中设置`metadata_services=cloudbaseinit.metadata.services.configdrive.ConfigDriveService`, 如果需要增加其它services，以逗号隔开就可以了。cloudbaseinit会顺序尝试加载所有相应配置的服务，直到找到一个可用的服务

３. IP注入支持

- openstack配置  
&emsp;&emsp;配置/etc/nova/nova.conf中DEFAULT块`flat_injected=true`，使openstack支持网络注入
- cloudinit配置  
&emsp;&emsp;设置resolv.conf(需要在/etc/cloud/cloud.cfg的cloud_init_modules 下面增加:  `- resolv-conf`。默认情况下这个是不支持的)
- cloudbaseinit配置  
&emsp;&emsp;cloudbaseinit有支持network注入的plugin，只要在plugins中加入`cloudbaseinit.plugins.common.networkconfig.NetworkConfigPlugin`就可以了

## 二. 使用metadata service
### Centos 6.5
1. 安装
    - 已测试版本（centos6.5 ubuntu12.04)
    - centos和ubuntu确定现在可以正常的安装包
    - 将svn路径svn://10.16.128.232/ttcloud/openstack_juno/cloudinit/cloud-init-0.7.6（如不能访问SVN，会提供相应的离线包）下的代码拷贝到虚拟机中，并进入拷贝过后cloud-init-0.7.6对应的目录，执行此路径下的install.sh,等待安装完成
2. 配置
    - 允许root登录  
    &emsp;&emsp;修改/etc/cloud/cloud.cfg配置文件,cloud-init默认禁用root登录，需要开户，否则重启后，root登录会不成功
    ```
    disable_root: 0
    ssh_pwauth: 1
    ```
    （注：有些配置是用false代表0，用true代表1。具体看一下原始的配置文件）
    并删除以下所示的default_user块
    ```
    system_info:
       # Default user name + that default users groups (if added/used)
       default_user:
         name: ubuntu
         lock_passwd: True
         gecos: Ubuntu
         groups: [adm, audio, cdrom, dialout, dip, floppy, netdev, plugdev, sudo, video]
         sudo: ["ALL=(ALL) NOPASSWD:ALL"]
         shell: /bin/bash
    ```
    - 使cloud-init在机器再次重启时运行（测试使用，镜像制作时可不必关注）

            rm -rf /var/lib/cloud/*

３. 结合openstack metadata service

-  openstack Juno版本虚拟机Metadata service虚拟机请求流程
![image](https://github.com/tianmaofu/stuff/blob/master/img/metadata.png)
- qrouter虚拟路由主要是实现一个PNAT,重定向端口
- nenutron-ns-metadata-proxy向请求头部添加X-Forwarded-For和X-Quantum-Router-ID，分别表示虚拟机的fixedIP和router的ID，以区分具体虚拟机。对于每个虚拟路由都会创建一个相应的nenutron-ns-metadata-proxy
- neutron-metadata-agent根据请求头部的X-Forwarded-For和X-Quantum-Router-ID参数，向Quantum service查询虚拟机ID，然后向Nova Metadata service服务发送请求
- Nova的metadata service是随着nova-api启动的，会同时启动三个服务：ec2, osapi_compute, metadata。另外可以在非控制接点启动nova-api-metadata服务完成最后的请求数据查询并返回
- 通过在/neutron/dhcp-agent.ini中设置`enable_isolated_metadata = True`，让dhcp自动给虚拟机加169.254.169.254默认路由

### 三. 使用user_data实现相应功能（yaml格式，需要特别注意文档的缩进）
&emsp;&emsp;目录/usr/share/doc/cloud-init/examples下有很多demo
- 密码修改
```
#cloud-config
chpasswd:
    list: |
        root:yourpassword
        user:passwd
        expire: False
```
- 包安装
```
#cloud-config
packages:
    - package_1
    - [package_2, version_num]
```
- 设置resolv.conf(需要在/etc/cloud/cloud.cfg的cloud_init_modules 下面增加:  - resolv-conf。默认情况下这个是不支持的)
```
#cloud-config
manage-resolv-conf: true
resolv_conf:
    nameservers:
        - '114.114.114.114'
        - '8.8.8.8'
    searchdomains:
        - first.domain.com
        - second.domain.com
    domain: domain.com
    options:
        option1: value1
        option2: value2
        option3: value3
```
- 开机执行命令

```
#cloud-config
runcmd:
    - command1
    - command2
```


- 以密码登录形式创建用户
```
# passwd中不能直接使用明文，需要加密。
# On Debian/Ubuntu (via the package "whois")
mkpasswd --method=SHA-512 --rounds=4096

# OpenSSL (note: this will only make md5crypt.  While better than plantext it should not be considered fully secure)
openssl passwd -1

# Python(change password and salt values)
python -c "import crypt, getpass, pwd; print crypt.crypt('password', '\$6\$SALT\$')"
密码生成：python -c "import crypt, getpass, pwd; print crypt.crypt('qwe123QWE', '\$6\$xHszl/dQwys/l\$')"
```
```
#cloud-config

users:
   - name: username
     gecos: Foo B. Bar
     lock_passwd: false
     groups: [wheel, adm]
     passwd: $6$xHszl/dQwys/l$G1TE3vZ/59i0CS3T2s0bBKyfEMXLVFOoZrXq8TiAg0WH0dWQDYb0odH7bMWOkb7ciNm3FjK1raDDXhzVhi/C1/
```
- 以密钥形式创建用户
```
#cloud-config
users:
    - name: barfoo_sshtest
      gecos: Bar B. Foo
      sudo: ALL=(ALL) NOPASSWD:ALL
      groups: users, admin
      ssh-import-id: None
      lock-passwd: true
      ssh-authorized-keys:
        - <ssh pub key 1>
        - <ssh pub key 2>
```
### windows

1. 安装
    - 安装官方包
    ```
    https://www.cloudbase.it/downloads/CloudbaseInitSetup_Beta_x64.msi
    https://www.cloudbase.it/downloads/CloudbaseInitSetup_Beta_x86.msi
    # 参照：https://github.com/cloudbase/cloudbase-init
    ```
    &emsp;&emsp;安装后，配置文件在 {安装路径}\Cloudbase-Init\conf下，名为cloudbase-init.conf
    - 禁用cloudbase init服务,并设置cloudbase-init.conf，添加stop_service_on_exit=false

    - 添加cloudbase init开机脚本  
    &emsp;&emsp;进入组策略界面，进入启动脚本目录，在此目录下新建 start_cloudinit.bat文件，在文件中输入以下内容（如果你安装的cloudbase文件口路径不同，请修改之）
    ```
     "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\Python27\Scripts\cloudbase-init.exe" --config-file "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init.conf"
     ```
    &emsp;&emsp;并保存（制作镜像过程中不要运行此bat脚本，如果不小心运行了，请删除下文4提到的注册表中cloudbase init配置中plugins中的全部键）

    并添加到启动脚本列表中

    - 设置脚本启动相关设置  
    &emsp;&emsp;在组策略设置界面，相应点击 计算机配置 ——>管理模板——>系统——>脚本（以下设置的名称可能在各个系统中有所区别）,禁用 异步运行启动脚本。（win2012默认是启用，win2003默认是关闭，各个系统有可能不一样，需要关注一下各选项说明）
    将 指定组策略脚本的最长等待时间 设置为0

2. 安装phicloud源码  
&emsp;&emsp;安装完成后，将svn上cloudbaseinit的代码覆盖到..\Cloudbase Solutions\Cloudbase-Init\Python27\Lib\site-packages\cloudbaseinit中

3. 其它说明  
    &emsp;&emsp;如果使用的是win2003r2-32-20150325.img这个镜像制作新的镜像的话，需要在注册中改过的MTU值都修改为默认的1500

    &emsp;&emsp;windows下对于每一个处理类，执行完后都会在注册表相应位置添加一个键值，1表示只执行一次，且已经执行，2下次开机继续执行
    ```
    32位系统 ：HKEY_LOCAL_MACHINE\Software\Cloudbase Solutions\Cloudbase-Init
    64位系统 ：HKEY_LOCAL_MACHINE\Software\Wow6432Node\Cloudbase Solutions\Cloudbase-Init
    ```
    - cloudbase init现在所有的支持的插件

    plugin name | description
    ---|---
    CreateUserPlugin | 创建用户
    SetUserPasswordPlugin | 设置用户名密码
    MTUPlugin | 设置mtu,暂时不支持2003和xp
    NTPClientPlugin | 通过dhcp设置ntp客户端
    SetHostNamePlugin | 设置计算机名及windows的hostname
    SetUserSSHPublicKeysPlugin | 实现密钥登录
    UserDataPlugin | 读取user_data数据，实现运行脚本
    LocalScriptsPlugin | 运行虚拟机本地脚本（事先做在系统中）
    ConfigWinRMListenerPlugin |  启动一个WinRM监听的服务
    ConfigWinRMCertificateAuthPlugin | WinRM证书
    ExtendVolumesPlugin | 扩盘

    &emsp;&emsp;对于上述插件，可以在conf配置文件中单独的禁用和调整运行顺序，运行顺序以在plugins中出现的顺序执行，以下是现在默认启动的内容。现在建议只启动MTUPlugin,CreateUserPlugin,SetUserPasswordPlugin,具体启动内容镜像制作的时候关注一下
    plugins=cloudbaseinit.plugins.common.mtu.MTUPlugin,cloudbaseinit.plugins.windows.createuser.CreateUserPlugin,cloudbaseinit.plugins.common.setuserpassword.SetUserPasswordPlugin,cloudbaseinit.plugins.windows.ntpclient.NTPClientPlugin,cloudbaseinit.plugins.common.sethostname.SetHostNamePlugin,cloudbaseinit.plugins.common.networkconfig.NetworkConfigPlugin,cloudbaseinit.plugins.windows.licensing.WindowsLicensingPlugin,cloudbaseinit.plugins.common.sshpublickeys.SetUserSSHPublicKeysPlugin,cloudbaseinit.plugins.windows.extendvolumes.ExtendVolumesPlugin,cloudbaseinit.plugins.common.userdata.UserDataPlugin,cloudbaseinit.plugins.windows.winrmlistener.ConfigWinRMListenerPlugin,cloudbaseinit.plugins.windows.winrmcertificateauth.ConfigWinRMCertificateAuthPlugin,cloudbaseinit.plugins.common.localscripts.LocalScriptsPlugin

4. 与openstack结合
    - 用户添加或者修改密码
    ```
    nova meta 35bd74ec-a5c1-4d29-b36b-5d227ba45b4d set admin_user='admin' admin_pass='qwe123QWE'
    ```
    &emsp;&emsp;cloudbase对于上面的metadata数据对应两个操作：
        - 如果admin_user在系统中不存在，则新建用户，并分配一个随机密码
        - 更改admin_user的密码为admin_pass
    - 设置hostanme  
    &emsp;&emsp;hostname写死在代码中了,具体代码中..\nova\api\metadata\base.py中
    - 运行脚本  
    &emsp;&emsp;脚本运行是通过user_data来指定的  
    &emsp;&emsp;user_data文件开头格式

    | format | description|
    | :--------| :-- |
    | rem cmd | windows批处理 |
    | #!/usr/bin/env python | python脚本 |
    | #! | bash命令 |
    | #(ps1\|ps1_sysnative) | PowershellSysnative脚本 |
    | #ps1_x86 | Powershell |
    | </?(script\|powershell)> | EC2Config, 如\<script\>...\</script\> 或者 \<powershell\>...\</powershell\>的脚本，前者是bat批处理代码，后者是PowershellSysnative脚本 |

    &emsp;&emsp;如果user-data是以Content-Type: multipart开头的，这种方式是以邮件的方式一次传递多个脚本，暂时不知道应该怎么写

# Cloudera Manager

Cloudera中，使用Cloudera Manager是安装、配置、管理、监控Hadoop生态最好的方式。

## The Vocabulary of Cloudera Manager

![image-20210122141710723](Cloudera%20Manager.assets/image-20210122141710723.png)

上图介绍了Cloudera Manager的基础组件及其关系。

deployment是最大的整体，包括了许多clusters。clusters是许多运行同一版本的hosts集合。Host以rack形式管理。Services是具体系统的实例，拥有很多roles，每个roles关联一个单独的host。Role config groups是一次配置多个roles的一种方法。

配置和环境相关联，环境间存在层级（小环境被包含于大环境配置中）。如：DataNode存放日志文件的路径通常在“Role Config Group”中指定，但也可在单个role中特指。

service与role关系类比于java中Class与Object的关系。需要注意的是，通常情况下一个host上运行的多个service，一个service也在多个host上运行。

## Agent/Server Architecture

Cloudera Manager有个central server，以往被称作“SCM Server”、“CMF Server”。这个server运行着CDH UI Web Server以及管理监控CDH的应用。所有与CDH安装、配置服务、启停服务相关的操作，斗鱼Cloudera Manager Server相关。

每个被管理的host上都运行着Cloudera Manager Agent，他们负责启停Linux进程、解压配置、触发安装路径、监控host。

## Heartbeating

心跳机制组成了Cloudera Manager最基础的通信信道。默认情况下，agent每15向server发送心跳信息以获取agent任务。agent固定时间向server请求任务。如果用户通过UI界面关停一个service，server会将start命令置为失败状态。

![phil2](Cloudera%20Manager.assets/phil2.png)





## Agent Process Supervision in Detail

Agent一个最主要的工作是启停process。当agent通过heartbeat检测到新process运行，agent会为该process创建目录/var/run/cloudera-scm-agent，并将相关配置信息解压至该目录。很重要的是：一个Cloudera Manager process永远不会独自旅行（携带有其他信息）。一个process不仅是exec()中的参数，也包括配置文件、需要创建目录、以及其他配置信息。这种方式下，不会存在配置文件过期的问题。

每个process私有运行及配置环境允许我们控制单个process，这在某些特定场景下十分重要。以下是一个但强度命名process目录下的内容：

```bash
$ tree -a /var/run/cloudera-scm-agent/process/879-hdfs-NAMENODE/
  /var/run/cloudera-scm-agent/process/879-hdfs-NAMENODE/
  ??? cloudera_manager_agent_fencer.py
  ??? cloudera_manager_agent_fencer_secret_key.txt
  ??? cloudera-monitor.properties
  ??? core-site.xml
  ??? dfs_hosts_allow.txt
  ??? dfs_hosts_exclude.txt
  ??? event-filter-rules.json
  ??? hadoop-metrics2.properties
  ??? hdfs.keytab
  ??? hdfs-site.xml
  ??? log4j.properties
  ??? logs
  ?   ??? stderr.log
  ?   ??? stdout.log
  ??? topology.map
  ??? topology.py
```

 process真正地启停依赖于supervisord开源系统。Supervisord关注重定向日志文件，通知我们process失败。

Cloudera Manager将Hadoop的“client configuration”存放在/etc/hadoop/conf目录下，hbase存于/etc/hbase/conf，hive存于/etc/hive/conf。默认情况下，若你的应用需要和Hadoop交互，需要先从/etc/hadoop/conf目录下获取NameNode及JobTracker地址。Cloudera Manager会区别“client”及“server”配置。像HDFS负载因子、MapReduce任务堆内存大小等默认情况下为client配置。因此，当致谢设置改变时，需要使用“Deploy Client Configuration”来更新对应的目录。

Cloudera Manager管理的processs不使用/etc/hadoop/conf下目录配置，而使用自己路径下的私有拷贝配置。这样设计的目的有两个：一是允许Cloudera Manager更仔细地管理各自配置的生命周期；二是指明以Cloudera Manager上的配置为冲突时的判定基准。这使得Cloudera Manager在重启时重写/etc下改变的配置变得不明显。

通常情况下，用户有“edge”、“client”或“gateway”机器，它们不运行hadoop daemon但与cluster在同一个网络中。用户使用它们作为执行任务、访问文件系统等事件的出发点（入口）。

通常情况下，agent由init.d启动。它和server通信以确定运行哪些process。agent被Cloudera Manager的host monitoring监控，如果agent停止发送心跳，对应host会被标记为bad health。

## **Meanwhile, on the Server…**

Server维护着整个cluster的状态。可以粗略的将状态分为“model”状态、“runtime”状态，两者都存于Cloudera Manager的server数据库中。

![phil3](Cloudera%20Manager.assets/phil3.png)

*Model State* 指明哪种任务在哪里运行以及如何配置。比如有17个host，哪个host运行DataNode由model state决定。

*Runtime State* 指明哪个process在哪里运行，当前运行哪些命令。runtime state包含很对细节，如待运行process的具体配置文件信息。实际上，在Cloudera Manager上点击“Start”命令，server将会收集所有相关service、role的配置。在验证完毕后将全部配置存入数据库中。

当配置更改时，必须更新model。若在运行时更新可能存在过期配置，此时需要重启role（会触发configuration re-generation及process restart）。

Many users ask us how backup should be done. A simple approach is to use the Cloudera Manager API to grab [/api/cm/deployment API endpoint](http://cloudera.github.io/cm_api/apidocs/v4/path__cm_deployment.html); this captures all the model information but not the runtime  information. A second approach is to back up the entire Cloudera Manager server database (which is typically quite small). There is almost  nothing to back up on a per-host basis, since the agent’s configuration  is typically simply the hostname of the server.

While we try to model all of the reasonable configurations, we found  that, inevitably, there are some dark corners that require special  handling. To allow our users to workaround, for example, some bug (or,  perhaps, to explore unsupported options), we have a “safety valve” which lets users plug in directly to the configuration files. (The analogy,  I’ll admit, is oriented toward the developers of Cloudera Manager: We’re “releasing pressure” if the model doesn’t hold up to some real-world  oddity.)

## Monitoring and Other Management Services

Cloudera Manager itself manages some of its helper services. These  include the Activity Monitor, the Service Monitor, the Host Monitor, the Event Server, the Reports Manager, and the Alert Publisher. Cloudera  Manager manages each separately (as opposed to rolling them all in as  part of the Cloudera Manager Server) for scalability (e.g., on large  deployments it’s useful to put the monitors on their own hosts) and  isolation.

For this behind-the-scenes blog post, we’ll only look at service monitoring in detail.

**Metric Collection**

To do its monitoring, Cloudera Manager collects metrics. Metrics are  simply numeric values, associated with a name (e.g., “cpu seconds”), an  entity they apply to (“host17”), and a timestamp. Most of this metric  collection is done by the agent. The agent talks to a supervised  process, grabs the metrics, and forwards them to the service monitor.  In most cases, this is done once per minute.

A few special metrics are collected by the Service Monitor  itself. For example, the Service Monitor hosts an HDFS canary, which  tries to write, read, and delete a file from HDFS at regular intervals,  and measures not just whether it succeeded, but how long it took. Once  metrics are received, they’re aggregated and stored.

Using the Charts page in Cloudera Manager, users can query and  explore the metrics being collected. Some metrics (e.g.,  “total_cpu_seconds”) are counters, and the appropriate way to query them is to take their rate over time, which is why a lot of metrics queries  look like “dt0(total_cpu_seconds)”. (The “dt0” syntax is intended to  remind you of derivatives. The “0” indicates that since we’re looking at the rate of a monotonically increasing counter, we should never have  negative rates.)

**Health Checks**

The service monitor continually evaluates “health checks” for every  entity in the system. A simple one asks whether there’s enough disk  space in every NameNode data directory. A more complicated health check  may evaluate when the last checkpoint for HDFS was compared to a  threshold or whether a DataNode is connected to a NameNode. Some of  these health checks also aggregate other health checks: in a distributed system like HDFS, it’s normal to have a few DataNodes down (assuming  you’ve got dozens of machines), so we allow for setting thresholds on  what percentage of nodes should color the entire service down. Cloudera  Manager encapsulates our experience with supporting clusters across our  customers by distilling them into these “health checks.”

When health checks go red, events are created, and alerts are fired off via e-mail or SNMP.

One common question is whether monitoring can be separated from  configuration. The answer is: No. One of our goals for monitoring is to  enable it for our users without needing to do additional configuration  and installing additional tools (e.g., Nagios). By having a deep model  of the configuration, we’re able to know which directories to monitor,  which ports to talk to, and which credentials to use for those  ports. This tight coupling means that, when you install Cloudera  Standard (the free version of the Cloudera platform), all the monitoring is immediately available.

# Parcel

## [Parcels: What and Why?](https://github.com/cloudera/cm_ext/wiki/Parcels%3A-What-and-Why%3F)

### What are Parcels

### What are the benifits of Parcels



## [Why you should use Parcels](https://github.com/cloudera/cm_ext/wiki/Why-you-should-use-parcels)

### Distributed a set of bits to many machines is boring but non trivial

### Parcels work well with CSDs



## [The Parcel Format](https://github.com/cloudera/cm_ext/wiki/The-parcel-format)

### a parcel is a tarball

### how a parcel interacts with the rest of the system

### The metadata

- [parcel.json]
- [Enviroment script]
- [alternatives.json]
- [permissions.json]
- [release-notes.txt]

### Compression

### Cloudera Manager Assumptions



## [Building a Parcel](https://github.com/cloudera/cm_ext/wiki/Building-a-parcel)

parcel包只需把文件与元数据放一起打包即可，无需编译等。





## [The Parcel Repository Format](https://github.com/cloudera/cm_ext/wiki/The-parcel-repository-format)





# CSD: Managing and monitoring services

CSD全称custom service descriptor。CSD文件命名规则：<name>-<csdversion>-<extra>.jar。

## [Overview](https://github.com/cloudera/cm_ext/wiki/CSD-Overview)

### Custom Service Descriptors

Cloudera Manager自4.5引入parcel包-一种向管理集群分发软件的机制。Parcel包只负责软件在集群中的分发，不对运行服务进程进行管理。在Cloudera Manager 5中引入了通过CSD管理服务的功能。三方服务可以通过CSD利用Cloudera Manager的特性，比如监控、资源管理、配置、分发、生命周期管理等等。提供的三方服务在Cloudera Manager中如HDFS、HBase一样。

#### Guiding Principles

- 可使用文档和开发工具编写，非代码人员可编写
- service descriptor language (SDL) 及 service monitoring language (MDL) 应为声明式语言，无需编程语言参与
- 在Cloudera Manager中，一个被CSD包装的服务应视作第一方应用，如HDFS
- CSD提供基础的功能，如进程级别的监控
- CSD可与parcel包兼容，也可不与其并用
- 如果你有自己封装的方式，你也可以使用CSD进行配置及进程生命周期的管理

### What exactly is a CSD?

CSD与Cloudera Manager中的一类服务关联，通常CSD是被打包并分发至集群的jar包。该jar包中包含CM管理该服务所需的所有配置及逻辑。Spark CSD布局如下：

```bash
$ jar -tf SPARK-1.0.jar 
descriptor/service.sdl
scripts/control.sh
images/icon.png
```

*More examples including the Spark CSD are available in our [git repo](https://github.com/cloudera/cm_csds).*

`descriptor/service.sdl` 是一个生命了在Cloudera Manager中服务类型的json文件. CSD的 `scripts/` 目录包含了控制服务启动的脚本文件. See [The Structure of a CSD](https://github.com/cloudera/cm_ext/wiki/The-Structure-of-a-CSD) for more details.

### CSDs vs. Parcels

CSD与parcel包都是Cloudera Manager提供的扩展工具，只是两者负责的领域不同。Parcel包致力于在集群中分发软件。Parcel包本质上是添加了元数据的tar包文件，在集群中分发时Cloudera Manager Agent仅将在host上解压，没有管理服务的功能。比如Hadoop的LZO插件，只需要修改HADOOP_CLASSPATH。

CSD补充parcel包遗漏的功能。当服务文件在集群上分发完成后，Cloudera Manager使用CSD去管理已部署的软件，管理他们的启/停、配置、资源管理等等。

一个汇总的方案是使用parcel包在Cloudera Manager上分发软件，并使用CSD进行管理。当你需要以特定的方式部署软件到集群，可以不使用parcel的方式分发软件，单独使用CSD管理软件。



## [CSD Primer](https://github.com/cloudera/cm_ext/wiki/CSD-Primer)

编写一个CSD是一个相对简单的过程。本节将会演示发布一个`ECHO`的小型CSD。`ECHO`服务只有一个角色类型，一个启动并监控指定端口的python webserver。

### Creating the Echo CSD

先创建一个名为ECHO-1.0的文件夹:

```bash
mkdir ECHO-1.0
```

#### The Service Descriptor

添加 `ECHO-1.0/descriptor/service.sdl`文件：

```json
{
  "name" : "ECHO",
  "label" : "Echo",
  "description" : "The echo service",
  "version" : "1.0",
  "runAs" : { 
    "user" : "root",
    "group" : "root"
   },  
   "roles" : [
    {
       "name" : "ECHO_WEBSERVER",
       "label" : "Web Server",
       "pluralLabel" : "Web Servers",
       "parameters" : [
        {
          "name" : "port_num",
          "label" : "Webserver port",
          "description" : "The web server port number",
          "required" : "true",
          "type" : "port",
          "default" : 8080
        }
      ],
      "startRunner" : {
         "program" : "scripts/control.sh",
         "args" : [ "start" ],
         "environmentVariables" : {
           "WEBSERVER_PORT" : "${port_num}"         
         }
      }
    }
  ]
}
```

#### The Control Script

添加 `ECHO-1.0/scripts/control.sh`文件：

```bash
#!/bin/bash
CMD=$1

case $CMD in
  (start)
    echo "Starting the web server on port [$WEBSERVER_PORT]"
    exec python -m SimpleHTTPServer $WEBSERVER_PORT
    ;;
  (*)
    echo "Don't understand [$CMD]"
    ;;
esac
```

#### Validation

`service.sdl` 文件可以使用提供的validator进行验证。 运行以下命令进行验证：

```bash
java -jar validator.jar -s ECHO-1.0/descriptor/service.sdl
```

#### Building

CSD被打包进jar包文件中。在CSD目录下运行以下命令：

```bash
cd ECHO-1.0
jar -cvf ECHO-1.0.jar *
```

#### Testing ECHO CSD in Cloudera Manager

接下来在Cloudera Manager中安装CSD `ECHO-1.0.jar` ：

1. 将 `ECHO-1.0.jar` 拷贝到CSD目录。默认配置的路径为 `/opt/cloudera/csd`。

  ```bash
  scp ECHO-1.0.jar myhost.com:/opt/cloudera/csd/.`
  ```

2. 重启Cloudera Manager

  ```bash
  service cloudera-scm-server restart`
  ```

3. 重启所有管理的服务

More detailed instructions can be found [here](http://cloudera.com/content/cloudera-content/cloudera-docs/CM5/latest/Cloudera-Manager-Managing-Clusters/cm5mc_addon_services.html).

当Cloudera Manager及其管理的服务重启完成，使用引导程序`Add Service`去添加Echo服务。Detailed instructions can be found [here](http://cloudera.com/content/cloudera-content/cloudera-docs/CM5/latest/Cloudera-Manager-Managing-Clusters/cm5mc_add_service.html). 在服务启动后，可在浏览器访问`http://<yourhost>:8080/`看到agent进程目录中的所有文件。

### A Closer Look into the ECHO CSD

Lets take a closer look at what exactly is going on with this simple CSD.

#### The Service Descriptor

 `service.sdl` 文件是Cloudera Manager进入CSD的入口。该文件描述了服务及配置关联的角色、命令等。ECHO使用了最基础的 `service.sdl`。更完整的SDL手册参考Service Descriptor Language Reference。

```json
{
  "name" : "ECHO",
  "label" : "Echo",
  "description" : "The echo service",
}
```

`name` 是此CSD暴露的服务类型，必须大写，仅含字母、数字、下划线。这需要和jar包文件名称匹配。 `label`是展示在Cloudera Manager UI界面的字符串。

```json
{
  "version" : "1.0",
}
```

sdl文件中的`version`与Cloudera Manager中管理的软件的实际版本无关，仅是CSD的版本标识。sdl中的`version`是CSD的第二个命名标志。

```json
{
  "runAs" : { 
    "user" : "root",
    "group" : "root"
   }
}
```

这是默认的运行启动脚本及其他`service.sdl`中声明命令的user/group。CM管理员可在CSD服务添加后添加用户。

```json
{
 "roles" : [
  {
    "name" : "ECHO_WEBSERVER",
    "label" : "Web Server",
    "pluralLabel" : "Web Servers",
  }
 ]
}
```

定义和当前服务关联的角色类型。在本示例中，我们只使用`ECHO_WEBSERVER`一个角色类型。需要注意的是角色类型需要全局唯一。因为服务类型`name`需要预先知道角色类型`roles[i].name`以定位服务。如服务类型一样，角色类型仅包含大写字母、数字、下划线。`label` 及`pluralLabel` 是Cloudera Manager展示给用户看的字符串。

```json
{
 "parameters" : [
  {
   "name" : "port_num",
   "label" : "Webserver port",
   "description" : "The web server port number",
   "required" : "true",
   "type" : "port",
   "default" : 8080
  }
 ]
}
```

Parameters用于描述实际服务需要的配置。Parameters可存在与服务级别，也可通过角色类型`roles[i].name`继承获得。一个parameter的`name`应在不同版本的CSD中保持不变。一般parameter名称使用小写，下划线分割。

Parameters也有type。本例中type为"port"，默认为8080。该参数可统一配置，也可每个实例单独配置。

```json
{
 "startRunner" : {
   "program" : "scripts/control.sh",
   "args" : [ "start" ],
   "environmentVariables" : {
     "WEBSERVER_PORT" : "${port_num}"         
   }
 }
}
```

 `startRunner` 告知Cloudera Manager如何启动角色 `ECHO_WEBSERVER` 。 `program` 指向执行对应CSD的脚本文件。处脚本路径外，可通过`args`及`environmentVariables`向脚本传递入参及设置环境变量。参数及环境变量即可硬编码，也可通过`${p}`获取。 如果用户没有修改默认`port_num`，启动角色 `ECHO_WEBSERVER` 时agent实际运行命令如下：

```bash
WEBSERVER_PORT=8080 scripts/control.sh start
```

#### The Control Script

控制脚本可以使用集群支持的任何语言编写。ECHO中我们使用bash，其中`control.sh`用于在指定`port_num`上启动python webserver。端口号以环境变量的方式传入。

```bash
#!/bin/bash
CMD=$1
```

命令的名称通过首个参数传入。这是有不同启动方式的常用方法。

```bash
case $CMD in
  (start)
    echo "Starting the web server on port [$WEBSERVER_PORT]"
    exec python -m SimpleHTTPServer $WEBSERVER_PORT
    ;;
  (*)
    echo "Don't understand [$CMD]"
    ;;
esac
```

如果输入命令为`start`，我们在指定端口运行python webServer。 注意`$WEBSERVER_PORT` 与 `service.sdl`中声明的`WEBSERVER_PORT`一致。

启动python server的命令如下：

```bash
exec python -m SimpleHTTPServer $WEBSERVER_PORT
```

脚本文件必须通过`exec`原语来执行可执行文件。以确保supervisord监控的进程树为执行的服务而不是`control.sh`脚本。

### Operational Diagnostics

如[Cloudera Manager concepts](http://blog.cloudera.com/blog/2013/07/how-does-cloudera-manager-work/)中介绍的一样，agent为每个role commond在 `/var/run/cloudera-scm-agent/process`目录下维护一个单独的文件件。  `ECHO_WEBSERVER` roles的一个示例可能如下：

```bash
$ tree -a /var/run/cloudera-scm-agent/process/121-echo-ECHO_WEBSERVER/
/var/run/cloudera-scm-agent/process/121-echo-ECHO_WEBSERVER/
├── cloudera-monitor.properties
├── logs
│   ├── stderr.log
│   └── stdout.log
└── scripts
    └── control.sh
```

我们可以看到`scripts/*`下的内容都被拷贝到agent上。这也是agent启动python webserver的方法。



## [Administration](https://github.com/cloudera/cm_ext/wiki/Administration-of-CSDs)

Cloudera Manager并不完全支持动态安装CSD。因此安装CSD需要重启Cloudera Manager。

### Installing

1. 将CSD文件拷贝至本地库，默认为： `/opt/cloudera/csd`
2. 重启Cloudera Manager
3. 重启所有Cloudera Manager管理的服务

### Uninstalling

1. 确保需移除CSD所有的服务角色提供的服务被停止且移除
2. 从本地库中移除CSD文件
3. 重庆Cloudera Manager
4. 重启所有Cloudera Manager管理的服务

### Missing CSDs

如果基于CSD的服务已被添加但CSD之后被移除，Cloudera Manager会提示警告信息且只提供该服务少部分功能。用户只能停止服务并将其移除。此时，该服务类型在向导程序中已不可用。其他可能导致此类问题的原因：

- CSD存在验证错误且不能被加载
- 添加了不兼容的CSD，[generation change](https://github.com/cloudera/cm_ext/wiki/Service-Descriptor-Language-Reference#generations)



## [The Structure of a CSD](https://github.com/cloudera/cm_ext/wiki/The-Structure-of-a-CSD)

CSD框架特别关注的文件：

- descriptor/service.sdl
- descriptor/service.mdl
- scripts/
- aux/

### descriptor/service.sdl

CSD的核心是sdl（service descriptor language）。service.sdl是一个json文件，描述如何管理CSD中描述的服务。文件内容包括：

- 服务类型及关联的角色类型
- 如何启动服务/角色
- 服务类型及角色类型的参数
- 附加的命令
- 配置文件生成器

service.sdl必须放置于descriptor目录下。

### descriptor/service.mdl

服务监控行为在mdl（monitoring descriptor language）文件中描述。service.mdl描述Cloudera Manager应如何监控CSD中的服务，其中内容有：

- 新定义的被监控实体类型
- 新定义的对服务、角色及监控实体类型的指标度量

service.mdl是一个可选项，但必须放置于descriptor目录下。

### scripts

用于控制服务的所有可执行文件均放置在scripts/目录下。目录下的文件在service.sdl中的script runners中指定。脚本文件可以使用集群支持的任意语言编写。

### aux

aux目录是CSD的可选项，随scripts目录一同下发。一些静态的配置文件可以放置aux目录下，如服务需要但CSD不产生的topology.py。经常改变的配置可放置于静态配置文件中，通过控制脚本文件指定改变。



## [Control Scripts](https://github.com/cloudera/cm_ext/wiki/Control-Scripts)

控制脚本文件提供了CSD与服务二进制文件见的关联，无论是否使用parcel方式发布。控制脚本需要放置于scripts/目录下。Cloudera在以下情况会运行脚本文件：

- 启动一个角色进程（role process）。See [Start Runner](https://github.com/cloudera/cm_ext/wiki/Service-Descriptor-Language-Reference#-startrunner).
- 启动一个角色命令（role command）。See [Commands](https://github.com/cloudera/cm_ext/wiki/Service-Descriptor-Language-Reference#-commands-1).
- 部署客户端配置（client configuration）。 See [Client Configuration](https://github.com/cloudera/cm_ext/wiki/Service-Descriptor-Language-Reference#scriptrunner).



### Executing a control script

在Cloudera Manager验证一个命令时，配置文件数据会随着心跳数据被发送至agent。agent在/var/run/cloudera-scm-agent/process/目录下放置收到的配置文件。

配置文件中包含的数据有：

- scripts/目录下全部文件，See [scripts](https://github.com/cloudera/cm_ext/wiki/The-Structure-of-a-CSD#scripts).
- aux/目录下全部文件，See [aux](https://github.com/cloudera/cm_ext/wiki/The-Structure-of-a-CSD#aux).
- [Config Writers](https://github.com/cloudera/cm_ext/wiki/Service-Descriptor-Language-Reference#wiki-config-writer)产生的全部文件

此时agent会运行脚本文件并将stderr及stdout分别放置于logs/stderr.log及logs/stdout.log文件中。

需要注意的是控制脚背中最后一行被exec执行的进程并不守护运行。这是因为agent使用[supervisord](http://supervisord.org/)去监控进程，并且服务的二进制文件需要被放置于supervisord的进程树下。此进程不可作为守护进程在背后运行。进程需要前台执行使supervisord可监控。

#### An Example: Echo Webserver

The ECHO_WEBSERVER `startRunner`（service.sdl文件中指定）:

```json
{
  "startRunner" : {
    "program" : "scripts/control.sh",
    "args" : [ "start" ],
    "environmentVariables" : {
      "WEBSERVER_PORT" : "9797"
    }
  }
}
```

The control script（scripts/目录下）:

```bash
​```bash
CMD=$1
case $CMD in
  (start)
    echo "Starting Server on port $WEBSERVER_PORT"
    exec python -m SimpleHTTPServer $WEBSERVER_PORT
    ;;    
  (*)
    log "Don't understand [$CMD]"
    ;;
esac
```

当agent上启动指定role时，会创建目录/var/run/cloudera-scm-agent/process/121-echo-ECHO_WEBSERVER/，121是CM的进程id。之后agent会执行：

```bash
WEBSERVER_PORT=9797 scripts/control.sh start
```

### Special Environment Variables

除了script runner提供的环境变量外，Cloudera Manager也提供一些特殊变量。

| Variable          | Description                                                  | Example                                                      |
| ----------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| CONF_DIR          | 当agent进程目录                                              | /var/run/cloudera-scm-agent/process/121-echo-ECHO_WEBSERVER/ |
| JAVA_HOME         | java binaries路径                                            | /usr/java/jdk1.7.0_25-cloudera                               |
| CDH_VERSION       | The version of CDH used in the cluster.                      | 5                                                            |
| COMMON_SCRIPT     | 在命令执行或启动进程时重要的脚本函数                         | /usr/lib64/cmf/service/common/cloudera-config.sh             |
| ZK_PRINCIPAL_NAME | Kerberos在ZooKeeper上的主要名称。只在非默认名称在ZooKeeper上配置时使用 | zk_custom_principal                                          |

### Interaction with Parcels

对大多数服务而言，parcel通常与CSD并存。parcel包包含服务文件。控制脚本需要知道启动服务或运行命令相关的parcel文件被放置于何处。CSD和parcel包在[provides tags](https://github.com/cloudera/cm_ext/wiki/The parcel.json file#providing-tags)中关联。CSD的parcel结构声明了其需要哪些标签。parcel包声明他们提供哪些标签。

当agent执行一个控制脚本时，它会首先检查其需要哪些标签。接着定位所需标签的parcel文件。在配置脚本已被定位后，控制脚本开始执行。parcel中定义的环境变量可被控制脚本用于定位服务文件。

注意：至少有一个parcel文件提供CSD所需的标签，否则命令会失败。

#### Example: Spark

Lets take the Spark service as an example. Only the relevant sections of the files are shown for simplicity.



##### Spark Parcel

The `meta/parcel.json`:

```json
{
  "scripts": {
    "defines": "spark_env.sh"
  },
  "provides" : {
    "spark"
  }
}
```

The `meta/spark_env.sh`:

```bash
SPARK_DIRNAME=${PARCEL_DIRNAME:-"SPARK-0.9.0-1.cdh4.6.0.p0.47"}
export CDH_SPARK_HOME=$PARCELS_ROOT/$SPARK_DIRNAME/lib/spark
```

##### Spark CSD

The spark `descriptor/service.sdl`:

```json
{
 "parcel" : {
    "requiredTags" : [ "spark" ],
    "optionalTags" : [ "spark-plugin" ]
 }
}
```

The Spark `scripts/control.sh`:

```bash
DEFAULT_SPARK_HOME=/usr/lib/spark
export SPARK_HOME=${SPARK_HOME:-$CDH_SPARK_HOME}
export SPARK_HOME=${SPARK_HOME:-$DEFAULT_SPARK_HOME}
...
exec "$SPARK_HOME/bin/spark-class ${ARGS[@]}"
...
```

agent运行该控制脚本后执行了以下操作:

1. agent从spark CSD中读取parcel标签.

- "spark" is a required tag.
- "spark-plugin" is an optional tag.

1. agent扫描所有actived状态的parcel文件，找到Spark parcek提供所需的“spark”标签。
2. 没有其他parcel文件提供 "spark" 或"spark-plugin"标签。
3. agent定位脚本文件 `meta/spark_env.sh`。

- This sets `CDH_SPARK_HOME=/opt/cloudera/parcels/SPARK-0.9.0-1.cdh4.6.0.p0.47/lib/spark`.

1. The agent executes `scripts/control.sh`.
2. The control script checks to see if `CDH_SPARK_HOME` is set. If so it sets `SPARK_HOME` to it.

- The `CDH_SPARK_HOME` might not be set if we are using the spark packages instead of parcels. In that case `SPARK_HOME` is set to the default package location of `/usr/lib/spark`.

1. The control script then uses `SPARK_HOME` to exec the spark-class binary.

### Getting kerberos tickets

在使用kerberos进行安全验证的集群上，在与有安全措施的服务器交互前必须先获取kerberos ticket。若role在描述中声明了kerberos，对应的kerberos信息将被添加至该role的keytab文件，同时也加入配置目录中。并且，每个kerberos principal被添加到该role的环境中。使用这些principal需在脚本文件中`source $COMMON_SCRIT`，并调用`acquire_kerberos_tgt myservice.keytab`。

```bash
# Source the common script to use acquire_kerberos_tgt
. $COMMON_SCRIPT

# acquire_kerberos_tgt expects that the principal to be kinited is referred to by 
# SCM_KERBEROS_PRINCIPAL environment variable
export SCM_KERBEROS_PRINCIPAL=$MY_KERBEROS_PRINCIPAL

# acquire_kerberos_tgt expects that the argument passed to it refers to the keytab file
acquire_kerberos_tgt myservice.keytab
```



## [Service Descriptor Language Reference](https://github.com/cloudera/cm_ext/wiki/Service-Descriptor-Language-Reference)
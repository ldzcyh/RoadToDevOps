
# zookeeper集群配置操作
## 1、配置节点标识
以三节点集群为例，在各服务器上zookeeper目录依次执行以下命令：  
- [ zk-1 执行 ]
```shell
echo "1" > data/myid
```

- [ zk-2 执行 ]
```shell
echo "2" > data/myid
```
- [ zk-3 执行 ]
```shell
echo "3" > data/myid
```


## 2、在各服务器zookeeper目录均执行以下命令
```shell
#!/bin/bash
# 下面的ip改成实际的ip
ip[0]=192.168.1.1
ip[1]=192.168.1.2
ip[2]=192.168.1.3

id=1
for i in ${ip[@]};do
echo "server.${id}=${i}:2888:3888" >> conf/zoo.cfg
let id++
done
```
### 注意事项
上述命令生成类似下面的配置
```shell
server.1=192.168.1.1:2888:3888
server.2=192.168.1.2:2888:3888
server.3=192.168.1.3:2888:3888
```
- 如果zk集群是部署在同一台服务器的伪集群，那么ip需要一样，后面的端口需要换成6个不同的端口。
- 手动填写配置的话，注意每行后面不要有空格，否则会报错


## 3、依次启动 zk-1、zk-2、zk-3
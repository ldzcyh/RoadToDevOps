#!/bin/bash

# 指定版本，生成配置需要，不能省略
version=4.2
# 指定特定小版本时需要，不需要指定时不用管
version_mini=
user=root
passwd=654321
port=27017
# 数据存储目录，默认/var/lib/mongo
dbpath=/data/mongodb

releasever=$(awk -F '"' '/VERSION_ID/{print $2}' /etc/os-release)



echo -e "\033[32m[+] 生成mongodb repo文件\033[0m"
cat > /etc/yum.repos.d/mongodb-org-${version}.repo << EOF
[mongodb-org-${version}]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/${version}/x86_64/
enabled=1
gpgcheck=0
gpgkey=https://www.mongodb.org/static/pgp/server-${version}.asc
EOF

echo -e "\033[32m[>] yum安装mongodb\033[0m"
if [ ! ${version_mini} ];then
    yum install -y mongodb-org
else
# 指定小版本
    yum install -y mongodb-org-${version_mini}
fi

if [ $? -ne 0 ];then
    echo -e "\033[31m[*] mongodb安装出错，请检查！\033[0m"
    exit 1
fi

systemctl start mongod
if [ $? -ne 0 ];then
    echo -e "\033[31m[*] mongodb启动出错，请检查！\033[0m"
    exit 2
fi
systemctl enable mongod

echo -e "\033[32m[>] 设置mongodb用户\033[0m"
mongo admin --eval "db.createUser({user:\"${user}\", pwd:\"${passwd}\", roles:[{role:\"root\", db:\"admin\"}]})" &> /dev/null

echo -e "\033[32m[>] 优化mongodb配置\033[0m"
sed -i '/bindIp: 127.0.0.1/a  #  maxIncomingConnections: 65536  #进程允许的最大连接数 默认值为65536' /etc/mongod.conf 
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/g' /etc/mongod.conf
cat > /tmp/mongo_temp_$(date +%F).sh << EOF
sed -i 's/port: 27017/port: ${port}/g' /etc/mongod.conf
# sed -i 's#dbPath: /var/lib/mongo#dbPath: ${dbpath}#g' /etc/mongod.conf
EOF
/bin/bash /tmp/mongo_temp_$(date +%F).sh
rm -rf /tmp/mongo_temp_$(date +%F).sh

echo -e "\033[32m[>] 开启安全认证\033[0m"
sed -i '/#security:/a security:\n  authorization: enabled' /etc/mongod.conf

echo -e "\033[32m[>] 检查mongodb数据存储目录\033[0m"
[ -d $dbpath ] || mkdir -p $dbpath
chown -R mongod:mongod $dbpath

systemctl restart mongod
if [ $? -ne 0 ];then
    echo -e "\033[31m[*] mongodb重启出错，请检查mongod.conf！\033[0m"
    exit 3
fi

echo -e "\033[36m[#] mongodb-${version} 已安装配置完成：\033[0m"
echo -e "\033[36m    mongodb端口：${port}\033[0m"
echo -e "\033[36m    超管账号：${user}\033[0m"
echo -e "\033[36m    超管密码：${passwd}\033[0m"


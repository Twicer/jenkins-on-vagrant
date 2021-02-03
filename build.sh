mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup`date '+%Y%m%d_%H%M%S'` 
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum clean all
yum makecache
yum update

yum install -y java-1.8.0-openjdk-devel.x86_64
mkdir -p /usr/local/src/jenkins
cp /home/vagrant/resources/jenkins-2.263.2LTS.war /usr/local/src/jenkins/jenkins-stable.war
ln -s /usr/local/src/jenkins/jenkins-stable.war /usr/local/src/jenkins/jenkins.war

function presetPassword(){
mkdir -p /usr/local/src/jenkins/home/secrets
tee /usr/local/src/jenkins/home/secrets/initialAdminPassword << _EOF
111111
_EOF
sed -i -e 's/<passwordHash>.*<\/passwordHash>/<passwordHash>#jbcrypt:$2a$10$DdaWzN64JgUtLdvxWIflcuQu2fgrrMSAMabF5TSrGK5nXitqK9ZMS<\/passwordHash>/g' /usr/local/src/jenkins/home/users/admin_*/config.xml
}

function updateUpdateCenter(){
tee /usr/local/src/jenkins/home/hudson.model.UpdateCenter.xml << _EOF
<?xml version='1.1' encoding='UTF-8'?>
<sites>
  <site>
    <id>default</id>
<!--<url>https://updates.jenkins.io/update-center.json</url>-->
    <url>http://mirror.xmission.com/jenkins/updates/update-center.json</url>
  </site>
</sites>
_EOF
}

tee /usr/local/src/jenkins/stopJenkins.sh << _EOF
export JENKINS_HOME=/usr/local/src/jenkins/home
user=\$(whoami)
ps -ef|grep -i jenkins.war|grep \$user
ps -ef|grep -i jenkins.war|grep \$user|grep -v grep|awk -F" " '{print \$2}' |xargs kill -9
echo "Jenkins stopped"
_EOF
tee /usr/local/src/jenkins/startJenkins.sh << _EOF
export JENKINS_HOME=/usr/local/src/jenkins/home
cd /usr/local/src/jenkins/
./stopJenkins.sh
nohup java -jar ./jenkins.war > jenkins.log & 
echo "Jenkins started"
_EOF
chmod 744 /usr/local/src/jenkins/*.sh
/usr/local/src/jenkins/startJenkins.sh
sleep 10
presetPassword
updateUpdateCenter

/usr/local/src/jenkins/startJenkins.sh

echo "finish jenkins server build "

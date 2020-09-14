sudo apt-get install openjdk-8-jdk -y

# SBT
echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
sudo apt-get update
sudo apt-get install sbt -y

# Maven
cat <<EOF > ~/.sbt/repositories
[repositories]
local
aliyun-nexus: https://maven.aliyun.com/nexus/content/groups/public/
typesafe: https://repo.typesafe.com/typesafe/ivy-releases/, [organization]/[module]/(scala_[scalaVersion]/)(sbt_[sbtVersion]/)[revision]/[type]s/[artifact](-[classifier]).[ext], bootOnly
sonatype-oss-releases
maven-central
sonatype-oss-snapshots
EOF

dpkg -L sbt
# Enable repo
echo "-Dsbt.override.build.repos=true" | sudo tee -a /usr/share/sbt/conf/sbtconfig.txt
echo "-Dsbt.override.build.repos=true" | sudo tee -a /usr/share/sbt/conf/sbtopts

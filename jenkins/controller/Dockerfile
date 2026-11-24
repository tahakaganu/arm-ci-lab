FROM jenkins/jenkins:lts-jdk21
ENV CASC_JENKINS_CONFIG=/usr/share/jenkins/ref/casc
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
COPY casc/ /usr/share/jenkins/ref/casc/
# Runtime-only JVM settings: set last so build steps don't inherit them
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Xms1g -Xmx1g -XX:+UseG1GC -Xlog:gc*:file=/var/jenkins_home/gc.log:time,uptime:filecount=5,filesize=20M"

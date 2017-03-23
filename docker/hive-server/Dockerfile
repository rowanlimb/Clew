FROM prasanthj/docker-hadoop:2.6.0

LABEL maintainer "Rowan Limb <rowan.limb@bt.com>"
LABEL description "A minimal Hadoop and Hive instance"

ARG USERID

ENV HIVE_VERSION 1.2.1

ENV HIVE_HOME /opt/hive
ENV PATH $HIVE_HOME/bin:$PATH
ENV HADOOP_PREFIX /usr/local/hadoop

ENV USER docker

WORKDIR /opt

#Install Hive
RUN wget http://www-eu.apache.org/dist/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz && \
	tar -xzvf apache-hive-$HIVE_VERSION-bin.tar.gz && \
	mv apache-hive-$HIVE_VERSION-bin hive && \
	rm apache-hive-$HIVE_VERSION-bin.tar.gz && \
        apt-get -y install supervisor && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/supervisor
COPY conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN adduser --disabled-password --gecos "" $USER && groupadd supergroup && usermod -a -G supergroup $USER && if [ $(id -u $USER) -ne $USERID ] ; then usermod -u $USERID $USER;fi

COPY docker_user_bashrc /home/$USER/.bashrc
RUN chown $USER:$USER /home/$USER/.bashrc

#Custom configuration goes here
COPY conf/hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
COPY conf/hive-site.xml $HIVE_HOME/conf
COPY conf/beeline-log4j2.properties $HIVE_HOME/conf
COPY conf/hive-env.sh $HIVE_HOME/conf
COPY conf/hive-exec-log4j2.properties $HIVE_HOME/conf
COPY conf/hive-log4j2.properties $HIVE_HOME/conf
COPY conf/ivysettings.xml $HIVE_HOME/conf
COPY conf/llap-daemon-log4j2.properties $HIVE_HOME/conf

#updated yarn config with aggregation for historyserver enabled
COPY conf/yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

#Create additional HDFS dirs
RUN /usr/sbin/sshd && $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && $HADOOP_PREFIX/sbin/start-dfs.sh && $HADOOP_PREFIX/bin/hdfs dfs -mkdir -p /tmp && $HADOOP_PREFIX/bin/hdfs dfs -mkdir -p /user/hive/warehouse && $HADOOP_PREFIX/bin/hdfs dfs -chmod -R g+w / && $HADOOP_PREFIX/bin/hdfs dfs -mkdir /user/$USER && $HADOOP_PREFIX/bin/hdfs dfs -chown $USER /user/$USER

#Add supervisord to parent's bootstrap.sh
RUN sed -i '/timelineserver/a\\nsupervisord -n' /etc/bootstrap.sh

EXPOSE 10000
EXPOSE 10002
EXPOSE 22
EXPOSE 19888


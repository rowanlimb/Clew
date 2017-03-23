FROM sameersbn/ubuntu:14.04.20170110

LABEL maintainer "Rowan Limb <rowan.limb@bt.com>"
LABEL description="A gateway for cluster monitoring which hosts MySql and Shiny Server"

ARG USERID

ENV MYSQL_USER=mysql \
    MYSQL_DATA_DIR=/var/lib/mysql \
    MYSQL_RUN_DIR=/run/mysqld \
    MYSQL_LOG_DIR=/var/log/mysql \
    USER=monitor

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server \
 && rm -rf ${MYSQL_DATA_DIR} \
 && rm -rf /var/lib/apt/lists/*

#Now install R and shiny server
#Based on 'shiny-server' image maintained by Winston Chang "winston@rstudio.com"

#Need this to add R repo
RUN apt-get update && apt-get install -y software-properties-common python-setuptools

# Add R apt repository
RUN add-apt-repository "deb http://cran.r-project.org/bin/linux/ubuntu $(lsb_release -cs)/"
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

# Install basic stuff and R
RUN apt-get update && apt-get install -y \
    sudo \
    git \
    vim-tiny \
    less \
    wget \
    r-base \
    r-base-dev \
    r-recommended \
    fonts-texgyre \
    openssh-client \
    libmariadbclient-dev

RUN echo 'options(\n\
  repos = c(CRAN = "https://cran.r-project.org/"),\n\
  download.file.method = "libcurl",\n\
  # Detect number of physical cores\n\
  Ncpus = parallel::detectCores(logical=FALSE)\n\
)' >> /etc/R/Rprofile.site

# =====================================================================
# Shiny Server dev stuff + Shiny
# =====================================================================

RUN apt-get update && apt-get install -y \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libxml2-dev \
    cmake

# Download and install shiny server
RUN wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb

RUN R -e "install.packages(c('shiny', 'devtools', 'rmarkdown', 'config', 'DT', 'ggplot2', 'lubridate', 'plotly', 'plyr', 'RMySQL', 'shinyBS', 'shinydashboard', 'tidyr', 'visNetwork'))" && \
   cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/

RUN chown -R shiny:shiny /var/lib/shiny-server/

#Create a user for monitor scripts
RUN adduser --disabled-password --gecos "" $USER \
    && if [ $(id -u $USER) -ne $USERID ] ; then usermod -u $USERID $USER;fi \
    && passwd monitor -d \
    && adduser monitor sudo \
    && mkdir /home/monitor/.ssh \
    && mkdir /home/monitor/utils

RUN easy_install supervisor

COPY ./conf/ssh.conf /home/monitor/.ssh/config
RUN chmod 600 /home/monitor/.ssh/*
COPY ./scripts/start.sh /start.sh
COPY ./scripts/createMySQLTable /home/monitor/utils
COPY ./scripts/runMySQLQuery /home/monitor/utils
COPY ./conf/supervisord.conf /etc/supervisord.conf
RUN chown -R monitor:monitor /home/monitor/.ssh /home/monitor/utils
RUN chmod 755 /start.sh
RUN mkdir /var/log/supervisor/

EXPOSE 3306 3838
CMD ["/bin/bash", "/start.sh"]

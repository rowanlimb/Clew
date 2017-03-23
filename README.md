# Clew

By [BT](http://www.btplc.com/).

R Shiny dashboard for Hadoop cluster.

**Clew** is a web based application implemented in R Shiny. It displays various performance indicators using REST APIs and custom shell scripts. The aim is to give cluster administrators an easy top-level view of the status of the cluster, highlighting potential 'hot spots' which may require investigation.

## Overview

The Shiny application calls [Yarn ResourceManager REST API](https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/ResourceManagerRest.html) to collect and display various statistics such as:

* Memory usage
* Process status
* Node status

The application also displays ['beeline'](https://cwiki.apache.org/confluence/display/Hive/HiveServer2+Clients#HiveServer2Clients-BeelineCommandLineShell) connection latency data which has been collected using custom scripts and stored in a MySQL database.

The basic architecture for the 'beeline' latency collection is as follows:

                                                         +---------+
                                                         |         |
                                                         |         |  [Script 2] calls:
             +---------+                     +---ssh---> |         |    [Script 3]
             |         |                     |           |         |
             |         | [Script 1]       <--+           +---------+
             |         | calls [Script 2] <--+            Cluster 1
             |         | over ssh [1]        |
             +----+----+                     |
             Monitor Node                    |           +---------+
                  |                          |           |         |
      (======)    |                          +---ssh---> |         |  [Script 2] calls:
      (      )    |                                      |         |    [Script 3]
      (      ) <--+                                      |         |
      (      )                                           +---------+
      (======)                                            Cluster 2
        MySQL

    Script 1: log_remote_beeline_latency.sh
    Script 2: log_beeline_latency.sh
    Script 3: query_beeline_latency.sh

See the diagram above. There are three Bash scripts, one which runs on the 'Monitor Node' and two which run on a server which hosts Hive for one or more clusters. It is assumed that the Monitor Node does not have direct access to the cluster node(s) so remote script invocation is done over ssh. The scripts on the cluster node(s) make a simple beeline query and record the access time which is then returned to the calling script on the Monitor Node, again over the same ssh connection. This calling script parses the returned data and connects to MySQL to update the table for each of the clusters.

The reason for having Script 2 call Script 3 on the cluster(s) is that Script 3 runs beeline to get the latency figure and writes to a log file. If this takes a very long time we do not want to hold up the whole process, so we have Script 2 which reads the logfile created by Script 3 for the data. It also checks to see if Script 3 is still running and will not call it again if this is the case.

#### Notes
[1] It is assumed that ssh will be set up to use public/private keys. If the cluster[s] use Kerberos then this can be configured within the scripts.

[2] Although 2 clusters are shown, this could be just one cluster, or more than two. The calling script (Script 1) is configured to call scripts on as many clusters as required and store the data in MySQL.

[3] The server labelled 'Monitor Node' is assumed to be a server running a Linux distribution and as well as the scripts as outlined above also hosts (or has access to) MySQL, R and Shiny Server. It is possible that some other database could be used in place of MySQL, see installation notes below.

## Requirements
 * R
 * Shiny
 * bash
 * ssh
 * MySQL
 * GNU Build System aka Autotools (autoconf, automake and make)
 * Docker (optional) - see Docker section below

## Installation

1. Bash and ssh<br/>
It is assumed you have, or know how to install a Linux server with this software installed. You will also need to set up public/private keys for ssh. The current version of the scripts do use bash features. Future versions may become more POSIX-generic.

2. R and Shiny<br/>
To obtain and install R and Shiny see [Shiny documentation](http://docs.rstudio.com/shiny-server/). Shiny recommends R version 3.0 or higher. Or use the appropriate package manager for your Linux distribution.

3. MySQL<br/>
To obtain and install MySQL see [MySQL documentation](https://dev.mysql.com/doc/) or use the appropriate package manager for your Linux distribution. There are no special dependencies on MySQL as such and other databases could easily be used instead with minor adjustments to the script which updates the database and the Shiny application which access the data.<br/>
Create MySQL user, database and tables. The database name is pre-set and cannot be changed. **You can use any names for the table(s). The script called by make (see below) will prompt for table names, one per cluster. Otherwise you will need to edit the Shiny configuration and Beeline scripts yourself**. The table creation statement will be something like:

    ```SQL
    Create table beeline_latency_1a (cluster varchar(20),  date varchar(25), latency float);
    Create table beeline_latency_1b (cluster varchar(20),  date varchar(25), latency float);
    ```
<br/>
Creating a table for each cluster (Hive instance) to be monitored.

4. GNU Build System<br/>
This may already be installed, look for autoconf, automake and make. Otherwise use your package manager to install, e.g.
  * Debian: apt-get install m4 automake autoconf
  * Centos/RedHat: yum group install "Development Tools"

5. Building<br/>
The build process starts at the top level and works through the sub folders for the dashboard and beeline-latency logging tool. As part of the build for the Dashboard, a config.yml file will be created by running a shell script which will ask you a number of configuration questions. Alternatively you can manually create the file dashboard/config.yml, using dashboard/config.yml.template as an example. If doing the latter, this must be done **before** running make.

For the Beeline latency logging, see the overview and diagram above. The code and build configuration files are in the sub-directory beeline-latency.

To run the build process:<br/>

Note, you can do this within a docker environment if you wish. This allows you to test/try it out without touching your existing cluster, or if you do not yet have a cluster to monitor. See Docker section for more information.

 * ./bootstrap.sh
 * ./configure [use optional --prefix=&lt;path&gt; to specify where local scripts will be installed, defaults to /usr/local/bin]
 * make
 * make install

bootstrap.sh sets up the GNU build tools autoconf and automake and creates the configure script based on configure.ac
configure checks the install requirements as described above and if all OK, creates Makefiles
make creates the scripts and required configuration files<br/>

make will also run a script which asks you to enter data for a series of configuration entries. These will be used to create a config.yml file for the Shiny app, and sets up the various scripts and configuration for beeline latency logging.<br/>

make install will place clusterconfig and log_remote_beeline_latency.sh in a bin folder beneath the path as specified with the prefix option. If no prefix option used then it will try and install in the default /usr/local/bin.<br/>

For remote beeline monitoring, it is assumed you already have ssh access to the remote gateway where the scripts log_beeline_latency.sh and query_beeline_latency.sh will be installed. if not already done so, you now need to setup ssh public/private keys for password-less ssh so that the script can run unattended. See for example this: https://www.debian.org/devel/passwordlessssh<br/>

scp the two generated script files log_beeline_latency.sh and query_beeline_latency.sh to the remote gateway according to the path you specified when asked in the make script.
 [NOTE: if the public/private keys have been set up correctly this scp task will not ask for a password. If it does then you need to double check the keys setup, especially look at permissions of ~/.ssh and the files in it.]<br/>

As a test you should now be able to run the local script log_remote_beeline_latency.sh and should see output something like:

```console
Running script on host <name of your host> for user <your username>. Cluster is called <cluster name you specified>
2017-01-23 16:50:36, 3.703
```
<br/>
The MySQL database/table should also have been updated.<br/>

If everything is working as expected, you can use the generated src/crontab_file to set up a cron job which by default runs the latency logger every 5 minutes. Check/edit the crontab_file as required then run 'cron src/crontab_file' or edit/update your cron jobs as appropriate according to your local polices.

## Docker

This repository includes a section which can build a simple Hadoop/Hive/Monitoring environment for demo/test purposes. Inevitably it is a very simple, single node 'cluster', but you can go through the build/install process as described above, run a simple MapReduce job and see results in the Shiny dashboard.

You must have docker installed on the host system. How to do this is beyond the scope of this document. See the [docker website](https://www.docker.com/) for details.

Docker compose is used to create two services/containers. One is called hive-server and runs Hadoop and Hive and on to which you can install the beeline latency check scripts. The other is called monitorgateway and runs Shiny Server and MySQL and from where you can build and install the monitor code as per the build instructions above.

The docker subfolder has its own Makefile. This can be used to build and run the docker containers, e.g.:

 * make begin - this will build and start the services
 * make ps - this will show the status of the services/containers
 * make clean - this will stop the services/containers
 * make help - display a help message

Other targets are available, see the Makefile for details.

Shared volumes are used to give access to files. The monitorgateway has access to the whole clew directory while hive-server has access to the test_mr directory under docker/hive-server so that a simple MapReduce job can be run on hive-server. This will produce some metrics which will be displayed in the dashboard. Both containers also share a tmp directory which is used to share ssh keys to enable ssh access from monitorgateway to hive-server. This not intended to be a secure solution and must only be used within the context of test/demo as explained above. A make target will create this tmp directory and the ssh private/public keys.<br/>

Once the containers have been created and started, you can get shell access to each one using the command:

```console
docker exec -it <container-name> bash
```
<br/>
Where 'container-name' is either hive-server or monitorgateway. You will start the shell as root in each case. The hive-server container has a user called docker. Use

```console
su - docker
```
 
<br/>To become docker user. The monitorgateway has a user called monitor. Access this using su in the same way.

As monitor user on monitorgateway:

* create MySQL table by running

   ```console
   mysql bl_latency < utils/create_table.sql
   ```
<br/>
* cd clew
* run ./bootstrap.sh
* run ./configure
* run make (responding to prompts as required, see below)
* run sudo make install
* copy scripts to hive-server. Note that the remote user, server name, paths etc. shown below are just examples. These will have been set during the make process.

   ```console
   ssh docker@hive-server 'mkdir -p beeline_latency'
   scp beeline-latency/clusterscripts/Cluster1/query_beeline_latency.sh beeline-latency/clusterscripts/Cluster1/log_beeline_latency.sh \
       docker@hive-server:beeline_latency
   ```
<br/>
* cd back to home directory
* test beeline latency logging by running...

   ```console
   log_remote_beeline_latency.sh
   ```
<br/>
   You should see something like this on the console:

   ```console
   Running script on host hive-server for user docker. Cluster is called hive-server
   2017-03-02 14:42:05, 0.128
   ```
<br/>
* You can check the data in the MySQL table by running...

    ```console
    ./utils/runMySQLQuery
    ```

<br/>
You can try out using cron for the remote logging as described above in the Installation section but you have to explicitly start cron as root on monitorgateway by running
```console
/usr/sbin/cron
```
<br/>
The Shiny Server port (3838) is exposed to the host machine so you can point your browser at that machine, port 3838 to see the dashboard, e.g. http://localhost:3838/clew<br/>

The latency data should be displayed in the line graph under the Beeline latency tab.

To run a simple MapReduce job on hive-server, connect to the container and su as docker user as described above. Then run...

```console
./test_mr/runJob
```

<br/>This script creates the required directories on HDFS, adds the input csv file and runs the job. At the end it should display:

```console
Count of animals having feathers (yes/no):
no  81
yes 20
```
<br/>
This script uses a small csv file of data about animals and a couple of simple map and reduce python scripts to count how many animals have feathers (or not).

runJob can also be run as a 'docker exec' process from make by:
```console
make runjob
```
<br/>

## Credits
Help with determining script path from this [gist](https://gist.github.com/tvlooy/cbfbdb111a4ebad8b93e) by 'tvlooy', in particular the response from user 'JoshuaGross'.

Help with creating a simple MapReduce job came from this [blog post](https://blog.matthewrathbone.com/2013/11/17/python-map-reduce-on-hadoop-a-beginners-tutorial.html) by Matthew Rathbone.

Help with Makefile for docker-compose came from this [gist](https://gist.github.com/miketheman/e17a9e5c6fedac4c34383931c01beb28) by Mike Fiedler

## License and Copyright
See LICENSE for details.

##Contributing
If you have a feature request or want to report a bug, we'd be happy to hear from you. Please raise an issue or fork the project and send a pull request.

##Colophon
The project name, Clew, is taken from *clew*, meaning a ball of thread or yarn (from the Middle English clewe). Since the project is about looking at YARN, this seemed appropriate, and is reflected in the logo. we also hope that the project will give users a 'clue' about what is happening with their YARN installation(s).



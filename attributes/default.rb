# Default attributes for tomcat cookbook

# Master switch to java install or not
default[:tomcat6][:install_java] = true
# minimal java version
# (java will be installed only if the existing version is older than specified here)
default[:tomcat6][:min_java_version] = "1.6.0_31"
# JAVA_HOME in for example init script
default[:tomcat6][:java_home] = "/usr"

# directory to install Tomcat to
default[:tomcat6][:tomcat_home] = "/opt/tomcat6"
# remove the previous tomcat installation or not
default[:tomcat6][:force_reinstall] = false

# users and groups
default[:tomcat6][:user] = "root"
default[:tomcat6][:group] = "root"
# set if UID and GID if you wish. Commented out by default
# default[:tomcat6][:uid] = "0"
# default[:tomcat6][:gid] = "0"

# default files and directories owner.
# Tomcat needs no write permissions for its binaries to work. This improves security a little.
default[:tomcat6][:default_owner] = "root"
default[:tomcat6][:default_group] = "root"

default[:tomcat6][:download_url] = ""
default[:tomcat6][:download_mirror] = "http://www.sai.msu.su/apache/tomcat/tomcat-6/"

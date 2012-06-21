# Default attributes for tomcat cookbook

# Master switch to java install or not
default[:tomcat6][:install_java] = true
# minimal java version
# (java will be installed only if the existing version is older than specified here)
default[:tomcat6][:min_java_version] = "1.6.0_20"
# JAVA_HOME in for example init script
default[:tomcat6][:java_home] = "/usr/java/default"

# directory to install Tomcat to
default[:tomcat6][:tomcat_home] = "/opt/tomcat6"
# may be it's worth placing the configuration directory in a different place (i.e. /usr/local/etc)
default[:tomcat6][:config_dir] = "#{node[:tomcat6][:tomcat_home]}/conf"
# compatibility property (ensure there is a triling slash as opscode's tomcat6 cookbook demands)
default[:tomcat6][:dir] = node[:tomcat6][:config_dir].match(/\/$/) ? node[:tomcat6][:config_dir] : "#{node[:tomcat6][:config_dir]}/"
# webapps directory
default[:tomcat6][:webapps] = "#{node[:tomcat6][:tomcat_home]}/webapps/"
# logs directory
default[:tomcat6][:logs] = "#{node[:tomcat6][:tomcat_home]}/logs/"
# tomcat port
default[:tomcat6][:port] = 8080
# remove the previous tomcat installation or not
default[:tomcat6][:force_reinstall] = false
# The recipe will remove all (example) webapps except the ones set here
# note that only firs level or application context is considered
default[:tomcat6][:webapps_to_preserve] = ["manager"]

# start, stop and restart commands
default[:tomcat6][:start] = "/etc/init.d/tomcat start"
default[:tomcat6][:stop] = "/etc/init.d/tomcat stop"
default[:tomcat6][:restart] = "/etc/init.d/tomcat restart"

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

# either specify your own URL to get tomcat from
# or leave it empty and give a valid tomcat mirror. Latest version will be used then.
default[:tomcat6][:download_url] = ""
default[:tomcat6][:download_mirror] = "http://www.sai.msu.su/apache/tomcat/tomcat-6/"

# username and password to be used with "/manager" webapp for deploy/undeploy
default[:tomcat6][:tomcat_admin_login] = "tc-admin"
default[:tomcat6][:tomcat_admin_password] = "nimda-ct"

# enable tomcat proxying with apache httpd?
default[:tomcat6][:apache_proxy] = false


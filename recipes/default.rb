#
# Cookbook Name:: tomcat6
# Recipe:: default
#
# Copyright 2012, GridDynamics
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# node[:tomcat6][:install_java] is a master manual switch.
if ( node[:tomcat6][:install_java] )
    if ( ! node[:languages][:java] ) || ( ! node[:languages][:java][:version] ) || \
        v1_older_v2( node[:languages][:java][:version], node[:tomcat6][:min_java_version] )
            include_recipe "java"
    end
end

# cleanup the previous installation if requested
if File.directory?(node[:tomcat6][:tomcat_home])
    if node[:tomcat6][:force_reinstall]
        directory "#{node[:tomcat6][:tomcat_home]}" do
            action :delete
            recursive true
        end
    else
        Chef::Log.info("#{node[:tomcat6][:tomcat_home]} exists and node[:tomcat6][:force_reinstall] not set. Exiting")
    end
end

# Prepare a temporary directory
require 'tmpdir'
setup_tmp_dir = Dir.mktmpdir
File::chmod(0777, setup_tmp_dir)

url = ""

# download the distro
distr_download =    remote_file "#{setup_tmp_dir}/tomcat-distro.tar.gz" do
                        source "#{url}"
                        mode "0644"
                        if (! url) || url.empty?
                            action :nothing
                        else
                            action :create
                        end
                    end

# select a version to download
if ( ! node[:tomcat6][:download_url] ) || node[:tomcat6][:download_url].empty?
# Find the latest tomcat 6 version
    # get the list
    remote_file "#{setup_tmp_dir}/tomcat_versions.html" do
        source "http://www.sai.msu.su/apache/tomcat/tomcat-6/"
        mode "0644"
    end

    ruby_block "get-latest-tomcat" do
        block do
            # parse the list
            latest = ""
            File.open("#{setup_tmp_dir}/tomcat_versions.html").each_line do |line|
                if tested = line.match(/v6\.[0-9]+\.[0-9]+/)
                    latest = tested.to_s
                end
            end
            # add a trailing "/" if it's missing
            url = node[:tomcat6][:download_mirror].match(/\/$/) ? node[:tomcat6][:download_mirror] : "#{node[:tomcat6][:download_mirror]}/"
            # build the complete URL. match() is used to remove 'v' in version string
            url = "#{url}#{latest}/bin/apache-tomcat-#{latest.match(/[0-9.]+/)}.tar.gz"
            Chef::Log.info("Automatically selected version: #{latest}")
            Chef::Log.debug("Setting Auto URL for downloading: #{url}")
            # change download resource properties
            distr_download.source( url )
            distr_download.run_action :create
        end
        action :create
    end
else
# use the version selected
    url = node[:tomcat6][:download_url]
    Chef::Log.debug("Specified URL for downloading: #{url}")
end

distr_unpack_dir = File.join( node[:tomcat6][:tomcat_home].split('/')[0..-2],'/')

if ( ! File.directory?(node[:tomcat6][:tomcat_home]) ) || node[:tomcat6][:force_reinstall]
    # do only if there is no tomcat in the directory or if force_reinstall set
    # extract the distro
    execute "extract-tomcat" do
        command "tar xvzf #{setup_tmp_dir}/tomcat-distro.tar.gz"
        # extract the archive to the directory one level higher that tomcat_home
        cwd distr_unpack_dir
        path [ "/usr/local/sbin", "/usr/local/bin", "/usr/sbin", "/usr/bin", "/sbin", "/bin" ]
    end
    
    # tomcat will be unpacked to smth like "apache-tomcat-6.X.YZ"
    # the following block will move it to node[:tomcat6][:config_dir]
    ruby_block "move-tomcat-to-tomcat_home" do
        block do
            #get name of the directory the distr was unpacked to
            tomcat_unpacked_name = url.split('/')[-1].gsub(/(.*)\.tar\.gz/, '\1')
    
            # move tomcat to it's home
            File.rename("#{distr_unpack_dir}/#{tomcat_unpacked_name}", node[:tomcat6][:tomcat_home])
        end
    end
end

# create a user and group for the app to run
if ! node[:etc][:passwd].keys.index(node[:tomcat6][:user])
    # create the user only if it doesn't exist
    group "#{node[:tomcat6][:group]}" do
        gid node[:tomcat6][:gid]
        action :create
    end
    
    # TODO user and group management
    user "#{node[:tomcat6][:user]}" do
        comment "Tomcat run user"
        uid node[:tomcat6][:uid]
        gid node[:tomcat6][:group]
        home node[:tomcat6][:tomcat_home]
        shell "/bin/bash"
        action :create
    end
end

# fix config directory permissions
if node[:tomcat6][:user] != "root"
    # I don't like using "execute" but ruby's File.chown() required numeric UID and GID
    execute "fix-config-dir-permissions" do
        command "chown -R #{node[:tomcat6][:user]}:#{node[:tomcat6][:group]} #{node[:tomcat6][:tomcat_home]}/conf"
        path [ "/usr/local/sbin", "/usr/local/bin", "/usr/sbin", "/usr/bin", "/sbin", "/bin" ]
        action :run
    end
end

# check that tomcat-julu.jar *is* in classpath
java_classpath =  node[:tomcat6][:classpath].match("tomcat-juli.jar") ?
    node[:tomcat6][:classpath] :
    "#{node[:tomcat6][:tomcat_home]}/bin/tomcat-juli.jar:#{node[:tomcat6][:classpath]}"

# this script will be evaluated on tomcat startup
template "#{node[:tomcat6][:tomcat_home]}/bin/setenv.sh" do
    source "setenv.sh.erb"
    variables(
        :cp => java_classpath
    )
    mode "0755"
end

# Sometimes it's better to keep config in a some safe place
if File.identical?(node[:tomcat6][:config_dir], "#{node[:tomcat6][:tomcat_home]}/conf")
    # place config directory in a safe place
    if File.directory?(node[:tomcat6][:config_dir])
        if node[:tomcat6][:force_reinstall]
            # wipe config directory
            directory node[:tomcat6][:config_dir] do
                action :delete
                recursive true
            end
            link "#{node[:tomcat6][:tomcat_home]}/conf" do
                action :delete
            end
            # use the definition to move the directory and create compatibility link
            move_tomcat_dir "move-config" do
                dir_in_home "#{node[:tomcat6][:tomcat_home]}/conf"
                dir_target node[:tomcat6][:config_dir]
            end
        else
            # preserve the existing config dir
            Chef::Log.info("Config directory #{node[:tomcat6][:config_dir]} exists. Not replacing with a new one.")
        end
    else # if there is no config directory in the place
        # use the definition to move the directory and create compatibility link
        move_tomcat_dir "move-config" do
            dir_in_home "#{node[:tomcat6][:tomcat_home]}/conf"
            dir_target node[:tomcat6][:config_dir]
        end
    end # if config directory exist
end # if location is outside home directory

# create an environmental variables file. Will be read at startup
template "#{node[:tomcat6][:env_file]}" do
    source "tomcat6_env.erb"
    owner node[:tomcat6][:user]
    group node[:tomcat6][:group]
end

# add a service user to tomcat administrators list (alter conf/tomcat-users.xml)
ruby_block "add-admin" do
    block do
        admin_string = "<user username=\"#{node[:tomcat6][:tomcat_admin_login]}\" password=\"#{node[:tomcat6][:tomcat_admin_password]}\" roles=\"manager-gui,manager\"/>"
        orig_lines = File.readlines("#{node[:tomcat6][:config_dir]}/tomcat-users.xml")
        if ! orig_lines.index("#{admin_string}\n")
            # only if there is no such admin already
            File.open("#{node[:tomcat6][:config_dir]}/tomcat-users.xml",'w') do |thefile|
                orig_lines.each do |line|
                    thefile.write(line)
                    if line.match('<tomcat-users>')
                        thefile.write("#{admin_string}\n")
                    end
                end
            end
        end
    end
    action :create
end

# fix permissions for directories required to be writeable
["logs", "temp", "work", "webapps"].each do |dir|
    directory "#{node[:tomcat6][:tomcat_home]}/#{dir}" do
        action :create
        owner node[:tomcat6][:user]
        group node[:tomcat6][:group]
        mode "0755"
        recursive true
    end
end

# move webapps directory into a specified place if needed
if File.identical?(node[:tomcat6][:webapps], "#{node[:tomcat6][:tomcat_home]}/webapps")
    if File.directory?(node[:tomcat6][:webapps])
        if node[:tomcat6][:force_reinstall]
            # wipe webapps directory

            # move webapps directory
            move_tomcat_dir "move-webapps" do
                dir_in_home "#{node[:tomcat6][:tomcat_home]}/webapps"
                dir_target node[:tomcat6][:webapps]
            end
        else
            Chef::Log.info("Webapps directory #{node[:tomcat6][:webapps]} exists. Not replacing with a new one.")
            # preserve webapps directory
        end
    else
        # place webapps directory in another place
        # use the definition to move the directory and create compatibility link
        move_tomcat_dir "move-webapps" do
            dir_in_home "#{node[:tomcat6][:tomcat_home]}/webapps"
            dir_target node[:tomcat6][:webapps]
        end
    end
end # if webapps outside of tomcat home

# move logs directory into a specified place if needed
if File.identical?(node[:tomcat6][:logs], "#{node[:tomcat6][:tomcat_home]}/logs")
    # place logs directory in another place
    if File.directory?(node[:tomcat6][:logs])
        if node[:tomcat6][:force_reinstall]
            # wipe logs directory
            directory node[:tomcat6][:logs] do
                action :delete
                recursive true
            end
            link "#{node[:tomcat6][:tomcat_home]}/logs" do
                action :delete
            end
            # use the definition to move the directory and create compatibility link
            move_tomcat_dir "move-logs" do
                dir_in_home "#{node[:tomcat6][:tomcat_home]}/logs"
                dir_target node[:tomcat6][:logs]
            end
        else
            # log message
            Chef::Log.info("Logs directory #{node[:tomcat6][:logs]} exists. Not replacing with a new one.")
        end
    else # if logs directory doesn't exist
        # use the definition to move the directory and create compatibility link
        move_tomcat_dir "move-logs" do
            dir_in_home "#{node[:tomcat6][:tomcat_home]}/logs"
            dir_target node[:tomcat6][:logs]
        end
    end
end # if logs outside tomcat home

# remove the example and doc applications
# prepare resource instance
rm_apps = directory "example-apps" do
    action :nothing
    recursive true
end

webapps_dir = "#{node[:tomcat6][:tomcat_home]}/webapps"
ruby_block "remove_standard_webapps" do
    block do
        Dir.chdir(webapps_dir)
        node[:tomcat6][:webapps_to_delete].each do |app|
            if File.directory?(app) # only if there IS such webapp
                Chef::Log.info("Removing webapp: #{app}")
                rm_apps.path app
                rm_apps.run_action :delete
            end
        end
    end
end

# Create startup script in /etc/init.d/ directory
template "/etc/init.d/tomcat6" do
    source "tomcat6_init.erb"
    mode "0755"
end

# enable and start the service
service "tomcat6" do
    supports :restart => true
    action [ :enable, :start ]
end

if node[:tomcat6][:apache_proxy]
    # include the recipe from site-cookbooks (configure with i.e. JSON file)
    include_recipe "apache2::default_proxy"
end

# perform some cleanup
directory "#{setup_tmp_dir}" do
    action :delete
    recursive true
end


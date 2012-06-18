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

# cleanup the previous installation of requested
if File.directory?(node[:tomcat6][:tomcat_home]) && node[:tomcat6][:force_reinstall]
    directory "#{node[:tomcat6][:tomcat_home]}" do
        action :delete
        recursive true
    end
end

# TODO user and group management

directory "#{node[:tomcat6][:tomcat_home]}" do
    action :create
    owner node[:tomcat6][:default_owner]
    group node[:tomcat6][:default_group]
    mode "0755"
end

# Prepare a temporary directory
require 'tmpdir'
setup_tmp_dir = Dir.mktmpdir
File::chmod(0777, setup_tmp_dir)

# select a version to download
if ( ! node[:tomcat6][:download_url] ) || node[:tomcat6][:download_url].empty?
# Find the l7atest tomcat 6 version
    # get the list
    remote_file "#{setup_tmp_dir}/tomcat_versions.html" do
    source "http://www.sai.msu.su/apache/tomcat/tomcat-6/"
    mode "0644"
    end

    # parse the list
    latest = ""
    File.open("#{setup_tmp_dir}/tomcat_versions.html").each_line do |line|
        if tested = line.match(/v6\.[0-9]+\.[0-9]+/)
            latest = tested.to_s
        end
    end
    # add a trailing "/" if it's missing
    url = node[:tomcat6][:download_mirror].match(/\/$/) ? [:tomcat6][:download_mirror] : "#{[:tomcat6][:download_mirror]}/"
    # build the complete URL. match() is used to remove 'v' in version string
    url = "#{url}#{latest}/bin/apache-tomcat-#{latest.match(/[0-9.]+/)}.tar.gz"
    Chef::Log.info("Automatically selected version: #{latest}")
    Chef::Log.debug("Auto URL for downloading: #{url}")
else
# download the version selected
    url = node[:tomcat6][:download_url]
    Chef::Log.debug("Specified URL for downloading: #{url}")
end

# download the distro
remote_file "#{setup_tmp_dir}/tomcat-distro.tar.gz" do
    source "#{url}"
    mode "0644"
end

# extract the distro
execute "extract-tomcat" do
    command "tar xvzf #{setup_tmp_dir}/tomcat-distro.tar.gz"
    cwd "#{node[:tomcat6][:tomcat_home]}"
    path [ "/usr/local/sbin", "/usr/local/bin", "/usr/sbin", "/usr/bin", "/sbin", "/bin" ]
end

# fix permissions for directories required to be writeable
["logs", "temp", "work", "webapps"].each do |dir|
    directory "#{node[:tomcat6][:tomcat_home]}/#{dir}" do
        action :create
        owner node[:tomcat6][:user]
        group node[:tomcat6][:group]
        mode "0755"
    end
end



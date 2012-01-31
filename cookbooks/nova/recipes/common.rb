#
# Cookbook Name:: nova
# Recipe:: common
#
# Copyright 2010, Opscode, Inc.
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

include_recipe "apt"

package "nova-common" do
  options "--force-yes -o Dpkg::Options::=\"--force-confdef\""
  action :install
end

directory "/etc/nova" do
  owner "root"
  group "root"
  mode 0755
  action :create
end

env_filter = ''
if node[:app_environment]
  env_filter = " AND app_environment:#{node[:app_environment]}"
end

sql_connection = nil
if node[:nova][:mysql]
  Chef::Log.info("Using mysql")
  package "python-mysqldb"
  mysqls = nil

  unless Chef::Config[:solo]
    mysqls = search(:node, "recipes:nova\\:\\:mysql#{env_filter}")
  end
  if mysqls and mysqls[0]
    mysql = mysqls[0]
    Chef::Log.info("Mysql server found at #{mysql[:mysql][:bind_address]}")
  else
    mysql = node
    Chef::Log.info("Using local mysql at  #{mysql[:mysql][:bind_address]}")
  end
  sql_connection = "mysql://#{mysql[:nova][:db][:user]}:#{mysql[:nova][:db][:password]}@#{mysql[:mysql][:bind_address]}/#{mysql[:nova][:db][:database]}"
end

rabbits = nil
unless Chef::Config[:solo]
  rabbits = search(:node, "recipes:nova\\:\\:rabbit#{env_filter}")
end
if rabbits and rabbits[0]
  rabbit = rabbits[0]
  Chef::Log.info("Rabbit server found at #{rabbit[:rabbitmq][:address]}")
else
  rabbit = node
  Chef::Log.info("Using local rabbit at #{rabbit[:rabbitmq][:address]}")
end

objectstores = nil
unless Chef::Config[:solo]
  objectstores = search(:node, "recipes:nova\\:\\:objectstore#{env_filter}")
end
if objectstores
  objectstore = objectstores[0]
  Chef::Log.info("Objectstore server found at #{objectstore[:nova][:my_ip]}")
else
  objectstore = node
  Chef::Log.info("Objectstore server found at #{objectstore[:nova][:my_ip]}")
end

networks = nil
unless Chef::Config[:solo]
  networks = search(:node, "recipes:nova\\:\\:network#{env_filter}")
end
if networks
  network = networks[0]
  Chef::Log.info("Network server found at #{network[:nova][:my_ip]}")
else
  network = node
  Chef::Log.info("Network server found at #{network[:nova][:my_ip]}")
end

rabbit_settings = {
  :address => rabbit[:rabbitmq][:address],
  :port => rabbit[:rabbitmq][:port],
  :user => rabbit[:nova][:rabbit][:user],
  :password => rabbit[:nova][:rabbit][:password],
  :vhost => rabbit[:nova][:rabbit][:vhost]
}

execute "nova-manage db sync" do
  user "nova"
  action :nothing
end

file "/etc/default/nova-common" do
  content <<-EOH
# defaults file for all the nova services
#
# Setting this to 1 will allow the services to run, it is set to 0 by default
# to prevent the services from running until they have been configured.
ENABLED=1
EOH
  owner "root"
  group "root"
  mode 0644
  action :nothing
end

template "/etc/nova/nova.conf" do
  source "nova.conf.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    :sql_connection => sql_connection,
    :rabbit_settings => rabbit_settings,
    :s3_host => objectstore[:nova][:my_ip],
    :flatdhcp => network[:nova][:flatdhcp]
  )
  notifies :run, resources(:execute => "nova-manage db sync"), :immediately
  notifies :touch, resources(:file => "/etc/default/nova-common"), :immediately
end

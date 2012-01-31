unless Chef::Config[:solo]
  node[:devstack][:hostname] = node.name
end

execute "/root/hostname.sh" do
  action :nothing
end

domain = node[:fqdn].split('.')[1..-1].join('.')

template "/root/hostname.sh" do
  source "hostname.erb"
  owner "root"
  group "root"
  mode 0755
  variables(
    :ip => node[:devstack][:my_ip],
    :hostname => node[:devstack][:hostname],
    :domain => domain
  )
  notifies :run, resources(:execute => "/root/hostname.sh"), :immediately
end

package "git"

execute "git clone #{node[:devstack][:repository]}" do
  cwd node[:devstack][:dir]
  user node[:devstack][:user]
  group node[:devstack][:group]
  not_if { File.directory?("#{node[:devstack][:dir]}/devstack") }
end

template "#{node[:devstack][:dir]}/devstack/localrc" do
  source "localrc.erb"
  owner node[:devstack][:user]
  group node[:devstack][:group]
  mode 0644
end

execute "su -c 'set -e; cd #{node[:devstack][:dir]}/devstack; bash stack.sh > devstack.log' #{node[:devstack][:user]}"

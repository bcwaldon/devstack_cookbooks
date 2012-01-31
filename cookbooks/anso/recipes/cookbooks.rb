#
# Cookbook Name:: anso
# Recipe:: vagrant
#
# Copyright 2011, Anso Labs
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

package "git"

file "/root/cookbooks.sh" do
  content <<-EOH
git clone #{node[:cookbooks][:url]} -b #{node[:cookbooks][:branch]} /root/openstack-cookbooks
export HOME=/root
knife configure -i -y --defaults -r="" -u #{node[:cookbooks][:user]}
knife cookbook upload -o /root/openstack-cookbooks/cookbooks -a
EOH
  owner "root"
  group "root"
  mode 0755
end

execute "/root/cookbooks.sh && touch /root/cooked" do
  user "root"
  group "root"
  not_if { File.exists?("/root/cooked") }
end

if node[:cookbooks][:copy_dir]
  execute "cp /root/.chef/#{node[:cookbooks][:user]}.pem #{node[:cookbooks][:copy_dir]}" do
    user "root"
    group "root"
  end
end

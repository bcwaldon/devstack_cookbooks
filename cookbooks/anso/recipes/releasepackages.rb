#
# Cookbook Name:: anso
# Recipe:: devpackages
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

include_recipe 'apt'

apt_repository "nova_release" do
  key "2A2356C9"
  keyserver "keyserver.ubuntu.com"
  uri "http://ppa.launchpad.net/nova-core/release/ubuntu"
  distribution node[:apt][:distro]
  components(["main"])
  action :add
end

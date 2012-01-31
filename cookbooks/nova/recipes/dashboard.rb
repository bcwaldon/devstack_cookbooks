package "python-pip"
package "python-virtualenv"
package "bzr"
package "git-core"
package "apache2"
package "libapache2-mod-wsgi"

execute "git clone #{node[:nova][:dashboard][:dashboard_repo]} #{node[:nova][:dashboard][:deploy_dir]}"

file "/usr/lib/python2.6/dist-packages/dashboard.pth" do
  content node[:nova][:dashboard][:dashboard_dir]
end

execute "python setup.py develop" do
    cwd node[:nova][:dashboard][:django_nova_dir]
end

execute "pip install -r #{node[:nova][:dashboard][:dashboard_dir]}/tools/pip-requires" do
    cwd node[:nova][:dashboard][:django_nova_dir]
end

template "#{node[:nova][:dashboard][:dashboard_dir]}/local/local_settings.py" do
    source "dashboard.local_settings.erb"
    mode "0644"
end

template "#{node[:nova][:dashboard][:dashboard_dir]}/local/initial_data.json" do
    source "dashboard.initial_data.json.erb"
    mode "0644"
end

template "#{node[:nova][:dashboard][:apache_dir]}/sites-available/default" do
  source "dashboard.apache.erb"
  mode "0644"
end

execute "python manage.py syncdb --noinput" do
    cwd "#{node[:nova][:dashboard][:dashboard_dir]}/dashboard"
end

execute "python manage.py loaddata ../local/initial_data.json" do
    cwd "#{node[:nova][:dashboard][:dashboard_dir]}/dashboard"
end

execute "chown -R www-data:www-data #{node[:nova][:dashboard][:dashboard_dir]}/local"

execute "/etc/init.d/apache2 restart"


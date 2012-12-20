#
# Cookbook Name:: graphite-chef-centos
# Recipe:: default
#

# Working on Centos 6 and Amazon Linux
# Thanks to http://www.ezunix.com/index.php?title=Install_statsd_and_graphite_on_CentOS_or_RHEL

# Install Epel Repo.
# TODO - make this smarter. User version info and check if already installed by other means.
if node['platform_version'].to_i >= 6.0
  # Install epel 6 signing key.
  execute "Install epel" do
    command "rpm -Uvh http://ftp.linux.ncsu.edu/pub/epel/6/i386/epel-release-6-7.noarch.rpm"
    not_if "rpm -qa epel-release | grep epel-release"
  end

  # Install Epel 6 Repo
  cookbook_file "/etc/yum.repos.d/epel.repo" do
    source "epel6.repo"
  end
end

%w(python python-pip python-devel Django bitmap pycairo python-sqlite2 gcc make).each { |p|
  package p
}

if node['platform'] == 'amazon'
  # yum install bitmap-fonts fails on amaz!
  %w(fixed-fonts console-fonts fangsongti-fonts lucida-typewriter-fonts miscfixed-fonts fonts-compat).each { |font|
    execute "loading rpm for bitmap-#{font}" do
      command "rpm -i http://mirror.centos.org/centos/6/os/x86_64/Packages/bitmap-#{font}-0.3-15.el6.noarch.rpm"
      not_if "rpm -qa bitmap-#{font}* | grep bitmap"
    end
  }
else
  # Works fine on base Centos 6
  package 'bitmap-fonts'
end

# PIP Installs. 
%w(whisper django-tagging).each { |pip|
  execute "Install #{pip}" do
    command "pip-python install #{pip}"
    not_if "pip-python freeze | grep #{pip}"
  end
}

# Pip post-test for carbon & graphite-web install isn't working.
execute "Install carbon" do
  command "pip-python install carbon"
  not_if "test -f /opt/graphite/conf/carbon.conf.example" # This test is bad if gcc isn't initially installed.
end
execute "Install graphite-web" do
  command "pip-python install graphite-web"
  not_if "test -f /opt/graphite/webapp/graphite/manage.py"
end

cookbook_file "/opt/graphite/conf/carbon.conf"
cookbook_file "/opt/graphite/conf/storage-schemas.conf"

# This is failing on first run, but successed on second try.
execute "Setup DB" do
  command "python /opt/graphite/webapp/graphite/manage.py syncdb --noinput"
  not_if "python /opt/graphite/webapp/graphite/manage.py inspecdb | grep django.db"
end

# Setup apache
package "httpd"
package "mod_wsgi"

cookbook_file "/etc/httpd/conf.d/graphite-vhost.conf" 
cookbook_file "/opt/graphite/conf/graphite.wsgi" do
  mode "644"
end

# Allow access by the webserver:
execute "Grant apache access to /opt/graphite/storage" do
  command "chown apache -R /opt/graphite/storage/"
end

service "httpd" do
  action [:enable, :start]
end

execute "Start carbon service" do
  command "/opt/graphite/bin/carbon-cache.py start"
  not_if "ps -p `more /opt/graphite/storage/carbon-cache-a.pid` | grep carbon"
end


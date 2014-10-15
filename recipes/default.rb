heka_deb = File.join(Chef::Config[:file_cache_path], node['heka']['file_name'])
cookbook_collection = run_context.cookbook_collection[cookbook_name]
sandbox_types = %w{ encoders decoders filters }

package 'libzmq1' do
  action :install
end

directory node['heka']['conf_dir'] do
  action :create
  owner 'root'
  group 'root'
end

sandbox_types.each do |type|
  directory File.join(node['heka']['conf_dir'], type) do
    action :create
    owner 'root'
    group 'root'
  end
end

# Hacky way to ensure sandbox files are sync'd from the cookbook
# Add a file to files/default/{encoders,decoders,filters}
# It will land in /etc/heka/{encoders,decoders,filters}
ruby_block 'ensure_sandbox_scripts' do
  block do
    require 'pathname'
    cookbook_collection.manifest['files'].each do |f|
      next unless sandbox_types.any? {|t| f['path'].include?(t) }

      name = f['name']
      path = Pathname.new(f['path'])
      relative_path = path.relative_path_from(Pathname.new('files/default'))

      dest_path = File.join(node['heka']['conf_dir'], relative_path)

      cookbook_file = Chef::Resource::CookbookFile.new(dest_path, run_context)
      cookbook_file.cookbook(cookbook_name.to_s)
      cookbook_file.source(relative_path.to_s)
      cookbook_file.mode('0644')
      cookbook_file.run_action(:create)
    end
  end
end

template '/etc/heka/config.toml' do
  source 'config.toml.erb'
  owner 'root'
  group 'root'
  notifies :restart, 'service[heka]'
end

remote_file heka_deb do
  source node['heka']['remote_file']
  checksum node['heka']['checksum']
end

dpkg_package 'heka' do
  source heka_deb
  action :install
end

template '/etc/init/heka.conf' do
  source 'heka_init.conf.erb'
  owner 'root'
  group 'root'
  variables({
    :hostname => node['hostname'],
    :bin => node['heka']['bin'],
    :log => node['heka']['log'],
    :conf_dir => node['heka']['conf_dir']
  })
  notifies :restart, 'service[heka]'
end

service 'heka' do
  action [ :enable, :start ]
  provider Chef::Provider::Service::Upstart
end

logrotate_app 'hekad' do
  cookbook  'logrotate'
  path      node['heka']['log']
  missingok true
  frequency 'weekly'
  rotate    4
  create    '644 root root'
end

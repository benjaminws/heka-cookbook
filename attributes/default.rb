node.set['heka']['version'] = '0.8.0'
node.set['heka']['file_name'] = "heka_#{node['heka']['version']}_amd64.deb"
node.set['heka']['remote_file'] = "https://s3.amazonaws.com/gw-internal/packages/#{node['heka']['file_name']}"
node.set['heka']['checksum'] = '7075137ec51a2d6316c36f443cab0bf2'
node.set['heka']['conf_dir'] = '/etc/heka/'
node.set['heka']['bin'] = '/usr/bin/hekad'
node.set['heka']['log'] = '/var/log/hekad.log'

node.set['heka']['enable_dashboard'] = true
node.set['heka']['types'] = []
node.set['heka']['outputs'] = ['stdout']
node.set['heka']['encoders'] = ['payload']

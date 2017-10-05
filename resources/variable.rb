# To learn more about Custom Resources, see https://docs.chef.io/custom_resources.html

default_action :set

property :variable_name, kind_of: String, name_attribute: true
property :host, kind_of: [String, NilClass], default: 'localhost', desired_state: false
property :port, kind_of: [String, NilClass], default: node['mariadb']['mysqld']['port'].to_s, desired_state: false
property :user, kind_of: [String, NilClass], default: 'root', desired_state: false
property :password, kind_of: [String, NilClass], default: node['mariadb']['server_root_password'], sensitive: true, desired_state: false
property :value, kind_of: [String, Integer, TrueClass, FalseClass], required: true
property :permanent, kind_of: [TrueClass, FalseClass], default: false

action_class do
  include MariaDB::Connection::Helper

end

load_current_value do
  require 'mysql2'
  socket = if node['mariadb']['client']['socket'] && host == 'localhost'
             node['mariadb']['client']['socket']
           end
  conn_options = { username: user, password: password,
                   port: port }.merge!(socket.nil? ? { host: host } : { socket: socket })
  begin
    mysql_connection = Mysql2::Client.new(conn_options)
    variable_query = "SHOW VARIABLES LIKE '#{new_resource.variable_name}'"
    variable_value = mysql_connection.query(variable_query)
    current_value_does_not_exist! if variable_value.count == 0
    slave_status.each do |row|
      value = variable_value['Value']
    end
  rescue Mysql2::Error => mysql_exception
    current_value_does_not_exist! if mysql_exception.message =~ /There is no master connection.*/
    raise "Mysql connection error: #{mysql_exception.message}"
  ensure
    mysql_connection.close
  end
end

action :set do
    converge_if_changed :value do
    end
end

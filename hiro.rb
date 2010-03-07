require 'rubygems'
require 'isaac'
require 'yaml'


puts "Loading bot configuration file..."
config = YAML.load_file("config.yaml")
puts "Loading user file..."
users = YAML.load_file("users.yaml")

authorized_users = {}

configure do |c|
  c.nick     = config['nick']
  c.server   = config['server']
  c.port     = config['port']
  c.realname = config['realname']
  c.version  = config['version']
end


on :connect do
  join config["channel"]
end

on :channel, /^whoami/ do
  auth_status = authorized_users.include? nick
  msg channel, "#{nick}: nick=#{nick} host=#{host} auth=#{auth_status}"
end


on :channel, /^restricted/ do
  if authorized_users.include? nick and authorized_users[nick]["host"] == "#{nick}@#{host}"
      msg channel, "#{nick}: You are in my authorized users list and your hostmask matches."
  else
    msg channel, "#{nick}: You are not in my list of authorized users."
  end
end

on :channel, /^authorized_users/ do
  authorized_users.each_pair { |n, h|
    msg channel, "#{n}"
    h.each_pair { |k,v|
      msg channel, "  #{k} = #{v}"
      }
    }

end

on :channel, /^password (\S+) (\S+)/ do
  if authorized_users.include? nick and authorized_users[nick]["host"] == "#{nick}@#{host}"
    if users[authorized_users[nick]["user"]]["pass"] == match[0]
      users[authorized_users[nick]["user"]]["pass"] = match[1]
      File.open('users.yaml', 'w') do |out|
        YAML.dump(users, out)
      end
      msg channel, "#{nick}: Your password has been updated."
    else
      msg channel, "#{nick}: Bad password. Your password has not been changed."
    end
  else
    msg channel, "#{nick}: You must identify before using this command."    
  end
end


on :channel, /^unidentify/ do
  if authorized_users.include? nick and authorized_users[nick]["host"] == "#{nick}@#{host}"
    authorized_users.delete(nick)
    msg channel, "#{nick}: You have been deauthorized."
  else
    msg channel, "#{nick}: You are not an authorized user."
  end
end

on :channel, /^identify (\S+) (\S+)/ do
  username = match[0]
  password = match[1]
  
  if users.include? username and users[username]["pass"] == password
    groups = 
    authorized_users.store(nick, {"user" => username, "host" => "#{nick}@#{host}", "groups" => users[username]["groups"]})
    msg channel, "#{nick}: You have been added to my list of authorized users."
  else
    msg channel, "#{nick}: Bad username or password."
  end

end


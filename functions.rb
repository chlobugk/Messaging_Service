require 'pg'
load './local_env.rb' if File.exists?('./local_env.rb')

def valid_password?(password)
	password.to_s.length > 5
end

def valid_username?(username)
	username.to_s.length > 0
end

def valid_full_name?(full_name)
	full_name.to_s.length > 1
end

def valid_credentials?(full_name, username, password)
	valid_full_name?(full_name) && valid_username?(username) && valid_password?(password)
end

def username_not_unique?(new_username)
	db_params = {
    host: ENV['host'],
    port: ENV['port'],
    dbname: ENV['db_name'],
    user: ENV['user'],
    password: ENV['password']
	}

	db = PG::Connection.new(db_params)
	
	dbname=db.exec("SELECT username FROM accounts")
	results = false
	dbname.each do |item|
		if item['username'] == new_username
			results = true
		end
	end
	results
end

def login_match?(log_username, log_password)
	db_params = {
    host: ENV['host'],
    port: ENV['port'],
    dbname: ENV['db_name'],
    user: ENV['user'],
    password: ENV['password']
	}

	db = PG::Connection.new(db_params)
	
	dbname=db.exec("SELECT username, password FROM accounts")
	results = false
	dbname.each do |item|
		if item['username'] == log_username && item['password'] == log_password
			results = true
		end
	end
	results
end

def new_message?(username, friendname)
	db_params = {
    host: ENV['host'],
    port: ENV['port'],
    dbname: ENV['db_name'],
    user: ENV['user'],
    password: ENV['password']
	}

	db = PG::Connection.new(db_params)
	dbname=db.exec("SELECT user, friend FROM messages")
	results = false
	if username_not_unique?(friendname) == true
		dbname.each do |item|
			if item['from'] == username && item['to'] == friendname
				results = true
			end
		end
	end
	results
end

def friend_exist?(username, friend)
	db_params = {
    host: ENV['host'],
    port: ENV['port'],
    dbname: ENV['db_name'],
    user: ENV['user'],
    password: ENV['password']
	}

	db = PG::Connection.new(db_params)
	
	dbname=db.exec("SELECT username, friends FROM accounts")
	results = false
	dbname.each do |item|
		if item['username'] == username && item['friends'].include?(friend.to_s)
			results = true
		end
	end
	results
end








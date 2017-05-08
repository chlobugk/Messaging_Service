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
	
	results = false

	check_login = db.exec("SELECT username, password FROM accounts WHERE username = '#{session[:username]}'")

    password = check_login[0]['password']
    unhashed_pass = BCrypt::Password.new(password)

    if check_login[0]['username'] == log_username &&  unhashed_pass == log_password
       results = true
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

	friends_table = username + "_" + "friends"
	dbname=db.exec("SELECT friends FROM #{friends_table}")
	results = false
	dbname.each do |item|
		if item['friends'] == friend
			results = true
		end
	end
	results
end

def user_exist?(user)
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
		if item['username'] == user
			results = true
		end
	end
	results
end

def send_message(username, friend)
	db_params = {
    host: ENV['host'],
    port: ENV['port'],
    dbname: ENV['db_name'],
    user: ENV['user'],
    password: ENV['password']
	}

	db = PG::Connection.new(db_params)
	
	from_table = "msg" + "_" + username.to_s + "_" + friend.to_s
	to_table = "msg" + "_" + friend.to_s + "_" + username.to_s
	dbname=db.exec("INSERT INTO #{from_table}(send) VALUES('#{params[:message]}')");
	dbname=db.exec("INSERT INTO #{to_table}(receive) VALUES('#{params[:message]}')");

end

def fb_user_exist?(id)
	db_params = {
    host: ENV['host'],
    port: ENV['port'],
    dbname: ENV['db_name'],
    user: ENV['user'],
    password: ENV['password']
	}

	db = PG::Connection.new(db_params)
	
	dbname=db.exec("SELECT fb_id FROM accounts")
	results = false
	dbname.each do |item|
		if item['fb_id'] == id
			results = true
		end
	end
	results
end

def g_user_exist?(gmail)

	db_params = {
    host: ENV['host'],
    port: ENV['port'],
    dbname: ENV['db_name'],
    user: ENV['user'],
    password: ENV['password']
	}

	db = PG::Connection.new(db_params)
	
	dbname=db.exec("SELECT gmail FROM accounts")
	results = false
	dbname.each do |item|
		if item['gmail'] == gmail
			results = true
		end
	end
	results
end


def delete_account(username)
	db_params = {
    host: ENV['host'],
    port: ENV['port'],
    dbname: ENV['db_name'],
    user: ENV['user'],
    password: ENV['password']
	}

	db = PG::Connection.new(db_params)
	
	friends_table = username + "_" + "friends"
	dbname=db.exec("SELECT friends FROM #{friends_table}")
	dbname.each do |item|
		other_friend_tables = item['friends'] + "_" + "friends"
		send_table = "msg" + "_" + username + "_" + item['friends'] 
		receive_table = "msg" + "_" + item['friends'] + "_" + username
		db.exec("DROP TABLE IF EXISTS #{send_table}");
		db.exec("DROP TABLE IF EXISTS #{receive_table}");
		db.exec("DELETE FROM #{other_friend_tables} WHERE friends = '#{username}' ")
	end
	db.exec("DROP TABLE IF EXISTS #{friends_table}");
	db.exec("DELETE FROM accounts WHERE username = '#{username}' ")
end


def reset_password(password)

	db = PG::Connection.new(db_params)

	full_name = session[:full_name]
	username = session[:username]
	new_password = session[:new_password]
	dbname=db.exec("SELECT password FROM accounts")

end


def unread_message?(username)
	db_params = {
    host: ENV['host'],
    port: ENV['port'],
    dbname: ENV['db_name'],
    user: ENV['user'],
    password: ENV['password']
	}

	db = PG::Connection.new(db_params)

	friends_table = username + "_" + "friends"
	dbname=db.exec("SELECT friends, message FROM #{friends_table}")
	results = false
	dbname.each do |item|
		if item['message'] == 'unread'
			results = true
		end
	end
	results
end









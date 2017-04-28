require 'sinatra'
require 'pg'
require 'bcrypt'
require_relative 'functions.rb'
require_relative 'controller.rb'
load './local_env.rb' if File.exists?('./local_env.rb')
db_params = {
    host: ENV['host'],
    port: ENV['port'],
    dbname: ENV['db_name'],
    user: ENV['user'],
    password: ENV['password']
}
enable :sessions

db = PG::Connection.new(db_params)

get '/' do
	session[:username] = nil
	session[:sendfriend] = nil
	accounts=db.exec("SELECT full_name, username, password FROM accounts");
	erb :home
end

post '/' do
	session[:username] = nil
	accounts=db.exec("SELECT full_name, username, password FROM accounts");
	erb :home
end

post '/login' do
	redirect '/login'
end

get '/login' do
	session[:message_add] = nil
	erb :login, locals: {message: ''}
end

get '/invalid_login' do
	message = 'The username or password you entered is incorrect.'
	erb :login, locals: {message: message}
end

post '/check_login' do
	session[:username] = params[:username]
	if login_match?(session[:username], params[:password])
		redirect '/message_home'
	else
		redirect '/invalid_login'
	end
end

post '/create_account' do
	redirect '/create_account'
end

get '/create_account' do
	message1 = nil
	message2 = nil
	erb :create_account, locals: {message1: message1, message2: message2}
end


get '/invalid_credentials' do
	message1 = 'One or more of your credentials was invalid.'
	message2 = 'Please make sure your password is at least 6 characters.'
	erb :create_account, locals: {message1: message1, message2: message2}
end

get '/username_not_unique' do
	message1 = 'The user name you selected has already been taken.'
	message2 = 'Please choose a different user name.'
	erb :create_account, locals: {message1: message1, message2: message2}
end

post '/created' do

	full_name = params[:full_name]
	username = params[:username]
	password = params[:password]
	password2 = params[:password2]

	if valid_credentials?(full_name, username, password) == false	
		redirect '/invalid_credentials'
	elsif password != password2
		message1 = 'Your passwords do not match'
		message2 = 'Please try again.'
		erb :create_account, locals: {message1: message1, message2: message2}
	elsif username_not_unique?(username)
		redirect '/username_not_unique'
	else
		hashed_password = BCrypt::Password.create("#{password}")
		#hashed_password = SCrypt::Password.create("#{password}")
		#this post adds created account info to database
		# db.exec("INSERT INTO accounts(full_name, username, password) VALUES('#{full_name}', '#{username}', '#{password}')");
		# accounts=db.exec("SELECT full_name, username, password FROM accounts"); 
		db.exec("INSERT INTO accounts(full_name, username, test_password) VALUES('#{full_name}', '#{username}', '#{hashed_password}')")
		table_name = username + "_" + "friends"
		db.exec("CREATE TABLE #{table_name} (
			following	text,
		    followers     text
			)")
		session[:username] = username
		session[:message_add] = nil
		redirect '/message_home'
	end
end

post '/message_home' do
	session[:username] = params[:username]
	redirect '/message_home'
end

get '/message_home' do
	friends_table = session[:username].to_s + "_" + "friends"
	friends=db.exec("SELECT following, followers FROM #{friends_table}");
	accounts=db.exec("SELECT full_name, username, password FROM accounts");
	messages=db.exec("SELECT user_name, friend, message, date_time FROM messages")
	erb :message, locals: {username: session[:username], messages: messages, accounts: accounts, message1: session[:message_add], friends: friends}

end

post '/addfriend' do
	
	session[:message_add] = nil
	friend_name = params[:friend_name].to_s
	username = params[:username].to_s
	table_name_send = "msg" + "_" + username + "_" + friend_name
	table_name_receive = "msg" + "_" + friend_name + "_" + username
	following_table = username + "_" + "friends"
	follower_table = friend_name + "_" + "friends"
	if followers?(username, friend_name) == true && friend_exist?(username, friend_name) == false
		db.exec("INSERT INTO #{following_table}(following) VALUES('#{friend_name}')")

	elsif user_exist?(friend_name) == true
		if friend_exist?(username, friend_name) == false
			db.exec("INSERT INTO #{following_table}(following) VALUES('#{friend_name}')")
			db.exec("INSERT INTO #{follower_table}(followers) VALUES('#{username}')")
			db.exec("CREATE TABLE #{table_name_send} (
			send	text,
		    receive     text
			)")
			db.exec("CREATE TABLE #{table_name_receive} (
			send	text,
		    receive     text
			)")
		elsif friend_exist?(username, friend_name) == true
   			session[:message_add] = 'This user is already your friend.'
   		end
   	else
   		session[:message_add] = 'User does not exist.'
   		
   	end
	session[:username] = username
	redirect '/message_home'

end

post '/send' do
	redirect '/send_message'
end

get '/send_message' do
	# pg.exec("IF EXISTS (SELECT * FROM pg_table WHERE tablename=table_name_send)
		send_message(session[:username], session[:sendfriend])
		friends_table = session[:username].to_s + "_" + "friends"
		friends=db.exec("SELECT following, followers FROM #{friends_table}");
		from_table = "msg" + "_" + session[:username].to_s + "_" + session[:sendfriend].to_s
		msg_table=db.exec("SELECT send, receive FROM #{from_table}");

		erb :send, locals: {msg_table: msg_table, username: session[:username], sendfriend: session[:sendfriend], friends: friends}
end
 
post '/send_message' do
	session[:sendfriend] = nil
	session[:sendfriend] = params[:friend]
	if session[:sendfriend].to_s.length > 0 && user_exist?(session[:sendfriend])
		redirect '/send_message'
	else
		redirect '/message_home'
	end
end

get '/settings' do
	friends_table = session[:username] + "_" + "friends"
	friends=db.exec("SELECT following, followers FROM #{friends_table}");
	accounts=db.exec("SELECT full_name, username, password FROM accounts");
	messages=db.exec("SELECT user_name, friend, message, date_time FROM messages")
	erb :settings, locals: {username: session[:username], messages: messages, accounts: accounts, message1: session[:message_add], friends: friends}
end

post '/settings' do
	redirect '/settings'
end

post '/delete' do
	trash = session[:username]
db.exec("DELETE FROM accounts WHERE username = '#{trash}' ");
	redirect '/'
end
require 'sinatra'
require 'pg'
require 'bcrypt'
require_relative 'functions.rb'
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
	accounts=db.exec("SELECT full_name, username FROM accounts");
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

get '/facebook' do
	session[:full_name] = params[:first_name]
	session[:fb_id] = params[:fb_id]
	if fb_user_exist?(params[:fb_id]) == false
		erb :create_username, locals: {full_name: session[:full_name]}
	else
		dbname=db.exec("SELECT username, fb_id FROM accounts")
		dbname.each do |item|
			if item['fb_id'] == params[:fb_id]
				session[:username] = item['username']
			end
		end
		redirect '/message_home'
	end
end

get '/google' do
	"hey"
end

post '/create_username' do
	full_name = session[:full_name].to_s
	username = params[:username].to_s
	hashed_password = "facebook_secret"
	fb_id = session[:fb_id].to_s
	db.exec("INSERT INTO accounts(full_name, username, password, fb_id) VALUES('#{full_name}', '#{username}', '#{hashed_password}', '#{fb_id}')")

			table_name = username + "_" + "friends"

	db.exec("CREATE TABLE #{table_name} (
			friends    text
			)")
	session[:username] = params[:username]
	redirect '/message_home'
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
			message2 = 'Please try again'
			erb :create_account, locals: {message1: message1, message2: message2}
		elsif username_not_unique?(username)
		  redirect '/username_not_unique'
		else
			hashed_password = BCrypt::Password.create("#{password}")

			db.exec("INSERT INTO accounts(full_name, username, password) VALUES('#{full_name}', '#{username}', '#{hashed_password}')")
			table_name = username + "_" + "friends"
			db.exec("CREATE TABLE #{table_name} (
					friends    text
					)")
			session[:username] = username
			session[:message_add] = nil
			redirect 'message_home'
		end
end

post '/message_home' do
	session[:username] = params[:username]
	username = params[:username]
	redirect '/message_home?username=' + username
end

get '/message_home' do
	username = session[:username].to_s
	friends_table = username + "_" + "friends"
	friends=db.exec("SELECT friends FROM #{friends_table}");
	accounts=db.exec("SELECT full_name, username, password FROM accounts");
	erb :message, locals: {username: session[:username], accounts: accounts, message1: session[:message_add], friends: friends}

end

post '/addfriend' do
	
	session[:message_add] = nil
	friend_name = params[:friend_name].to_s
	username = params[:username].to_s
	table_name_send = "msg" + "_" + username + "_" + friend_name
	table_name_receive = "msg" + "_" + friend_name + "_" + username
	following_table = username + "_" + "friends"
	follower_table = friend_name + "_" + "friends"
	
	if user_exist?(friend_name) == true
 		if friend_exist?(username, friend_name) == false
 			db.exec("INSERT INTO #{following_table}(friends) VALUES('#{friend_name}')")
 			db.exec("INSERT INTO #{follower_table}(friends) VALUES('#{username}')")
 			db.exec("CREATE TABLE #{table_name_send} (
 			send	text,
 		 receive    text
 			)")
 			db.exec("CREATE TABLE #{table_name_receive} (
 			send	text,
 		 receive	text
 			)")
		else friend_exist?(username, friend_name) == true
    		session[:message_add] = 'This user is already your friend.'
   		end
    else		
    	session[:message_add] = 'User does not exist.'
	end
	session[:username] = username
	redirect '/message_home'
end

post '/send' do
	message = params[:message]
	username = session[:username].to_s
	friend = session[:sendfriend].to_s
	from_table = "msg" + "_" + username + "_" + friend
	to_table = "msg" + "_" + friend + "_" + username

	dbname=db.exec("INSERT INTO #{from_table}(send, receive) VALUES('#{message}', ' ')");
	dbname=db.exec("INSERT INTO #{to_table}(receive, send) VALUES('#{message}', ' ')");

	redirect '/send_message'
end

get '/send_message' do
	# pg.exec("IF EXISTS (SELECT * FROM pg_table WHERE tablename=table_name_send)
				username = session[:username].to_s
				friend = session[:sendfriend].to_s
				from_table = "msg" + "_" + username + "_" + friend
		to_table = "msg" + "_" + friend + "_" + username

		friends_table = username + "_" + "friends"
		friends=db.exec("SELECT friends FROM #{friends_table}");
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
	friends=db.exec("SELECT friends FROM #{friends_table}");
	accounts=db.exec("SELECT full_name, username, password FROM accounts");
	erb :settings, locals: {username: session[:username], accounts: accounts, message1: session[:message_trash], friends: friends}
end

post '/settings' do
	session[:message_trash] = ""
	redirect '/settings'
end

post '/delete' do
	trash = params[:trash]
db.exec("DELETE FROM accounts WHERE username = '#{trash}' ");
	redirect '/'
end

post '/delete_friend' do
	username = session[:username].to_s
	friend_name = session
	trash = params[:trash_friend].to_s

	if friend_exist?(username, trash) == true
    		session[:message_trash] = 'This user has been removed from your friends list.'
			user_table = username + "_" + "friends"
			friend_table = trash + "_" + "friends"
			send_table = "msg" + "_" + username + "_" + trash
			receive_table = "msg" + "_" + trash + "_" + username
				db.exec("DELETE FROM #{user_table} WHERE friends = '#{trash}'")
				db.exec("DELETE FROM #{friend_table} WHERE friends = '#{username}'")
				db.exec("DROP TABLE IF EXISTS #{send_table}");
				db.exec("DROP TABLE IF EXISTS #{receive_table}");
	else		
    	session[:message_trash] = 'This user is not your friend.'
	end
	redirect '/settings'
end

post '/forgot_password' do
	redirect '/forgot_password'
end  

get '/forgot_password' do
	full_name = session[:full_name].to_s
	username = session[:username].to_s
	new_data = session[:new_password]
	old_data = session[:old_password]
	db.exec("UPDATE accounts SET password = '{new_data}' WHERE password ='{old_data}'")
	new_password = BCrypt::Password.create("#{session[:password]}")
	erb :forgot_password, locals: {full_name: session[:full_name], username: session[:username]}

end
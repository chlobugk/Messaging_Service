require 'sinatra'
require 'pg'
require 'scrypt'
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
	accounts=db.exec("SELECT full_name, username, password FROM accounts");
	erb :home
end

post '/login' do
	redirect '/login'
end

get '/login' do
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
	message1 = 'One or more of your credentials is invalid.'
	message2 = 'Please make sure your password is at least 6 character.'
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
			hashed_password = Scrypt::Password.create("#{password}")

			# db.exec("INSERT INTO accounts(full_name, username, password) VALUES('#{full_name}', '#{username}', '#{password}')")
			# accounts=db.exec("SELECT full_name, username, password FROM accounts");
			db.exec("INSERT INTO accounts(full_name, username, password) VALUES('#{full_name}', '#{username}', '#{hashed_password}')")
			session[:username] = username
			redirect 'message_home'
		end
end

post '/message_home' do
	session[:username] = params[:username]
	redirect '/message_home'
end

get '/message_home' do 
	messages=db.exec("SELECT user, friend, message, date_time FROM messages")
	erb :message, locals: {username: session[:username], messages: messages}
end

post '/addfriend' do
	friend_name = params[:friend_name].to_s
	username = params[:username].to_s
	table_name = "msg" + "_" + username + "_" + friend_name
	db.exec("CREATE TABLE #{table_name} (
	messageID	integer CONSTRAINT firstkey PRIMARY KEY,
    message     text
	)") 
	redirect '/message_home?username=' + username
	session[:username] = username
	redirect '/message_home'
end

get '/send_message' do
	redirect '/message_home'
end
 
post '/send_message' do
	username = session[:username]
	friendname = params [:friendname]
	message = params[:message]
	date = 'now'

	if username_not_unique(friendname) == true
		db.exec("INSERT INTO messages(user_name, friend, message, date_time) VALUES('#{username}', '#{friendname}', '#{message}', '#{date}')"); 
	end
	redirect '/message_home'
end
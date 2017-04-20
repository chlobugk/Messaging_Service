require 'sinatra'
require 'pg'
load './local_env.rb' if File.exists?('./local_env.rb')
db_params = {
    host: ENV['host'],
    port: ENV['port'],
    dbname: ENV['db_name'],
    user: ENV['user'],
    password: ENV['password']
}

db = PG::Connection.new(db_params)

get '/' do
	accounts=db.exec("SELECT full_name, username, password FROM accounts");
	erb :home
end

post '/login' do
	erb :login
end

post '/create_account' do
		session[:message] = nil
		erb :create_account, locals: {message: session[:message]}
end


post '/created' do
	accounts=db.exec("SELECT full_name, username, password FROM accounts");
		if accounts.include?(params[:username])
			session[:message] = 'Invalid'
			redirect '/create_account'
		else
		#this post adds created account info to database
		full_name = params[:full_name]
		username = params[:username]
		password = params[:password] 
		db.exec("INSERT INTO accounts(full_name, username, password) VALUES('#{full_name}', '#{username}', '#{password}')")
		erb :login
		end
end

post '/message' do
	username = params[:username]
	erb :message, locals: {username: username}
end


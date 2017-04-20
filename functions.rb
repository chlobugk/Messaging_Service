def valid_password?(password)
	password.to_s.length > 5
end

def valid_username?(username)
	username.to_s.length > 0
end

def valid_full_name?(full_name)
	full_name.to_s.include?(' ') && full_name.to_s.length > 1
end

def valid_credentials?(full_name, username, password)
	valid_full_name?(full_name) && valid_username?(username) && valid_password?(password)
end

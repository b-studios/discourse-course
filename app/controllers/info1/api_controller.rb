require_dependency 'pbkdf2'

class Info1::ApiController < Admin::AdminController

  def auth
    name = params[:user]
    password = params[:password]

    user = User.find_by_username name

    return fail if user.nil?

    entered = hash_password(password, user.salt)

    if entered == user.password_hash then
      render :json => { authenticated: true }
    else
      fail
    end
  end

  protected

  def fail
    render :json => { authenticated: false }
  end

  # Copied from User
  def hash_password(password, salt)
    raise "password is too long" if password.size > User.max_password_length
    Pbkdf2.hash_password(password, salt, Rails.configuration.pbkdf2_iterations, Rails.configuration.pbkdf2_algorithm)
  end

end

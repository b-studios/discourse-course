require_dependency 'pbkdf2'

class Course::ApiController < Admin::AdminController

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

  def dump
    render :json => {
      users: User.all.reject { |u| u.staff? }.map do |u|
        entry = {}
        members_mapping.each { |member| entry[member] = u.send member }
        user_fields_mapping.each { |id| entry[id] = user_field_by_id(u, id) }
        entry
      end
    }
  end

  protected

  # Returns a hash "configured user field identifier: => UserField.id"
  # If no custom identifier is provided the name of the user-field is used.
  def user_field_identifiers

    return @user_field_identifiers unless @user_field_identifiers.nil?

    mapping = SiteSetting.user_fields_mapping
      .split('|')
      .map { |f| f.split ':' }
      .map { |kv| kv.map {|x| x.strip } } # sanitize input
      .to_h

    @user_field_identifiers = UserField.all
      .map { |uf| [mapping[uf.name] || uf.name, uf.id] }
      .to_h
  end

  def user_field_by_id(user, id)
    user.user_fields[user_field_identifiers[id].to_s]
  end

  def members_mapping
    SiteSetting.export_user_members.split('|')
  end

  def user_fields_mapping
    SiteSetting.export_user_fields.split('|')
  end

  def fail
    render :json => { authenticated: false }
  end

  def lookupData(data, path)
    path.reduce(data) { |d, m| d.send(m) }
  end

  # Copied from User
  def hash_password(password, salt)
    raise "password is too long" if password.size > User.max_password_length
    Pbkdf2.hash_password(password, salt, Rails.configuration.pbkdf2_iterations, Rails.configuration.pbkdf2_algorithm)
  end

end

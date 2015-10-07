require_dependency 'pbkdf2'

class Course::ApiController < Admin::AdminController

  def auth
    name = params[:user]
    password = params[:password]

    user = User.find_by_username name

    return error("user not found") if user.nil?

    entered = hash_password(password, user.salt)

    if entered == user.password_hash then
      success
    else
      error("wrong password")
    end
  end

  def dump

    dumpStaff = (params[:staff] == "true") || false

    success({
      users: User.all.select { |u| u.staff? == dumpStaff }.map do |u|
        entry = {}
        members_mapping
          .select { |member| allowed_fields.include? member }
          .each { |member| entry[member] = u.send member }
        user_fields_mapping.each { |id| entry[id] = user_field_by_id(u, id) }
        entry
      end
    })
  end

  def set_user_field
    uf = params[:userfield]
    userid = params[:userid]
    value = params[:value]

    return error("provided user field not found") unless user_field_exists? uf

    return error("user not found") unless user = User.find_by_id(userid)

    return error("no value provided") if value.nil?

    user_field_key = "user_field_#{user_field_identifiers[uf]}"
    user.custom_fields[user_field_key] = value
    user.save!
    success
  end

  def set_user_fields
    data = params[:data]

    puts params.inspect
    #params[:page] = JSON.parse params[:page] if params[:page].is_a? String

    def read(entry)
      [entry[:userid], entry[:userfield], entry[:value]]
    end

    # 1. Step: Validation
    data.each do |entry|
      id, field, value = read entry
      return error("user field #{field} not found") unless user_field_exists? field
      return error("user #{id} not found") unless User.find_by_id id
      return error("no value provided for user #{id} and userfield #{field}") if value.nil?
    end

    # 2. Step: Data Update
    data.each do |entry|
      id, field, value = read entry
      user_field_key = "user_field_#{user_field_identifiers[field]}"
      user = User.find_by_id id
      user.custom_fields[user_field_key] = value
      user.save!
    end
    success
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
      .tap { |arr| break Hash[arr] } # since to_h is only available with 2.1.0

    @user_field_identifiers = UserField.all
      .map { |uf| [mapping[uf.name] || uf.name, uf.id] }
      .tap { |arr| break Hash[arr] }
  end

  def user_field_exists?(identifier)
    not identifier.nil? and not user_field_identifiers[identifier].nil?
  end

  def user_field_by_id(user, id)
    user.user_fields[user_field_identifiers[id].to_s]
  end

  def members_mapping
    SiteSetting.export_user_members.split('|')
  end

  def allowed_fields
    %w(id username name email active approved title updated_at)
  end

  def user_fields_mapping
    SiteSetting.export_user_fields.split('|')
  end

  def success(response = {})
    response["success"] = true
    render :json => response
  end

  def error(msg)
    render :json => { success: false, error: msg }
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

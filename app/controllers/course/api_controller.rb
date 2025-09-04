require_dependency 'pbkdf2'
require_dependency 'json'

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
    exported = params[:export] && JSON.parse(params[:export])
    dumpStaff = params[:staff] == "true"
    group = params[:group]
    confirmed = params[:confirmed] && JSON.parse(params[:confirmed])
    name = params[:user]

    user = User.find_by_username name

    exportedMembers = exported ? exported.select { |m| allowed_fields.include? m } : members_mapping
    exportedFields = exported ? exported - exportedMembers : user_fields_mapping

    selectedUsers =
      if user.nil?
        User.all.select { |u|
          u.staff? == dumpStaff &&
            (group.nil? || u.groups.map(&:name).include?(group)) &&
            (confirmed.nil? || all_confirmations_checked(u, confirmed))
        }
      else
        return error("user not found") unless user.staff? == dumpStaff

        [user]
      end

    success({
      users: selectedUsers.map do |u|
        entry = {}
        exportedMembers
          .select { |member| allowed_fields.include? member }
          .each { |member|
            entry[member] = render_user_member(member, u.send(member))
          }
        exportedFields.each { |id| entry[id] = user_field_by_id(u, id) }
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

  def synchronize_user_fields_and_groups
    username = params[:user]
    user = username && User.all.find{ |u| u.username == username }
    return error("user not found: #{username.inspect}") unless user
    active_groups = get_active_groups(fail_silently = false)
    if active_groups
      synchronize_groups_with_fields_of_user(active_groups, user)
      success({ username: user.username, groups: render_user_groups(user.groups) })
    end
  end

  def synchronize_all_user_fields_and_groups
    active_groups = get_active_groups(fail_silently = false)
    return unless active_groups
    users = User.all.select { |user|
      ! user.staff? &&
      synchronize_groups_with_fields_of_user(active_groups, user)
    }
    success({ modified_users: users.map(&:username) })
  end

  def add_people_to_default_lecture_group
    default_group = Group.all.find{ |g| default_lecture_group == g.name }
    active_groups = active_lecture_groups
    users = User.all.select { |user|
      ! user.staff? &&
      ! some_confirmations_checked(user, active_groups) &&
      ! user.groups.include?(default_group)
    }

    users.each { |user|
      user.groups << default_group
      user.save!
    }

    success({ modified_users: users.map(&:username) })
  end

  protected

  # Returns a hash "configured user field identifier: => UserField.id"
  # If no custom identifier is provided the name of the user-field is used.
  def user_field_identifiers

    return @user_field_identifiers unless @user_field_identifiers.nil?

    mapping = setting_to_list(SiteSetting.user_fields_mapping)
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
    setting_to_list(SiteSetting.export_user_members)
  end

  def allowed_fields
    %w(id username name email active approved title updated_at groups)
  end

  def user_fields_mapping
    setting_to_list(SiteSetting.export_user_fields)
  end

  # get actively maintained lecture user groups.
  # unless failure is silent (default behavior),
  # render error if plugin setting and user groups are inconsistent,
  # and return nil.
  def get_active_groups(fail_silently = true)
    active_group_names = active_lecture_groups
    result = Group.all.select { |g| active_group_names.include? g.name }
    if fail_silently
      result
    elsif result.size == active_group_names.size
      # result is sane
      result
    else
      # result is insane
      error("incongruent configuration: " +
            "plugin settings = #{active_group_names.inspect}, " +
            "valid user groups among them = #{result.map(&:name).to_a.inspect}")
      nil
    end
  end

  def setting_to_list(setting)
    setting.split('|')
  end

  def success(response = {})
    response["success"] = true
    render :json => JSON.pretty_generate(response)
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

  # convert user member to JSON according to its name
  def render_user_member(member, value)
    if member == "groups"
      render_user_groups(value)
    else
      value
    end
  end

  # convert ActiveRecord user.groups to array of group names
  def render_user_groups(groups)
    groups.map(&:name).as_json
  end

  # returns whether a user checked all named confirmation checkboxes
  def all_confirmations_checked(user, confirmed)
    confirmed.map{ |checkboxName| confirmed?(user, checkboxName) }.inject(:&)
  end

  # returns whether a user checked one named confirmation checkboxes
  def some_confirmations_checked(user, confirmed)
    confirmed.map{ |checkboxName| confirmed?(user, checkboxName) }.inject(:|)
  end

  def confirmed?(user, checkboxName)
    value = user_field_by_id(user, checkboxName)
    ! (value.nil? || value.empty?)
  end

  # set groups membership according to user fields matching `active_groups
  def synchronize_groups_with_fields_of_user(groups, user)
    modified = false
    groups.each do |group|
      if confirmed?(user, group.name)
        unless user.groups.include?(group)
          user.groups << group
          modified = true
        end
      else
        if user.groups.include?(group)
          user.groups.delete(group)
          modified = true
        end
      end
    end
    user.save!
    modified
  end

  def active_lecture_groups
    setting_to_list(SiteSetting.active_lecture_groups)
  end

  # the user group to give people not subscribed to any lecture
  def default_lecture_group
    SiteSetting.default_lecture_group
  end
end

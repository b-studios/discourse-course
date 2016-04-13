# name: course
# about: A plugin to use Discourse as auth provider
# version: 0.0.2
# authors: Jonathan Brachthäuser

require_relative 'lib/course'

Discourse::Application.routes.append do
  post '/admin/course/auth' => 'course/api#auth'
  get  '/admin/course/dump' => 'course/api#dump'
  put '/admin/course/user_field' => 'course/api#set_user_field'
  put '/admin/course/user_fields' => 'course/api#set_user_fields'

  # Synchronize fields and groups for a single user for debugging,
  # hence GET. Webhooks will use POST, to be handled by another method.
  get '/admin/course/synchronize_user_fields_and_groups' => 'course/api#synchronize_user_fields_and_groups'

  # Give all users not subscribed to any lecture
  # the group `SiteSetting.default_lecture_group`
  get '/admin/course/add_people_to_default_lecture_group' => 'course/api#add_people_to_default_lecture_group'
end

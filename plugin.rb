# name: course
# about: A plugin to use Discourse as auth provider
# version: 0.0.1
# authors: Jonathan Brachthäuser

require_relative 'lib/course'

Discourse::Application.routes.append do
  get '/admin/course/auth' => 'course/api#auth'
  get '/admin/course/dump' => 'course/api#dump'
end

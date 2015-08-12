# name: info1
# about: A plugin to use Discourse as auth provider
# version: 0.0.1
# authors: Jonathan Brachthäuser

require_relative 'lib/info1'

Discourse::Application.routes.append do
  get '/admin/info1/auth' => 'info1/api#auth'
end

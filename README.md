# discourse-course
Plugin to use discourse as primitive authentication provider and to export selected user data

This plugin adds two new API methods that can be used to interact with discourse as central user database. Both require an admin user API token.

## Authenticate User
~~~
GET /admin/course/auth.json
~~~

#### Parameters
- user
- password

#### Returns
~~~
{ authenticated: Boolean }
~~~

## Dump Userdata
~~~
GET /admin/course/dump.json
~~~

#### Parameters
None

#### Returns
~~~
{ users: [USER] }
~~~

Here the information contained in the object USER can be configured in the admin area of discourse under "Settings/Plugins".

You can explore the available fields and methods on `User` in the discourse implementation [user.rb](https://github.com/discourse/discourse/blob/master/app/models/user.rb).

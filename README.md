# discourse-course
Plugin to use discourse as primitive authentication provider and to export selected user data

This plugin adds two new API methods that can be used to interact with discourse as central user database. Both require an admin user API token.

## Authenticate User
~~~
GET /admin/course/auth
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
GET /admin/course/dump
~~~

#### Parameters
None

#### Returns
~~~
{ users: [USER] }
~~~

Here the information contained in the object USER can be configured by editing [config.yml](https://github.com/b-studios/discourse-course/blob/master/config/configs.yml).
Each entry in the section `members` defines a property of `USER` by querying the user-object using the provided "path". A path consists of accessor methods called on the user object. For instance the entry:

~~~
www:
  - user_profile
  - website
~~~
will translate into the method calls `@user.user_profile.website` and bind the result to the property `www` in the json-output.

You can explore the available fields and methods on `User` in the discourse implementation [user.rb](https://github.com/discourse/discourse/blob/master/app/models/user.rb).

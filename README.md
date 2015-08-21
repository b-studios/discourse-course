# discourse-course
Plugin to use discourse as primitive authentication provider and to export selected user data

This plugin adds three new API methods that can be used to interact with discourse as central user database. All of them require an admin user API token.

#### General Output
All API methods return a boolean flag that indicates the success of the method call:
~~~
{ success: Boolean, error: String, ... }
~~~

The optional field `error` explains the failure in case `success == false`.

## Authenticate User
~~~
POST /admin/course/auth.json
~~~

#### Parameters
- user
- password

#### Additional Output
None

## Dump Userdata
~~~
GET /admin/course/dump.json
~~~

#### Parameters
None

#### Additional Output
~~~
{ users: [USER] }
~~~

Here the information contained in the object USER can be configured in the admin area of discourse under "Settings/Plugins".

You can explore the available fields and methods on `User` in the discourse implementation [user.rb](https://github.com/discourse/discourse/blob/master/app/models/user.rb).

## Set User Field
~~~
PUT /admin/course/user_field.json
~~~

#### Parameters
- userid
- userfield
- value

`userfield` is either the name of the userfield to set a value or a custom identifier, configured under "Settings/Plugins".

#### Additional Output
None

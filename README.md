# discourse-course
Plugin to use discourse as primitive authentication provider and to export selected user data

This plugin adds a couple of new API methods that can be used to interact with discourse as central user database. All of them require an admin user API token.

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
Dumps the userdata together with customized user-fields. The flag `staff` can
be used to indicate whether only students or only staff should be dumped.
Right now it is not possible to dump both at the same time.

#### Parameters
- staff: Boolean (Defaults to `false`)

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

## Set User Fields
~~~
PUT /admin/course/user_fields.json
~~~

#### Parameters
- { data: [USER_FIELD_UPDATE] }

where

~~~
USER_FIELD_UPDATE = {
  userid: Number,
  userfield: String,
  value: String
}
~~~

It is important that the following headers are set in your request:

~~~
Content-Type: application/json
Accept: application/json
~~~

For instance when using `curl`:
~~~
url -X PUT -H 'Accept: application/json' -H 'Content-type: application/json' -d '{ "data" : [{ "userid": 1, ...}] }' '<URL>/admin/course/user_fields.json?api_key=<API_KEY>&api_username=<USERNAME>'
~~~

For possible values of `USER_FIELD_UPDATE` properties see "Set User Field". Updating

#### Additional Output
None

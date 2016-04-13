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
- export: [String] (Exported members and fields of `USER`, e.g., `["username","info1"]`.
  Defaults to `SiteSetting.export_user_members.split('|')`.)
- staff: Boolean (Select by `user.staff`. Defaults to `false`.)
- group: String (Select members of named group. Defaults to `nil`.)
- confirmed: [String] (Select by checked confirmation user fields. Defaults to `nil`.)

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


## Add People to Default Lecture Group
~~~
GET /admin/course/add_people_to_default_lecture_group.json
~~~

For all non-staff users not belonging to any active lecture, add them to the default lecture group.

#### Parameters

None

#### Additional Output

List of usernames newly added to default lecture group


## Synchronize Fields and Groups for All Users
~~~
GET /admin/course/synchronize_all_user_fields_and_groups.json
~~~

For all non-staff users, set their membership in active lecture groups according to the corresponding user fields.

#### Parameters

None

#### Additional Output

List of usernames whose user groups are modified by the command

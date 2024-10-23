import gleam/dynamic
import gleam/json
import gleam/result

pub type AddUserInfo {
  UserInfo(username: String, did_string: String)
}

pub fn user_info_from_json(json_string: String) -> AddUserInfo {
  let user_info_decoder =
    dynamic.decode2(
      UserInfo,
      dynamic.field("username", of: dynamic.string),
      dynamic.field("did_string", of: dynamic.string),
    )

  json.decode(json_string, user_info_decoder)
  |> result.unwrap(UserInfo("", ""))
}

pub type Password {
  Password(password: String)
}

pub fn password_from_json(json_string: String) -> Password {
  let password_decoder =
    dynamic.decode1(Password, dynamic.field("password", of: dynamic.string))

  json.decode(json_string, password_decoder)
  |> result.unwrap(Password(password: ""))
}

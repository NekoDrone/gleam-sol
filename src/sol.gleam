import cors_builder as cors
import db/postgres
import envoy
import func/env
import func/github_api
import func/json_helper
import gleam/bit_array
import gleam/bytes_builder
import gleam/erlang/process
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
import gleam/json
import gleam/list
import gleam/pgo
import gleam/result
import gleam/string
import mist.{type Connection, type ResponseData}

pub fn main() {
  env.env_config()
  let db = postgres.setup_db()

  let not_found =
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_builder.new()))

  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      use req <- cors.mist_middleware(req, cors())
      case request.path_segments(req) {
        [".well-known", "atproto-did"] -> get_atproto_did(req, db)
        ["add_user"] -> add_user(req, db)
        ["verify_password"] -> verify_password(req)
        ["last_updated"] -> last_updated()
        [] -> redirect_to_profile(req)
        _ -> not_found
      }
    }
    |> mist.new
    |> mist.port(8080)
    |> mist.bind("0.0.0.0")
    |> mist.start_http

  process.sleep_forever()
}

fn cors() {
  cors.new()
  |> cors.allow_origin("http://localhost:3000")
  |> cors.allow_origin("https://tgirl.gay")
  |> cors.allow_header("content-type")
  |> cors.allow_header("origin")
  |> cors.allow_header("")
  |> cors.allow_method(http.Get)
  |> cors.allow_method(http.Post)
}

fn get_atproto_did(
  request: Request(Connection),
  db: pgo.Connection,
) -> Response(ResponseData) {
  let username =
    request.host
    |> string.split(".")
    |> list.first
    |> result.unwrap("nil")

  let did = postgres.find_did_from_user(username, db) |> result.unwrap("")

  case did {
    "" ->
      response.new(200)
      |> response.set_body(mist.Bytes(bytes_builder.from_string(username)))
    _ ->
      response.new(200)
      |> response.set_body(
        mist.Bytes(bytes_builder.from_string("did:plc:" <> did)),
      )
      |> response.set_header("content-type", "text/plain")
  }
}

fn add_user(
  request: Request(Connection),
  db: pgo.Connection,
) -> Response(ResponseData) {
  mist.read_body(request, 1024 * 1024 * 10)
  |> result.map(fn(req) {
    let user_info =
      json_helper.user_info_from_json(
        bit_array.to_string(req.body) |> result.unwrap(""),
      )
    case postgres.add_user_to_db(user_info, db) {
      Ok(_) -> {
        response.new(200)
        |> response.set_body(mist.Bytes(bytes_builder.new()))
      }
      Error(_) -> {
        response.new(400)
        |> response.set_body(mist.Bytes(bytes_builder.new()))
      }
    }
  })
  |> result.lazy_unwrap(fn() {
    response.new(400)
    |> response.set_body(mist.Bytes(bytes_builder.new()))
  })
}

fn verify_password(request: Request(Connection)) -> Response(ResponseData) {
  mist.read_body(request, 1024 * 1024 * 10)
  |> result.map(fn(req) {
    let password_from_req =
      json_helper.password_from_json(
        bit_array.to_string(req.body)
        |> result.unwrap(""),
      )
    let password_from_env =
      envoy.get("VERIFICATION_PASSWORD")
      |> result.unwrap("")
    case
      password_from_env != "" && password_from_env == password_from_req.password
    {
      True -> {
        response.new(200)
        |> response.set_body(mist.Bytes(bytes_builder.new()))
      }
      False -> {
        response.new(401)
        |> response.set_body(mist.Bytes(bytes_builder.new()))
      }
    }
  })
  |> result.lazy_unwrap(fn() {
    response.new(400)
    |> response.set_body(mist.Bytes(bytes_builder.new()))
  })
}

fn last_updated() -> Response(ResponseData) {
  let latest_commit_data = github_api.fetch_latest_commit()

  let json_data =
    json.object([#("updated", json.string(latest_commit_data.author.date))])

  response.new(200)
  |> response.set_body(
    mist.Bytes(bytes_builder.from_string(json.to_string(json_data))),
  )
  |> response.set_header("content-type", "application/json")
}

fn redirect_to_profile(request: Request(Connection)) -> Response(ResponseData) {
  let target_url = "https://bsky.app/profile/" <> request.host

  response.new(302)
  |> response.prepend_header("location", target_url)
  |> response.set_body(
    mist.Bytes(bytes_builder.from_string(
      "You are being redirected to " <> target_url,
    )),
  )
}

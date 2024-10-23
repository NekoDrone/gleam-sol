import db/postgres
import func/env
import func/json_helper
import gleam/bit_array
import gleam/bytes_builder
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
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
      case request.path_segments(req) {
        [".well-known", "atproto-did"] -> get_atproto_did(req, db)
        ["add_user"] -> add_user(req, db)
        _ -> not_found
      }
    }
    |> mist.new
    |> mist.port(8080)
    |> mist.start_http

  process.sleep_forever()
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
        mist.Bytes(bytes_builder.from_string("did=did:plc:" <> did)),
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

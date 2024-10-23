import db/postgres
import func/env
import gleam/bytes_builder
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/list
import gleam/result
import gleam/string
import mist.{type Connection, type ResponseData}

pub fn main() {
  env.env_config()
  let _db = postgres.setup_db()

  let not_found =
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_builder.new()))

  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      case request.path_segments(req) {
        [".well-known", "atproto-did"] -> get_atproto_did(req)
        _ -> not_found
      }
    }
    |> mist.new
    |> mist.port(3000)
    |> mist.start_http

  process.sleep_forever()
}

fn get_atproto_did(request: Request(Connection)) -> Response(ResponseData) {
  let username =
    request.host
    |> string.split(".")
    |> list.first
    |> result.unwrap("nil")

  let did = postgres.find_did_from_user(username) |> result.unwrap("")

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

import db/postgres
import gleam/bytes_builder
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/list
import gleam/result
import gleam/string
import mist.{type Connection, type ResponseData}

pub fn main() {
  let _db = postgres.setup_db()

  let not_found =
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_builder.new()))

  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      case request.path_segments(req) {
        ["echo"] -> echo_body(req)
        ["hello"] -> hello_sol(req)
        ["get_uri"] -> get_uri(req)
        [".well-known/atproto-did"] -> get_atproto_did(req)
        _ -> not_found
      }
    }
    |> mist.new
    |> mist.port(3000)
    |> mist.start_http

  process.sleep_forever()
}

fn echo_body(request: Request(Connection)) -> Response(ResponseData) {
  let content_type =
    request
    |> request.get_header("content-type")
    |> result.unwrap("text/plain")

  mist.read_body(request, 1024 * 1024 * 10)
  |> result.map(fn(req) {
    response.new(200)
    |> response.set_body(mist.Bytes(bytes_builder.from_bit_array(req.body)))
    |> response.set_header("content-type", content_type)
  })
  |> result.lazy_unwrap(fn() {
    response.new(400)
    |> response.set_body(mist.Bytes(bytes_builder.new()))
  })
}

fn hello_sol(request: Request(Connection)) -> Response(ResponseData) {
  let content_type =
    request
    |> request.get_header("content-type")
    |> result.unwrap("text/plain")

  response.new(200)
  |> response.set_body(mist.Bytes(bytes_builder.from_string("Hi from Sol!")))
  |> response.set_header("content-type", content_type)
}

fn get_uri(request: Request(Connection)) -> Response(ResponseData) {
  let content_type = "text/plain"

  response.new(200)
  |> response.set_body(mist.Bytes(bytes_builder.from_string(request.host)))
  |> response.set_header("content-type", content_type)
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
      response.new(404)
      |> response.set_body(mist.Bytes(bytes_builder.new()))
    _ ->
      response.new(200)
      |> response.set_body(mist.Bytes(bytes_builder.from_string(did)))
      |> response.set_header("content-type", "text/plain")
  }
}

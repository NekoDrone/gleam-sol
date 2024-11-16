import envoy
import gleam/dynamic
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/list
import gleam/result

pub type ApiResponse {
  ApiResponse(List(ResponseData))
}

pub fn api_response_decoder(data: dynamic.Dynamic) {
  dynamic.list(response_data_decoder)(data)
}

pub type ResponseData {
  ResponseData(sha: String, commit: CommitData)
}

pub fn response_data_decoder(data: dynamic.Dynamic) {
  dynamic.decode2(
    ResponseData,
    dynamic.field("sha", of: dynamic.string),
    dynamic.field("commit", of: commit_data_decoder),
  )(data)
}

pub type CommitData {
  CommitData(author: AuthorData, committer: AuthorData, message: String)
}

pub fn commit_data_decoder(data: dynamic.Dynamic) {
  dynamic.decode3(
    CommitData,
    dynamic.field("author", of: author_data_decoder),
    dynamic.field("committer", of: author_data_decoder),
    dynamic.field("message", of: dynamic.string),
  )(data)
}

pub type AuthorData {
  AuthorData(name: String, email: String, date: String)
}

pub fn author_data_decoder(data: dynamic.Dynamic) {
  dynamic.decode3(
    AuthorData,
    dynamic.field("name", of: dynamic.string),
    dynamic.field("email", of: dynamic.string),
    dynamic.field("date", of: dynamic.string),
  )(data)
}

pub fn fetch_latest_commit() -> CommitData {
  let github_api_key =
    envoy.get("GITHUB_API_KEY")
    |> result.unwrap("")

  let frontend_repo_path =
    envoy.get("FRONTEND_REPO_PATH")
    |> result.unwrap("")

  let assert Ok(base_req) =
    request.to(
      "https://api.github.com/repos/"
      <> frontend_repo_path
      <> "/commits?per_page=1",
    )

  let req =
    request.set_header(base_req, "accept", "application/vnd.github+json")
    |> request.set_header("Authorization", "Bearer " <> github_api_key)

  let assert Ok(resp) = httpc.send(req)

  let assert Ok(api_response) = resp.body |> json.decode(api_response_decoder)

  let assert Ok(response_data) = list.first(api_response)

  response_data.commit
}

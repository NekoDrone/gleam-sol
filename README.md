# sol

A stellar verification server written in Gleam.

Sol, because the sun gleams in the blue sky.

## What is this for?

Sol is a verification service written in [Gleam](https://gleam.run) (because our sun, Sol, gleams in the blue sky) that allows users to register their own domains and subdomains.

The [AT Protocol](https://atproto.com/), written by the [Bluesky](https://bsky.social) team, allows for different subdomains to be verified within the atproto federation.

In the Bluesky app, you may self-register the root subdomain (`example.com`) for a given domain name by inserting a DNS record on your domain, which returns a given DID. This works fine for the majority of users.

However, in order to register other subdomains (`user1.example.com`) for yourself, a group, or collective under a given domain, there are two methods.

The first is to add a DNS record for each account in the subdomain at the host `_atproto.<user>` where you would normally simply add `_atproto`. (`_atproto.user1`) For some DNS providers, this approach would quickly reach the limit of available DNS records on the domain.

The second is to provide a `.well-known/atproto-did` route to the given handle's subdomain. (`https://user1.example.com/.well-known/atproto-did`). This must then return a DID of the account with the content type `text/plain`.

Sol provides both the backend service for Bluesky or any other atproto application to visit and verify DIDs, as well as the frontend for adding new handles and DIDs.

If you're looking for a simpler solution instead of self-hosting, please take a look at [Skyname](https://github.com/darnfish/skyname), or use the service at [skyna.me](https://skyna.me).

## Requirements

1. Git
2. [Gleam](https://gleam.run)
3. Your own domain for use with the [AT Protocol](https://atproto.com/)

## Usage

1. Clone this repository on a public cloud service.
2. Populate the configs at [WIP]
3. Run the server.
4. You may access the frontend at `<url route>/sol` where `<url-route>` is wherever you host your cloud service, or the domain that you own if you have configured your DNS as such.

```sh
git clone https://github.com/NekoDrone/gleam-sol.git
cd gleam-sol
gleam run sol
```

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## License

BSD-3-Clause
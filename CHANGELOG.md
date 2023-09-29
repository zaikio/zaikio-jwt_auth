# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

* Fix: support `token_data.to_s` when using mocked JWTs

## [2.8.0] - 2023-09-29

* Add convenient method `token_data.to_s` to get the current token as string.

## [2.7.0] - 2023-07-03

* Handle errors when fetching the directory cache and fallback to API

## [2.6.0] - 2023-06-05

* Support on behalf access tokens when `authorize_by_jwt_subject_type "Person"`

## [2.5.0] - 2023-05-11

* Accept `zaikio.revoked_access_token` event when access token got revoked

## [2.4.1] - 2023-05-08

* Support multiple apps in one controller

## [2.4.0] - 2023-03-27

* Do not schedule `Cache::UpdateJob` for waiting time as it is not supported by every ActiveJob Queue Adapater (such as sneakers)

## [2.3.0] - 2023-02-09

* Add more detailed information to error responses
* Fix `NoMethodError: undefined method '[]' for nil` when Directory cache is unavailable
* Ensure callers handle `DirectoryCache.fetch` returning nil

## [2.2.0] - 2022-09-28

* Added rack Middleware for rack-attack throttling

## [2.1.1] - 2022-09-06

* Mocked JWTs now contain actual random UUIDs instead of a fixed string

## [2.1.0] - 2022-08-02

* Added support for `jwt_options` in controller to customize JWT options

## [2.0.0] - 2022-04-29

* **BREAKING** `config.redis` has been replaced with `config.cache`, replacing the
  direct Redis dependency with an instance of a `ActiveSupport::Cache::Store`. If you
  wish to keep using Redis, you should wrap it like so:

```diff
-config.redis = Redis.new
+config.cache = ActiveSupport::Cache::RedisCacheStore.new
```

  Alternatively, you can also use `Rails.cache` to use a different backend:

```diff
-config.redis = Redis.new
+config.cache = Rails.cache
```

## [1.0.2] - 2022-04-21

* After setting `authorize_by_jwt_subject_type` and `authorize_by_jwt_scopes` in a
  controller, any classes inheriting from your controller will also get a copy of those
  attributes. You can override this behaviour by calling the methods again in the child
  class.

## [1.0.1] - 2021-04-28

* Bugfix: add runtime dependency `activejob` for rebuilding the `DirectoryCache`

## [1.0.0] - 2021-04-23

* **BREAKING** When updating the `DirectoryCache` (either using `invalidate: true` or when
  the cache expires), it will no longer retry & sleep, blocking the main thread.
  Instead, it enqueues a background job to attempt the update (and will re-queue again, if
  needed, until the job succeeds.

## [0.5.1] - 2021-04-21

* Set correct `use_ssl` flag on `net/http` when working with HTTPS

## [0.5.0] - 2021-04-21

* Throw a `Zaikio::JWTAuth::DirectoryCache::BadResponseError` when the server returns with
  an unexpected HTTP 4xx error code or non-JSON body.

### [0.4.4] - 2020-03-25

 * Replace dependency on `rails` with a more specific dependency on `railties`

### [0.4.3] - 2020-03-17

* Fix incorrect const_defined? behaviour when initializing without zaikio-webhooks gem

### [0.4.2] - 2020-02-18
* Add authorization for custom actions and scope types

### [0.4.1] - 2020-01-15

* Add a changelog
* Setup automated gem publishing

[Unreleased]: https://github.com/zaikio/zaikio-directory-models/compare/v2.8.0...HEAD
[2.8.0]: https://github.com/zaikio/zaikio-directory-models/compare/v2.7.0...v2.8.0
[2.7.0]: https://github.com/zaikio/zaikio-directory-models/compare/v2.7.0...v2.7.0
[2.6.0]: https://github.com/zaikio/zaikio-directory-models/compare/v2.5.0...v2.6.0
[2.5.0]: https://github.com/zaikio/zaikio-directory-models/compare/v2.4.1...v2.5.0
[2.4.1]: https://github.com/zaikio/zaikio-directory-models/compare/v2.4.0...v2.4.1
[2.4.0]: https://github.com/zaikio/zaikio-directory-models/compare/v2.3.0...v2.4.0
[2.3.0]: https://github.com/zaikio/zaikio-directory-models/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/zaikio/zaikio-directory-models/compare/v2.1.1...v2.2.0
[2.1.1]: https://github.com/zaikio/zaikio-directory-models/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/zaikio/zaikio-directory-models/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/zaikio/zaikio-directory-models/compare/v1.0.2...v2.0.0
[1.0.2]: https://github.com/zaikio/zaikio-directory-models/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/zaikio/zaikio-directory-models/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/zaikio/zaikio-directory-models/compare/v0.5.1...v1.0.0
[0.5.1]: https://github.com/zaikio/zaikio-directory-models/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/zaikio/zaikio-directory-models/compare/v0.4.4...v0.5.0
[0.4.4]: https://github.com/zaikio/zaikio-directory-models/compare/v0.4.3...v0.4.4
[0.4.3]: https://github.com/zaikio/zaikio-directory-models/compare/v0.4.2...v0.4.3
[0.4.2]: https://github.com/zaikio/zaikio-directory-models/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/zaikio/zaikio-directory-models/compare/d601d8c2f5c68f9c440755a8fbf9e17b4ae79a66...v0.4.1

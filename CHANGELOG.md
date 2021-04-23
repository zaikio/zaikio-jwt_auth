# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/zaikio/zaikio-directory-models/compare/v0.5.1...HEAD
[0.5.1]: https://github.com/zaikio/zaikio-directory-models/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/zaikio/zaikio-directory-models/compare/v0.4.4...v0.5.0
[0.4.4]: https://github.com/zaikio/zaikio-directory-models/compare/v0.4.3...v0.4.4
[0.4.3]: https://github.com/zaikio/zaikio-directory-models/compare/v0.4.2...v0.4.3
[0.4.2]: https://github.com/zaikio/zaikio-directory-models/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/zaikio/zaikio-directory-models/compare/d601d8c2f5c68f9c440755a8fbf9e17b4ae79a66...v0.4.1

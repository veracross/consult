#### Unreleased

#### 1.0.0

* Stop with error when force rendering and no template is found
* Remove non-functional short verbosity argument
* Add `--version` option to show the version
* Better logging for template rendering status, errors, and config (verbose mode)
* Development: adjust require's to be able to run CLI from any folder
* Enable defining vars at the env block level, rather than only on template blocks
* Create directories for rendered files as needed

#### 0.11.0

* Enable support for Ruby 3.1 ([#36](https://github.com/veracross/consult/pull/36))
* Bump Diplomat version & better testing for default parameters ([#37](https://github.com/veracross/consult/pull/37) & [#39](https://github.com/veracross/consult/pull/39))
* Avoid loading Railtie if SKIP_CONSULT is truthy ([#40](https://github.com/veracross/consult/pull/40))

#### 0.10.0

* Switch from Travis to CircleCI, and set up testing for multiple Ruby versions ([#25](https://github.com/veracross/consult/pull/25) & [#34](https://github.com/veracross/consult/pull/34))
* Improve development on Windows ([#21](https://github.com/veracross/consult/pull/21))
* Normalize string encodings to UTF-8 ([#22](https://github.com/veracross/consult/pull/22))
* Remove dependency on ActiveSupport ([#27](https://github.com/veracross/consult/pull/27))

#### 0.9.0

* Add a CLI to render templates on demand ([#20](https://github.com/veracross/consult/pull/20))

#### 0.8.2

* Use `X-Consul-Token` header for Consul authentication. See the [Consul docs](https://www.consul.io/api/index.html#authentication) for details. ([#19](https://github.com/veracross/consult/pull/19))

#### 0.8.1

* Obey template location order as specified in consult's config

#### 0.8.0

* Add support for multiple sources for a single template ([#14](https://github.com/veracross/consult/pull/14))
* Add support for Consul-sourced templates ([#15](https://github.com/veracross/consult/pull/15))
* Don't crash on rendering errors ([#16](https://github.com/veracross/consult/pull/16))

#### 0.7.3

* Add `key` function to templates to pull kv data from Consul
* Relax Vault gem dependency to unblock upstream upgrades

#### 0.7.2

* Fix reading Rails.env

#### 0.7.1

* Redeploy while diagnosing gem installation problem

#### 0.7.0

* `consult.yml` configuration structure has changed, to enable environment specific configuration blocks (see readme for example)
* Improve safety around edge cases

#### 0.6.0

* Fixed tests to account for versioned key-value stores in Vault 0.10+

#### 0.5.0

Initial release.

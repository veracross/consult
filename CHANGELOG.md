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

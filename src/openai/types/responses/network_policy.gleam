import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

pub type NetworkPolicy {
  NetworkPolicyDisabled
  // type: "disabled"
  NetworkPolicyAllowList(AllowList)
}

pub fn encode_network_policy(network_policy: NetworkPolicy) -> Json {
  case network_policy {
    NetworkPolicyDisabled -> json.object([#("type", json.string("disabled"))])
    NetworkPolicyAllowList(allow_list) ->
      json.object([
        #("type", json.string("allowlist")),
        #(
          "allowed_domains",
          json.array(allow_list.allowed_domains, json.string),
        ),
        #("domain_secrets", case allow_list.domain_secrets {
          Some(secrets) ->
            json.array(secrets, encode_container_network_policy_domain_secret)
          None -> json.null()
        }),
      ])
  }
}

pub fn decode_network_policy() -> Decoder(NetworkPolicy) {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "disabled" -> decode.success(NetworkPolicyDisabled)
    "allowlist" ->
      decode_allow_list() |> decode.map(NetworkPolicyAllowList)
    _ -> panic as "network_policy.decode_network_policy"
  }
}

pub type AllowList {
  AllowList(
    /// A list of allowed domains when type is allowlist.
    allowed_domains: List(String),
    // type: "allowlist"
    /// Optional domain-scoped secrets for allowlisted domains.
    domain_secrets: Option(List(ContainerNetworkPolicyDomainSecret)),
  )
}

pub type ContainerNetworkPolicyDomainSecret {
  ContainerNetworkPolicyDomainSecret(
    /// The domain associated with the secret.
    /// minLength1
    domain: String,
    /// The name of the secret to inject for the domain.
    /// minLength1
    name: String,
    /// The name of the secret to inject for the domain.
    /// minLength1
    value: String,
  )
}

fn decode_allow_list() -> Decoder(AllowList) {
  use allowed_domains <- decode.field(
    "allowed_domains",
    decode.list(decode.string),
  )
  use domain_secrets <- decode.optional_field(
    "domain_secrets",
    None,
    decode.optional(decode.list(decode_container_network_policy_domain_secret())),
  )
  decode.success(AllowList(allowed_domains:, domain_secrets:))
}

fn encode_container_network_policy_domain_secret(
  domain_secret: ContainerNetworkPolicyDomainSecret,
) -> Json {
  json.object([
    #("domain", json.string(domain_secret.domain)),
    #("name", json.string(domain_secret.name)),
    #("value", json.string(domain_secret.value)),
  ])
}

fn decode_container_network_policy_domain_secret(
) -> Decoder(ContainerNetworkPolicyDomainSecret) {
  use domain <- decode.field("domain", decode.string)
  use name <- decode.field("name", decode.string)
  use value <- decode.field("value", decode.string)
  decode.success(ContainerNetworkPolicyDomainSecret(domain:, name:, value:))
}

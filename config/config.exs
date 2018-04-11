use Mix.Config

config :logger, backends: [RingLogger]
config :logger, RingLogger, max_size: 200

config :shoehorn,
  init: [:nerves_runtime, :nerves_init_gadget],
  app: Mix.Project.config()[:app]

key_mgmt = System.get_env("NERVES_NETWORK_KEY_MGMT") || "WPA-PSK"

config :nerves_network, :default, wlan0: [
    ssid: System.get_env("NERVES_NETWORK_SSID"),
    psk: System.get_env("NERVES_NETWORK_PSK"),
    key_mgmt: String.to_atom(key_mgmt)
  ]

config :nerves_init_gadget,
  ifname: "wlan0",
  address_method: :dhcp,
  mdns_domain: "nerves.local",
  node_name: nil,
  node_host: :mdns_domain

config :scanner,
  wunderlist_access_key: System.get_env("WUNDERLIST_ACCESS_KEY"),
  wunderlist_client_id: System.get_env("WUNDERLIST_CLIENT_ID"),
  upcdatabase_access_jey: System.get_env("UPCDATABASE_ACCESS_KEY")

config :nerves_firmware_ssh,
  authorized_keys: [File.read!(Path.join(System.user_home!, ".ssh/id_rsa.pub"))]

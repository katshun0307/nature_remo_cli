defmodule NatureRemoCli.Api do
  @token Application.fetch_env!(:nature_remo_cli, :token)

  def client() do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.nature.global/1"},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers,
       [
         {"Content-type", "application/json"},
         {"Authorization", "Bearer #{@token}"}
       ]}
    ]

    adapter = {Tesla.Adapter.Hackney, [recv_timeout: 30_000]}

    Tesla.client(middleware, adapter)
  end

  def get_devices(client) do
    Tesla.get(client, "/devices")
  end

  def control_ac(client, nickname, settings) do
    get_appliances(client)
    |> find_appliance(%{"nickname" => nickname})
    |> Map.fetch!("id")
    |> control_ac(client, settings)
  end

  def get_appliances(client) do
    Tesla.get(client, "/appliances")
  end

  def get_signals(client, appliance_id) do
    Tesla.get(client, "/appliances/#{appliance_id}/signals")
  end

  def post_control_ac(client, ac_id, settings) do
    # settings include: temperature, operation_mode, air_volume, air_direction, button

    Tesla.post(
      client,
      "appliances/#{ac_id}/aircon_settings",
      settings
    )
  end

  def find_appliance(appliances, %{} = query) do
    appliances |> Enum.find(&query_appliance_flag(&1, query))
  end

  defp query_appliance_flag(appliance, query) do
    query
    |> Enum.all?(fn {k, v} -> appliance[k] == v end)
  end
end

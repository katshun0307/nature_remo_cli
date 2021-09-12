defmodule NatureRemoCli.Interface.SensorComponent do
  import Ratatouille.View

  alias NatureRemoCli.Api

  @sensor_measurement_names %{
    "hu" => {"humidity", "%"},
    "te" => {"temperature", "℃"},
    "mo" => {"motion", ""},
    "il" => {"illumination", ""}
  }

  def assign(%{client: client} = model) do
    with {:ok, %{body: devices}} <- Api.get_devices(client) do
      model |> Map.put(:devices, devices)
    end
  end

  def component(%{devices: devices} = _model) do
    num_of_devices_to_show = min(length(devices), 4)
    size_of_row = 12 / num_of_devices_to_show

    row do
      devices |> Enum.map(fn d -> generate_column(d, size_of_row) end)
    end
  end

  def generate_column(%{"newest_events" => events} = device, size) do
    column(size: size) do
      panel title: device["name"] do
        table do
          events |> Enum.map(&generate_row/1)
        end
      end
    end
  end

  defp generate_row({event_name, %{"val" => val} = _event_content} = _event) do
    {name_of_measurement, unit} = @sensor_measurement_names[event_name]

    table_row([
      table_cell(content: name_of_measurement),
      table_cell(content: "#{Kernel.inspect(val)} #{unit}")
    ])
  end
end

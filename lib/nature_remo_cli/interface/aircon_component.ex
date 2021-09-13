defmodule NatureRemoCli.Interface.AirconComponent do
  import Ratatouille.View

  alias NatureRemoCli
  alias NatureRemoCli.Api
  alias NatureRemoCli.Interface.{ApplicanceComponent, ComponentTools}
  alias Ratatouille.Constants

  @enter Constants.key(:enter)
  @arrow_up Constants.key(:arrow_up)
  @arrow_down Constants.key(:arrow_down)
  @arrow_left Constants.key(:arrow_left)
  @arrow_right Constants.key(:arrow_right)

  @aircon_api_keypair %{
    "temp" => "temperature",
    "mode" => "operation_mode",
    "vol" => "air_volume",
    "dir" => "air_direction"
  }

  def enable_component(model, device \\ nil) do
    device =
      if is_nil(device) do
        ApplicanceComponent.get_aircon(model)
      else
        device
      end

    settings = device["settings"]

    model
    |> Map.put(:control_component, %{
      type: :aircon,
      device: device,
      selected: %{
        mode: settings["mode"],
        param_name: "temp"
      },
      current_setting: settings
    })
  end

  def disable_component(model) do
    model
    |> Map.delete(:control_component)
  end

  def update(model, msg) do
    case msg do
      {:event, %{key: @enter}} ->
        send_command(model)
        model

      {:event, %{key: @arrow_up}} ->
        decrement_row(model)

      {:event, %{key: @arrow_down}} ->
        increment_row(model)

      {:event, %{key: @arrow_right}} ->
        increment_column(model)

      {:event, %{key: @arrow_left}} ->
        decrement_column(model)

      _ ->
        model
    end
  end

  def move_row(model, new_param_name) do
    model |> put_in([:control_component, :selected, :param_name], new_param_name)
  end

  def increment_row(
        %{
          control_component:
            %{selected: %{mode: mode, param_name: selected_param_name}} = control_component
        } = model
      ) do
    next_param_name =
      ComponentTools.get_next(
        get_parameter_options(control_component, mode) |> Map.keys(),
        selected_param_name
      )

    move_row(model, next_param_name)
  end

  def decrement_row(
        %{
          control_component:
            %{selected: %{mode: mode, param_name: selected_param_name}} = control_component
        } = model
      ) do
    new_param_name =
      ComponentTools.get_prev(
        get_parameter_options(control_component, mode) |> Map.keys(),
        selected_param_name
      )

    move_row(model, new_param_name)
  end

  def move_column(model, param_name, new_param_value) do
    model |> put_in([:control_component, :current_setting, param_name], new_param_value)
  end

  def increment_column(
        %{
          control_component:
            %{
              selected: %{param_name: param_name, mode: mode},
              current_setting: current_setting
            } = control_component
        } = model
      ) do
    param_options = get_parameter_options(control_component, mode)

    new_param_value =
      ComponentTools.get_next(param_options[param_name], current_setting[param_name])

    move_column(model, param_name, new_param_value)
  end

  def decrement_column(
        %{
          control_component:
            %{
              selected: %{param_name: param_name, mode: mode},
              current_setting: current_setting
            } = control_component
        } = model
      ) do
    param_options = get_parameter_options(control_component, mode)

    new_param_value =
      ComponentTools.get_next(param_options[param_name], current_setting[param_name])

    move_column(model, param_name, new_param_value)
  end

  def send_command(
        %{control_component: %{device: device, current_setting: setting}, client: client} = _model
      ) do
    appliance_id = device["id"]
    {:ok, _res} = Api.post_control_ac(client, appliance_id, setting |> translate_param_name)
  end

  defp translate_param_name(setting) do
    Enum.reduce(setting, %{}, fn {param_name, param_value}, acc ->
      acc |> Map.put_new(@aircon_api_keypair[param_name], param_value)
    end)
  end

  def component(%{control_component: %{type: :aircon} = component_model} = _model) do
    overlay(padding: 15) do
      generate_mode_panel(component_model)
    end
  end

  def component(_model) do
  end

  defp generate_mode_panel(%{selected: %{mode: mode}} = component_model) do
    panel do
      generate_paramer_options_table(component_model, mode)
    end
  end

  defp generate_paramer_options_table(component_model, mode) do
    parameter_options = get_parameter_options(component_model, mode)

    table do
      parameter_options
      |> Enum.map(fn param_option -> generate_parameter_row(component_model, param_option) end)
    end
  end

  defp generate_parameter_row(
         %{current_setting: current_setting, selected: %{param_name: selected_param_name}},
         {param_name, _}
       ) do
    table_row(selected_attributes(param_name == selected_param_name)) do
      table_cell(content: param_name)
      table_cell(content: current_setting[param_name])
    end
  end

  def selected_attributes(flag) do
    if flag do
      [background: :blue]
    else
      []
    end
  end

  defp get_parameter_options(%{device: device} = _component_model, mode) do
    device["aircon"]["range"]["modes"][mode]
  end
end

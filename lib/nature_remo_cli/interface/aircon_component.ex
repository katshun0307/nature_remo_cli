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

      {:event, %{ch: keycode}}
      when ?0 <= keycode and keycode <= ?9 ->
        model |> change_mode_with_number(<<keycode>> |> String.to_integer())

      _ ->
        model
    end
  end

  def change_mode_with_number(model, number) do
    modes = get_modes(model.control_component)

    if number < length(modes) do
      change_mode(model, Enum.at(modes, number))
    else
      model
    end
  end

  def change_mode(%{control_component: component_model} = model, mode) do
    param_info = get_parameter_options(component_model, mode)
    selected_param_name = param_info |> Map.keys() |> Enum.at(0)

    model
    |> put_in([:control_component, :selected], %{mode: mode, param_name: selected_param_name})
    |> put_in(
      [:control_component, :current_setting, mode],
      get_initial_setting(component_model, param_info)
    )
  end

  # Get initial param settings for new mode
  def get_initial_setting(%{current_setting: current_setting} = _control_component, param_info) do
    param_info
    |> Enum.map(fn {param_name, param_options} ->
      current_param_value = current_setting[param_name]

      if current_param_value do
        new_param_value =
          if(Enum.member?(param_options, current_param_value)) do
            current_param_value
          else
            Enum.at(param_options, 0)
          end

        {param_name, new_param_value}
      else
        nil
      end
    end)
    |> Map.new()
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

  def component(%{control_component: %{type: :aircon, device: device} = component_model} = _model) do
    overlay(padding: 15) do
      panel(title: device["nickname"]) do
        generate_mode_select_table(component_model)
        generate_paramer_options_table(component_model, component_model.selected.mode)
        label(content: "Press ESC to close popup. Press ENTER to fire signal.")
      end
    end
  end

  def component(_model) do
  end

  def generate_mode_select_table(component_model) do
    modes_with_index = get_modes(component_model) |> Enum.with_index()

    table do
      table_row do
        modes_with_index |> Enum.map(fn m -> generate_column(m, component_model) end)
      end
    end
  end

  def generate_column({mode, i}, %{selected: %{mode: selected_mode}} = _component_model) do
    if mode == selected_mode do
      table_cell(content: "#{i}: #{mode}", background: :blue)
    else
      table_cell(content: "#{i}: #{mode}")
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
      table_cell(content: "◀ #{current_setting[param_name]} ▶")
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
    |> Enum.filter(fn {_, options} -> length(options) > 1 end)
    |> Map.new()
  end

  def get_modes(%{device: device} = _component_model) do
    device["aircon"]["range"]["modes"] |> Map.keys()
  end
end

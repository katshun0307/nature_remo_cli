defmodule NatureRemoCli.App do
  @behaviour Ratatouille.App

  import Ratatouille.View

  alias NatureRemoCli.Api
  alias NatureRemoCli.Interface.{ApplicanceComponent, SensorComponent, AirconComponent}
  alias Ratatouille.Constants

  @enter Constants.key(:enter)
  @esc Constants.key(:esc)

  def init(_context \\ %{}) do
    %{client: Api.client(), debug: "", focus: ApplicanceComponent}
    |> ApplicanceComponent.assign()
    |> SensorComponent.assign()
  end

  def put_focus(model, module) do
    model |> Map.put(:focus, module)
  end

  def enable_appliance_component(model, appliance) do
    case appliance["type"] do
      "AC" -> model |> put_focus(AirconComponent) |> AirconComponent.enable_component(appliance)
      _ -> model
    end
  end

  def update(model, msg) do
    case msg do
      # Move Focus
      {:event, %{key: @enter}} when model.focus == ApplicanceComponent ->
        appliance = ApplicanceComponent.get_current_device(model)
        model |> enable_appliance_component(appliance) |> put_focus(AirconComponent)

      {:event, %{key: @enter}} when model.focus == AirconComponent ->
        model
        |> AirconComponent.update(msg)
        |> AirconComponent.disable_component()
        |> put_focus(ApplicanceComponent)

      {:event, %{key: @esc}} when model.focus == AirconComponent ->
        model
        |> AirconComponent.disable_component()
        |> put_focus(ApplicanceComponent)

      # Pass down msg to Focus
      msg when model.focus == ApplicanceComponent ->
        model
        |> ApplicanceComponent.update(msg)

      msg when model.focus == AirconComponent ->
        model
        |> AirconComponent.update(msg)

      {:event, %{ch: keycode}}
      when ?0 <= keycode and keycode <= ?9 ->
        model
        |> ApplicanceComponent.assign_selection(
          <<keycode>> |> String.to_integer(),
          true
        )

      _ ->
        model
    end
  end

  def render(model) do
    view top_bar: top_bar(), bottom_bar: bottom_bar(model) do
      panel title: "hoge" do
        # a row
        SensorComponent.component(model)
        # a row
        ApplicanceComponent.component(model)
      end

      # overlay
      AirconComponent.component(model)
    end
  end

  def top_bar() do
    bar do
      label(content: "Nature Remo TUI")
    end
  end

  def bottom_bar(%{debug: message} = _model) do
    bar do
      label(content: message)
    end
  end
end

defmodule NatureRemoCli.App do
  @behaviour Ratatouille.App

  import Ratatouille.View

  alias NatureRemoCli.Api
  alias NatureRemoCli.Interface.{ApplicanceComponent, SensorComponent}
  alias Ratatouille.Constants

  @arrow_down Constants.key(:arrow_down)
  @arrow_up Constants.key(:arrow_up)

  def init(_context) do
    %{client: Api.client(), debug: ""}
    |> ApplicanceComponent.assign()
    |> SensorComponent.assign()
  end

  def update(model, msg) do
    case msg do
      {:event, %{key: @arrow_down}} ->
        model |> ApplicanceComponent.increment_selection()

      {:event, %{key: @arrow_up}} ->
        model |> ApplicanceComponent.decrement_selection()

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

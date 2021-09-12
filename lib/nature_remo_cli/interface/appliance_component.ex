defmodule NatureRemoCli.Interface.ApplicanceComponent do
  import Ratatouille.View

  alias NatureRemoCli.Api

  def assign(%{client: client} = model) do
    with {:ok, %{body: appliances}} <- Api.get_appliances(client) do
      map = %{appliances: appliances |> Enum.with_index(), selected: 0, size: length(appliances)}

      model
      |> Map.put(:appliance_component, map)
    end
  end

  def assign_selection(
        %{appliance_component: appliance_component} = model,
        selection,
        is_strict \\ false
      ) do
    size = appliance_component.size

    if (is_strict and selection < size) or not is_strict do
      model
      |> Map.put(
        :appliance_component,
        appliance_component
        |> Map.put(:selected, rem(selection, size))
      )
    else
      model
    end
  end

  def increment_selection(%{appliance_component: %{selected: selected}} = model) do
    assign_selection(model, selected + 1)
  end

  def decrement_selection(%{appliance_component: %{selected: selected}} = model) do
    assign_selection(model, selected - 1)
  end

  def component(%{appliance_component: %{appliances: appliances, selected: selected}}) do
    row do
      column size: 12 do
        panel title: "Appliances" do
          table(
            appliances
            |> Enum.map(fn appliance -> generate_row(appliance, selected) end)
          )
        end
      end
    end
  end

  defp generate_row(
         {%{"nickname" => nickname, "device" => %{"name" => device_name}} = _appliance, i},
         selected
       ) do
    table_row(
      selected_attributes(selected == i),
      [
        table_cell(content: "#{i}"),
        table_cell(content: nickname),
        table_cell(content: device_name)
      ]
    )
  end

  defp selected_attributes(flag) do
    if flag do
      [background: :blue]
    else
      []
    end
  end
end

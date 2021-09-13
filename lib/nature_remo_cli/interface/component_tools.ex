defmodule NatureRemoCli.Interface.ComponentTools do
  def get_next(list, current) do
    new_index =
      Enum.find_index(list, fn x -> x == current end)
      |> increment_number_modulo(length(list))

    Enum.at(list, new_index)
  end

  def get_prev(list, current) do
    new_index =
      Enum.find_index(list, fn x -> x == current end)
      |> decrement_number_modulo(length(list))

    Enum.at(list, new_index)
  end

  def increment_number_modulo(number, modulo) do
    rem(number + modulo + 1, modulo)
  end

  def decrement_number_modulo(number, modulo) do
    rem(number + modulo - 1, modulo)
  end
end

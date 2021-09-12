defmodule NatureRemoCli do
  @moduledoc """
  Documentation for `NatureRemoCli`.
  """

  def run(_args \\ %{}) do
    Ratatouille.run(NatureRemoCli.App)
  end
end

defmodule Instinct.WordGames.WordGameTemplate do
  use Ecto.Schema
  use Instinct.SchemaResultTypes
  use Instinct.StandardData

  import Ecto.Changeset

  @primary_key {:date, :date, autogenerate: false}
  schema "word_game_templates" do
    field(:key, :string)
    field(:prompt, :string)
    field(:phrase, :string)
    field(:category, :string)
    field(:max_guesses, :integer, default: 5)

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = game, attrs) do
    required = [:key, :phrase, :category, :date]
    optional = [:prompt]

    game
    |> cast(attrs, required ++ optional)
    |> validate_required(required)
  end
end

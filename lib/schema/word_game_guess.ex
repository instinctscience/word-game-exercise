defmodule Instinct.WordGames.WordGameGuess do
  use Ecto.Schema
  use Instinct.SchemaResultTypes

  import Ecto.Changeset

  alias Instinct.WordGames

  schema "word_game_guesses" do
    belongs_to(:word_game, WordGames.WordGame)
    field(:phrase, :string)

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = game, attrs) do
    required = [
      :word_game_id,
      :phrase
    ]

    optional = []

    game
    |> cast(attrs, required ++ optional)
    |> validate_required(required)
  end
end

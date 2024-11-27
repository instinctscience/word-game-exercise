defmodule Instinct.WordGames.WordGameSlot do
  use Ecto.Schema
  use Instinct.SchemaResultTypes

  import Ecto.Changeset

  alias Instinct.WordGames

  schema "word_game_slots" do
    belongs_to(:word_game, WordGames.WordGame)
    belongs_to(:word_game_guess, WordGames.WordGameGuess)
    field(:character, :string)
    field(:position, :integer)
    field(:points, :integer)
    field(:is_active, :boolean)

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = game, attrs) do
    required = [
      :word_game_id,
      :character,
      :position,
      :points,
      :is_active
    ]

    optional = [:word_game_guess_id]

    game
    # empty_values: [] allows <space> characters " " to not be cast to nil
    |> cast(attrs, required ++ optional, empty_values: [])
    |> validate_required(required)
  end
end

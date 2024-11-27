defmodule Instinct.WordGames.WordGamePlayer do
  alias Instinct.WordGames.WordGame

  @type t :: %__MODULE__{
          key: String.t(),
          points: integer,
          user: Staff.User,
          word_games: [WordGame.t()],
          rank: integer | nil
        }

  defstruct [
    :key,
    :points,
    :user,
    :word_games,
    :rank
  ]
end

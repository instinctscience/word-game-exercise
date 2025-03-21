defmodule Instinct.WordGames.WordGame do
  use Ecto.Schema

  import Ecto.Changeset

  alias Instinct.{Organization, Staff, WordGames}

  @type t :: %__MODULE__{}

  schema "word_games" do
    belongs_to(:word_game_template, WordGames.WordGameTemplate,
      foreign_key: :word_game_template_date,
      type: :date,
      references: :date
    )

    belongs_to(:user, Staff.User)
    belongs_to(:location, Organization.Location)
    field(:score, :integer, default: 0)
    field(:is_completed, :boolean, default: false)

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = game, attrs) do
    required = [
      :word_game_template_date,
      :user_id,
      :location_id
    ]

    optional = [
      :score,
      :is_completed
    ]

    game
    |> cast(attrs, required ++ optional)
    |> validate_required(required)
    |> foreign_key_constraint(:word_game_template_date)
  end
end

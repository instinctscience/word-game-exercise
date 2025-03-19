defmodule Instinct.API.Schema.WordGame do
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Instinct.API.Schema.WordGame.Resolvers

  # schema objects

  object :word_game do
    field(:id, non_null(:id))
    field(:user, non_null(:user), resolve: dataloader(Instinct.Staff.UserData))
    field(:location, non_null(:location), resolve: dataloader(Instinct.Data))
    field(:word_game_template, non_null(:word_game_template), resolve: dataloader(Instinct.Data))

    field(:slots, non_null(list_of(non_null(:word_game_slot))),
      resolve: &Resolvers.list_game_slots/3
    )

    field(:guesses, non_null(list_of(non_null(:word_game_guess))),
      resolve: &Resolvers.list_game_guesses/3
    )

    field(:remaining_guesses, non_null(:integer),
      resolve: &Resolvers.get_game_remaining_guesses/3
    )

    field(:score, non_null(:integer)) do
      arg(:end_date, :date)
      resolve(&Resolvers.get_game_score/3)
    end

    field(:is_completed, non_null(:boolean))

    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end

  object :word_game_template do
    field(:key, non_null(:string))
    field(:prompt, :string)
    field(:category, non_null(:string))
    field(:max_guesses, non_null(:integer))
    field(:points, non_null(:integer), resolve: &Resolvers.get_game_template_points/3)
    field(:date, non_null(:date))

    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end

  object :word_game_slot do
    field(:word_game, non_null(:word_game), resolve: dataloader(Instinct.Data))
    field(:id, non_null(:id))
    field(:is_revealed, non_null(:boolean))
    field(:reveal_actor, :string)
    field(:reveal_actor_id, :integer, resolve: dataloader(Instinct.Data))
    field(:character, non_null(:string))
    field(:position, non_null(:integer))
    field(:points, non_null(:integer))
  end

  object :word_game_guess do
    field(:word_game, non_null(:word_game), resolve: dataloader(Instinct.Data))
    field(:id, non_null(:id))
    field(:phrase, non_null(:string))
  end

  object :word_game_character do
    field(:content, non_null(:string))
    field(:value, non_null(:integer))
  end

  object :word_game_player do
    field(:key, non_null(:string))
    field(:user, non_null(:user))
    field(:points, non_null(:integer))
    field(:rank, non_null(:integer))
    field(:word_games, non_null(list_of(non_null(:word_game))))
  end

  object :word_game_queries do
    field(:word_game_templates, non_null(list_of(non_null(:word_game_template)))) do
      arg(:start_date, :date)
      arg(:end_date, :date)
      resolve(&Resolvers.list_game_templates/2)
    end

    field(:word_game, :word_game) do
      arg(:id, non_null(:id))
      resolve(&Resolvers.get_game/2)
    end

    field(:word_games, non_null(list_of(non_null(:word_game)))) do
      arg(:location_id, non_null(:id))
      arg(:user_id, :id)
      arg(:start_date, :date)
      arg(:end_date, :date)
      resolve(&Resolvers.list_games/2)
    end

    field(:word_game_players, non_null(list_of(non_null(:word_game_player)))) do
      arg(:location_id, non_null(:id))
      arg(:start_date, :date)
      arg(:end_date, :date)
      arg(:limit, :integer)
      resolve(&Resolvers.list_players/2)
    end

    field(:word_game_player, :word_game_player) do
      arg(:start_date, :date)
      arg(:end_date, :date)
      resolve(&Resolvers.get_player/2)
    end

    field(:word_game_characters, non_null(list_of(non_null(:word_game_character)))) do
      resolve(&Resolvers.list_game_characters/2)
    end
  end

  object :word_game_mutations do
    @desc "Create game"
    field(:create_word_game, non_null(:word_game)) do
      arg(:word_game_template_date, non_null(:date))
      arg(:location_id, non_null(:id))
      resolve(&Resolvers.create_game/2)
    end

    @desc "Make a guess"
    field(:create_word_game_guess, non_null(:word_game)) do
      arg(:word_game_id, non_null(:id))
      arg(:phrase, non_null(:string))
      resolve(&Resolvers.create_game_guess/2)
    end

    @desc "Reveal a hint"
    field(:reveal_word_game_hint, non_null(:word_game)) do
      arg(:word_game_id, non_null(:id))
      resolve(&Resolvers.reveal_game_hint/2)
    end

    field(:reveal_word_game_board, non_null(:word_game)) do
      arg(:word_game_id, non_null(:id))
      resolve(&Resolvers.reveal_game_board/2)
    end
  end
end

defmodule Instinct.WordGames.WordGames do
  import Ecto.Query, warn: false

  require Logger

  alias Instinct.{Data, Error, Repo}

  alias __MODULE__.{
    WordGame,
    WordGameTemplate,
    WordGameSlot,
    WordGameGuess,
    WordGamePlayer
  }

  #############
  # Supported Characters for a Phrase
  #############

  @characters [
    {"a", 1},
    {"e", 1},
    {"i", 1},
    {"o", 1},
    {"u", 1},
    {"l", 1},
    {"n", 1},
    {"r", 1},
    {"s", 1},
    {"t", 1},
    {"d", 2},
    {"g", 2},
    {"b", 3},
    {"c", 3},
    {"m", 3},
    {"p", 3},
    {"f", 4},
    {"h", 4},
    {"v", 4},
    {"w", 4},
    {"y", 4},
    {"k", 5},
    {"j", 8},
    {"x", 8},
    {"q", 9},
    {"z", 9}
  ]

  @spec list_characters() :: list()
  def list_characters, do: Enum.map(@characters, fn {k, v} -> %{content: k, value: v} end)

  #################################
  # Managing Word Game TEMPLATES
  #################################

  @spec list_game_templates(game_template_filters_params()) :: [WordGameTemplate.t()]
  def list_game_templates(params \\ %{}) do
    params
    |> with_game_template_filters(WordGameTemplate)
    |> order_by([gt], asc: gt.date)
    |> Repo.all()
  end

  @spec get_word_game_template(Data.id()) :: WordGameTemplate.result()
  def get_word_game_template(game_template_date) do
    Repo.fetch(WordGameTemplate, game_template_date)
  end

  @spec create_game_template(map) :: WordGameTemplate.result()
  def create_game_template(attrs) do
    attrs = Map.put_new(attrs, :key, Map.get(attrs, :date))

    %WordGameTemplate{}
    |> WordGameTemplate.changeset(attrs)
    |> Repo.insert()
  end


  #################################
  # Creating a Game
  #################################

  @spec list_games(game_filters_params()) :: [WordGame.t()]
  def list_games(args \\ %{}) do
    args
    |> with_game_filters(WordGame)
    |> Repo.all()
  end

  @spec get_game(Data.id()) :: WordGame.result()
  def get_game(game_id) do
    Repo.fetch(WordGame, game_id)
  end

  @spec get_existing_word_game(String.t(), map) :: WordGame.result()
  def get_existing_word_game(date, attrs) do
    from(g in WordGame,
      where:
        g.word_game_template_date == ^date and g.user_id == ^attrs.user_id and
          g.location_id == ^attrs.location_id
    )
    |> Repo.fetch_one()
  end

  @spec create_game(map) :: WordGame.result()
  def create_game(%{:word_game_template_date => word_game_template_date} = attrs) do
    case get_existing_word_game(word_game_template_date, attrs) do
      {:ok, word_game} ->
        {:ok, word_game}

      _ ->
        # Insert the word_games record
        {:ok, game} =
          %WordGame{}
          |> WordGame.changeset(attrs)
          |> Repo.insert()

        # Create the PLACEHOLDER slots for each character of the game phrase.
        with {:ok, word_game_template} <- get_word_game_template(word_game_template_date) do
          word_game_template
          |> Map.get(:phrase)
          |> get_characters_from_phrase()
          |> Enum.with_index()
          |> Enum.each(fn {char, i} ->
            {:ok, _slot} = create_game_slot(game.id, char, i)
          end)
        end

        {:ok, game}
    end
  end

  @spec update_word_game(WordGame.t(), map) :: {:ok, WordGame.t()}
  def update_word_game(game, attrs) do
    game
    |> WordGame.changeset(attrs)
    |> Repo.update()
  end

  #################################
  # Game Slots
  #################################

  @spec list_game_slots(WordGame.t()) :: [WordGameSlot.t()]
  def list_game_slots(word_game) do
    from(s in WordGameSlot, where: s.word_game_id == ^word_game.id, order_by: [asc: s.position])
    |> Repo.all()
  end

  @spec get_game_slot(Data.id()) :: WordGameSlot.result()
  def get_game_slot(slot_id) do
    Repo.fetch(WordGameSlot, slot_id)
  end

  @spec get_game_slot_by_position(WordGame.t(), number) :: WordGameSlot.result()
  def get_game_slot_by_position(game, position) do
    Repo.fetch_one(
      from s in WordGameSlot,
        where: s.word_game_id == ^game.id,
        where: s.position == ^position
    )
  end

  @spec create_game_slot(Data.id(), String.t(), number) :: WordGameSlot.result()
  def create_game_slot(word_game_id, character, position) do
    %WordGameSlot{}
    |> WordGameSlot.changeset(%{
      word_game_id: word_game_id,
      # special characters "," "-" "'" start as revealed
      is_revealed: letter_character?(character) == false,
      reveal_actor: nil,
      reveal_actor_id: nil,
      position: position,
      character: character,
      points: get_character_value(character)
    })
    |> Repo.insert()
  end

  @spec update_game_slot(WordGameSlot.t(), map) :: WordGameSlot.result()
  def update_game_slot(slot, attrs) do
    slot
    |> WordGameSlot.changeset(attrs)
    |> Repo.update()
  end

  #################################
  # Game Guesses
  #################################

  @spec list_game_guesses(WordGame.t()) :: [WordGameGuess.t()]
  def list_game_guesses(word_game) do
    from(gg in WordGameGuess, where: gg.word_game_id == ^word_game.id)
    |> Repo.all()
  end

  @spec create_guess(WordGame.t(), String.t()) :: {:ok, WordGame.t()} | {:error, Error.t()}
  def create_guess(word_game, guess_phrase) do
    remaining_guesses = get_game_remaining_guesses(word_game)

    if remaining_guesses > 0 do
      # Insert the word_game_guesses record
      {:ok, game_guess} =
        %WordGameGuess{}
        |> WordGameGuess.changeset(%{
          word_game_id: word_game.id,
          phrase: guess_phrase
        })
        |> Repo.insert()

      # Now, we are going to update any game slots that were guessed correctly.

      # Split the guess_phrase into characters
      guess_characters = get_characters_from_phrase(guess_phrase)

      # Lookup the game slot at the corresponding position
      # If it is inactive, update it if the character matches
      #   - Update the guess_id
      #   - Update is_revealed
      guess_characters
      |> Enum.with_index()
      |> Enum.each(fn {guess_character, index} ->
        case get_game_slot_by_position(word_game, index) do
          {:ok, slot} ->
            cond do
              # Ignore already active slots
              slot.is_revealed ->
                slot

              # Correct guess!
              slot.character == guess_character ->
                update_game_slot(slot, %{is_revealed: true, reveal_actor: :guess, reveal_actor_id: game_guess.id})

              # Ignore incorrect guesses.
              true ->
                true
            end

          # Game slot does not exists. Do nothing.
          {:error, _msg} ->
            true
        end
      end)

      # Update the scores for the game
      update_word_game_stats(word_game)
    else
      {:error, %Error{type: :exceeded_remaining_guesses, message: "No guesses remaining"}}
    end
  end

  @spec get_game_remaining_guesses(WordGame.t()) :: number
  def get_game_remaining_guesses(word_game) do
    {:ok, game_template} = get_word_game_template(word_game.word_game_template_date)
    guesses = list_game_guesses(word_game)
    game_template.max_guesses - length(guesses)
  end

  #################################
  # Revealing Slots
  #################################

  @spec reveal_hint(WordGame.t()) :: {:ok, WordGame.t()}
  def reveal_hint(word_game) do
    slots = list_game_slots(word_game)
    hint_slots = find_next_hint_slots(slots)

    Enum.each(hint_slots, fn hint_slot ->
      update_game_slot(hint_slot, %{is_revealed: true, reveal_actor: :hint, reveal_actor_id: nil})
    end)

    update_word_game_stats(word_game)
  end

  @spec reveal_board(WordGame.t()) :: {:ok, WordGame.t()} | {:error, any()}
  def reveal_board(word_game) do
    remaining_guesses = get_game_remaining_guesses(word_game)

    if remaining_guesses == 0 do
      slots = list_game_slots(word_game)

      Enum.each(slots, fn slot ->
        update_game_slot(slot, %{is_revealed: true, reveal_actor: :hint, reveal_actor_id: nil})
      end)

      update_word_game_stats(word_game)
    else
      {:error, %Error{type: :remaining_guesses, message: "Game still has remaining guesses"}}
    end
  end

  @spec find_next_hint_slots([WordGameSlot.t()]) :: [WordGameSlot.t()]
  defp find_next_hint_slots([]) do
    []
  end

  defp find_next_hint_slots(slots) do
    empty_guessable_slots = Enum.filter(slots, fn slot -> slot.points > 0 and slot.is_revealed == false end)

    # This "hint engine" reveals hidden letters in the board in a predictable order using the @characters list order.
    Enum.reduce_while(@characters, [], fn {character, _points}, acc ->
      hint_slots = Enum.filter(empty_guessable_slots, &(&1.character == character))

      if hint_slots == [] do
        {:cont, acc}
      else
        {:halt, hint_slots}
      end
    end)
  end

  #################################
  # Game Utilities
  #################################

  @spec update_word_game_stats(WordGame.t()) :: {:ok, WordGame.t()}
  def update_word_game_stats(word_game) do
    slots = list_game_slots(word_game)

    is_game_completed = slots |> Enum.map(& &1.is_revealed) |> Enum.all?()

    next_score =
      Enum.reduce(slots, 0, fn slot, score ->
        if slot.word_game_guess_id == nil do
          score
        else
          score + slot.points
        end
      end)

    update_word_game(word_game, %{
      is_completed: is_game_completed,
      score: next_score
    })
  end

  @spec compute_phrase_points(String.t()) :: number
  def compute_phrase_points(phrase) do
    phrase
    |> get_characters_from_phrase()
    |> Enum.map(&get_character_value/1)
    |> Enum.sum()
  end

  defp letter_character?(char), do: if(get_character(char) == nil, do: false, else: true)

  defp get_character_value(char) do
    case get_character(char) do
      {_k, v} -> v
      _ -> 0
    end
  end

  defp get_character(char) do
    Enum.find(@characters, fn {k, _v} -> char == k end)
  end

  @spec get_characters_from_phrase(String.t()) :: [String.t()]
  def get_characters_from_phrase(phrase) do
    phrase
    |> String.split(" ", trim: true)
    |> Enum.map(&characters_from_word/1)
    |> Enum.intersperse([" "])
    |> Enum.flat_map(& &1)
  end

  defp characters_from_word(word) do
    word
    |> String.split("", trim: true)
    |> Enum.map(&String.downcase/1)
  end

  @spec get_game_phrase(WordGame.t()) :: String.t()
  def get_game_phrase(game) do
    game
    |> list_game_slots()
    |> Enum.map_join("", &if(&1.is_revealed, do: &1.character, else: "_"))
  end

  @type game_filters_params() :: %{
          optional(:limit) => integer,
          optional(:location_id) => Data.id(),
          optional(:user_id) => Data.id(),
          optional(:start_date) => Date.t(),
          optional(:end_date) => Date.t()
        }

  @spec with_game_filters(game_filters_params(), Ecto.Queryable.t()) :: Ecto.Queryable.t()
  defp with_game_filters(params, query) do
    Enum.reduce(params, query, fn
      {:limit, limit}, query ->
        from g in query, limit: ^limit

      {:location_id, location_id}, query ->
        from g in query, where: g.location_id == ^location_id

      {:user_id, user_id}, query ->
        from g in query, where: g.user_id == ^user_id

      {:start_date, start_date}, query ->
        from(g in query,
          left_join: gt in assoc(g, :word_game_template),
          where: gt.date >= ^start_date
        )

      {:end_date, end_date}, query ->
        from(g in query,
          left_join: gt in assoc(g, :word_game_template),
          where: gt.date <= ^end_date
        )

      _, query ->
        query
    end)
  end

  @type game_template_filters_params() :: %{
          optional(:limit) => integer,
          optional(:start_date) => Date.t(),
          optional(:end_date) => Date.t()
        }

  @spec with_game_template_filters(game_template_filters_params(), Ecto.Queryable.t()) ::
          Ecto.Queryable.t()
  defp with_game_template_filters(params, query) do
    Enum.reduce(params, query, fn
      {:limit, limit}, query ->
        from gt in query, limit: ^limit

      {:start_date, start_date}, query ->
        from gt in query,
          where: gt.date >= ^start_date,
          or_where: is_nil(gt.date)

      {:end_date, end_date}, query ->
        from gt in query,
          where: gt.date <= ^end_date,
          or_where: is_nil(gt.date)

      _, query ->
        query
    end)
  end
end

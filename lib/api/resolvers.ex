defmodule Instinct.API.Schema.WordGame.Resolvers do
  alias Instinct.WordGames

  def list_game_templates(params, _) do
    {:ok, WordGames.list_game_templates(params)}
  end

  def list_games(params, _) do
    {:ok, WordGames.list_games(params)}
  end

  def list_game_characters(_, _) do
    {:ok, WordGames.list_characters()}
  end

  def list_players(params, _) do
    {:ok, WordGames.list_players(params)}
  end

  def get_player(attrs, info) do
    attrs = Map.put_new(attrs, :user_id, info.context.user.id)
    {:ok, WordGames.get_player(attrs)}
  end

  def get_game(params, _) do
    WordGames.get_game(params.id)
  end

  def create_game(attrs, info) do
    attrs = Map.put_new(attrs, :user_id, info.context.user.id)

    WordGames.create_game(attrs)
  end

  def create_game_guess(attrs, _info) do
    {:ok, game} = WordGames.get_game(attrs.word_game_id)
    WordGames.create_guess(game, attrs.phrase)
  end

  def reveal_game_hint(attrs, _info) do
    {:ok, game} = WordGames.get_game(attrs.word_game_id)
    WordGames.reveal_hint(game)
  end

  def reveal_game_board(attrs, _info) do
    {:ok, game} = WordGames.get_game(attrs.word_game_id)
    WordGames.reveal_board(game)
  end

  def get_game_score(game, %{end_date: end_date}, info) do
    if Date.compare(game.updated_at, end_date) == :gt do
      {:ok, 0}
    else
      get_game_score(game, %{}, info)
    end
  end

  def get_game_score(game, _, _), do: {:ok, game.score}

  def list_game_guesses(game, _, _) do
    guesses = WordGames.list_game_guesses(game)
    {:ok, guesses}
  end

  def list_game_slots(game, _, _) do
    slots = WordGames.list_game_slots(game)
    {:ok, slots}
  end

  def get_game_remaining_guesses(game, _, _) do
    remaining_guesses = WordGames.get_game_remaining_guesses(game)
    {:ok, remaining_guesses}
  end

  def get_game_template_points(game_template, _, _) do
    points = WordGames.compute_phrase_points(game_template.phrase)
    {:ok, points}
  end
end

use Dogma.RuleBuilder

defrule Dogma.Rule.FinalCondition, [catch_all: true] do
  @moduledoc """
  A rule that checks that the last condition of a `cond` statement is `true`.

  For example, prefer this:

      cond do
        1 + 2 == 5 ->
          "Nope"
        1 + 3 == 5 ->
          "Uh, uh"
        true ->
          "OK"
      end

  Not this:

      cond do
        1 + 2 == 5 ->
          "Nope"
        1 + 3 == 5 ->
          "Nada"
        _ ->
          "OK"
      end

  This rule will only catch those `cond` statements where the last condition
  is a literal or a `_`. Complex expressions and function calls will not
  generate an error.

  For example, neither of the following will generate an error:

      cond do
        some_predicate? -> "Nope"
        var == :atom    -> "Yep"
      end

      cond do
        var == :atom    -> "Nope"
        some_predicate? -> "Yep"
      end

  An atom may also be used as a catch-all expression in a `cond`, since it
  evaluates to a truthy value. Suggested atoms are `:else` or `:otherwise`.

  To allow one of these instead of `true`, pass it to the rule as a
  `:catch_all` option.

  If you would like to enforce the use of `_` as your catch-all condition, pass
  the atom `:_` into the `:catch_all` option.

      cond do
        _ -> "Yep"
      end

      cond do
        :_ -> "Yep"
      end
  """

  def test(rule, script) do
    script
    |> Script.walk(&check_ast(&1, &2, rule.catch_all))
    |> Enum.reverse
  end

  defp check_ast({:cond, _, [[do: children]]} = ast, errors, check) do
    {:->, meta, [[con] | _]} = List.last( children )

    if error?(con, check) do
      {ast, [error(meta[:line], check) | errors]}
    else
      {ast, errors}
    end
  end

  # Case for a custom cond function
  defp check_ast({:cond, _, _} = ast, errors, _) do
    {ast, errors}
  end

  defp check_ast(ast, errors, _) do
    {ast, errors}
  end

  defp error?(con, con),      do: false
  defp error?({:_, _,_}, :_), do: false
  defp error?({:_, _,_}, _),  do: true
  defp error?({_, _, _}, _),  do: false
  defp error?(_, _),          do: true

  defp error(line, :_), do: error(line, '_')
  defp error(line, check) do
    %Error{
      rule: __MODULE__,
      message:
        "Always use #{inspect check} as the last condition of a cond statement",
      line: Dogma.Script.line(line)
    }
  end
end

defmodule Dogma.Rule.ModuleDocTest do
  use RuleCase, for: ModuleDoc

  test "no error with moduledoc" do
    script = ~S"""
    defmodule VeryGood do
      @moduledoc "Lots of good info here"
    end
    """ |> Script.parse!("")
    assert [] == Rule.test( @rule, script )
  end

  test "no error with nested modules with docs" do
    script = """
    defmodule VeryGood do
      @moduledoc "Lots of good info here"
      defmodule AlsoGood do
        @moduledoc "And even more here!"
      end
    end
    """ |> Script.parse!("")
    assert [] == Rule.test( @rule, script )
  end

  test "errors for a module missing a module doc" do
    script = """
    defmodule NotGood do
    end
    """ |> Script.parse!("")
    expected_errors = [
      %Error{
        rule: ModuleDoc,
        message: "Module NotGood is missing a @moduledoc.",
        line: 1,
      }
    ]
    assert expected_errors == Rule.test( @rule, script )
  end

  test "it determines the module name correctly when it is namespaced" do
    script = """
    defmodule NameSpace.ModName do
    end
    """ |> Script.parse!("")
    expected_errors = [
      %Error{
        rule: ModuleDoc,
        message: "Module NameSpace.ModName is missing a @moduledoc.",
        line: 1,
      }
    ]
    assert expected_errors == Rule.test( @rule, script )
  end

  test "errors for a nested module missing a module doc" do
    script = """
    defmodule VeryGood do
      @moduledoc "Lots of good info here"
      defmodule NotGood do
      end
    end
    """ |> Script.parse!("")
    expected_errors = [
      %Error{
        rule: ModuleDoc,
        message: "Module NotGood is missing a @moduledoc.",
        line: 3,
      }
    ]
    assert expected_errors == Rule.test( @rule, script )
  end

  test "errors for a parent module missing a module doc" do
    script = """
    defmodule NotGood do
      defmodule VeryGood do
        @moduledoc "Lots of good info here"
      end
    end
    """ |> Script.parse!("")
    expected_errors = [
      %Error{
        rule: ModuleDoc,
        message: "Module NotGood is missing a @moduledoc.",
        line: 1,
      }
    ]
    assert expected_errors == Rule.test( @rule, script )
  end

  test "no error for an exs file (exs is skipped)" do
    script = """
    defmodule NotGood do
    end
    """ |> Script.parse!( "foo.exs" )
    assert [] == Rule.test( @rule, script )
  end

  test "don't crash for unquoted module names" do
    script = """
    quote do
      defmodule unquote(name) do
      end
    end
    """ |> Script.parse!("")
    expected_errors = [
      %Error{
        rule: ModuleDoc,
        message: "Unknown module is missing a @moduledoc.",
        line: 2,
      }
    ]
    assert expected_errors == Rule.test( @rule, script )
  end


  test "understand :atom module names" do
    script = """
    defmodule :some_mod do
    end
    """ |> Script.parse!("")
    expected_errors = [
      %Error{
        rule: ModuleDoc,
        message: "Module :some_mod is missing a @moduledoc.",
        line: 1,
      }
    ]
    assert expected_errors == Rule.test( @rule, script )
  end
end

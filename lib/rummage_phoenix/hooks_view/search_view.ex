defmodule Rummage.Phoenix.SearchView do
  @moduledoc """
  Search View Module for Rummage. This has view helpers that can generate rummagable links and forms.

  Usage:

  ```elixir
  defmodule MyApp.ProductView do
    use MyApp.Web, :view
    use Rummage.Phoenix.View, struct: :product, helpers: MyApp.Router.Helpers,
      default_scope: MyApp.Product, repo: MyApp.Repo
  end
  ```

  """

  @doc """
  This macro includes the helpers functions from different Rummage.Phoenix.SearchView

  Provides helpers function `search_form/3` for creating search form in an html.eex
  file of using `Phoenix`.

  Usage:
  Just add the following code in the index template. Make sure that you're passing
  rummage from the controller. Please look at the
  [README](https://github.com/Excipients/rummage_phoenix) for more details

  ```elixir
  search_form(@conn, [:title], @rummage)
  ```
  """
  defmacro __using__(opts) do
    quote do
      def search_form(conn, rummage, link_params) do
        search = rummage["search"]
        sort = if rummage["sort"], do: Poison.encode!(rummage["sort"]), else: ""
        paginate = if rummage["paginate"], do: Poison.encode!(rummage["paginate"]), else: ""

        fields = Keyword.fetch!(link_params, :fields)

        form_for(conn, apply(unquote(opts[:helpers]), String.to_atom("#{unquote(opts[:struct])}_path"), [conn, :index]), [as: :rummage, method: :get], fn(f) ->
          {
            :safe,
            elem(hidden_input(f, :sort, value: sort, class: "form-control"), 1) ++
            elem(hidden_input(f, :paginate, value: paginate, class: "form-control"), 1) ++
            elem(inputs_for(f, :search, fn(s) ->
              {
                :safe,
                inner_form(s, fields, search)
              }
              end), 1) ++
            elem(submit("Search", class: "btn btn-primary"), 1)
          }
        end)
      end

      defp inner_form(s, fields, search) do
        Enum.map(fields, fn(field) ->
          field_name = elem(field, 0)
          field_params = elem(field, 1)
          label = field_params[:label] || "Search by #{Phoenix.Naming.humanize(field_name)}"
          search_type = field_params[:search_type] || "like"
          assoc = field_params[:assoc] || []

          elem(label(s, field_name, label, class: "control-label"), 1) ++
          elem(inputs_for(s, field_name, fn(e) ->
            {
              :safe,
              elem(hidden_input(e, :search_type, value: search_type, class: "form-control"), 1) ++
              elem(hidden_input(e, :assoc, value: assoc, class: "form-control"), 1) ++
              elem(search_input(e, :search_term, value: search[Atom.to_string(field_name)]["search_term"], class: "form-control"), 1)
            }
            end), 1)
        end) |> Enum.reduce([], & &2 ++ &1)
      end
    end
  end
end

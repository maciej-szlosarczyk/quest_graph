defmodule QuestGraph.Schema.Pagination.PageInfo do
  alias QuestGraph.Schema.Cursor

  defstruct [:has_previous_page, :has_next_page, :start_cursor, :end_cursor]

  @type t() :: %__MODULE__{
          has_previous_page: boolean(),
          has_next_page: boolean(),
          start_cursor: Cursor.t() | nil,
          end_cursor: Cursor.t() | nil
        }
end

defmodule QuestGraph.Repo.Migrations.AddTables do
  use Ecto.Migration

  def change do
    create table(:programs) do
      add :name, :string, null: false
      timestamps()
    end

    create table(:quests) do
      add :name, :string, null: false
      add :program_id, references(:programs), null: false
      timestamps()
    end

    create table(:resources) do
      add :name, :string, null: false
      add :quest_id, references(:quests), null: false
      timestamps()
    end
  end
end

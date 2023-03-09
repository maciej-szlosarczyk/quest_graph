# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     RelayWithoutFuss.Repo.insert!(%RelayWithoutFuss.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias RelayWithoutFuss.{Program, Quest, Resource, Repo}

first_program = %Program{name: "First Program"}
second_program = %Program{name: "Second"}

first_program = Repo.insert!(first_program)
second_program = Repo.insert!(second_program)

for i <- 1..500 do
  first_quest = %Quest{program_id: first_program.id, name: "Quest for #{first_program.id} program #{i}"}
  second_quest = %Quest{program_id: second_program.id, name: "Quest for #{second_program.id} program #{i}"}

  first_quest = Repo.insert!(first_quest)
  second_quest = Repo.insert!(second_quest)

  for i <- 1..3 do
    first_quest_resource = %Resource{
      name: "Resource for quest #{first_quest.id}: #{i}",
      quest_id: first_quest.id
    }

    second_quest_resource = %Resource{
      name: "Resource for quest #{second_quest.id}: #{i}",
      quest_id: second_quest.id
    }

    Repo.insert!(first_quest_resource)
    Repo.insert!(second_quest_resource)
  end
end

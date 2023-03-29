defmodule QuestGraph.TestSeeds do
  alias QuestGraph.Program
  alias QuestGraph.Repo
  alias QuestGraph.Resource
  alias QuestGraph.Quest

  def seed_programs(_) do
    first_program = %Program{name: "HyperMemory"} |> Repo.insert!()
    second_program = %Program{name: "SuperDiet"} |> Repo.insert!()

    %{first_program: first_program, second_program: second_program}
  end

  def seed_quests(%{first_program: first_program, second_program: second_program}) do
    quests =
      for i <- 1..100 do
        first_quest = %Quest{
          program_id: first_program.id,
          name: "Quest for HyperMemory program: #{i}"
        }

        second_quest = %Quest{
          program_id: second_program.id,
          name: "Quest for SuperDiet program: #{i}"
        }

        first_quest = Repo.insert!(first_quest)
        second_quest = Repo.insert!(second_quest)

        [first_quest, second_quest]
      end

    quests = List.flatten(quests)

    %{quests: quests}
  end

  def seed_resources(%{quests: quests}) do
    resources =
      for quest <- quests, i <- 1..3 do
        resource = %Resource{name: "Resource for quest #{quest.id}: #{i}", quest_id: quest.id}
        Repo.insert!(resource)
      end

    %{resources: resources}
  end
end

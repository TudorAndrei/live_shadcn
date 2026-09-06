defmodule LiveAiElements.Components.ConfirmationTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]
  import Phoenix.Component, only: [sigil_H: 2]

  alias LiveAiElements.Components.Confirmation

  test "the root renders the alert contract only for an approval outside input states" do
    html = confirmation(%{approval: %{id: "approval-1"}, state: "approval-requested"})

    assert html =~ ~s(data-slot="alert")
    assert html =~ ~s(role="alert")
    assert html =~ "flex"
    assert html =~ "flex-col"
    assert html =~ "gap-2"

    refute confirmation(%{approval: nil, state: "approval-requested"}) =~ "data-slot=\"alert\""

    refute confirmation(%{approval: %{id: "approval-1"}, state: "input-streaming"}) =~
             "data-slot=\"alert\""

    refute confirmation(%{approval: %{id: "approval-1"}, state: "input-available"}) =~
             "data-slot=\"alert\""
  end

  test "the request part is limited to approval-requested" do
    assert request("approval-requested") =~ "Request approval"
    refute request("approval-responded") =~ "Request approval"
  end

  test "the accepted part requires an approved response state" do
    assert accepted(%{id: "approval-1", approved: true}, "approval-responded") =~ "Accepted"
    assert accepted(%{"id" => "approval-1", "approved" => true}, "output-available") =~ "Accepted"
    refute accepted(%{id: "approval-1", approved: false}, "approval-responded") =~ "Accepted"
    refute accepted(%{id: "approval-1", approved: true}, "approval-requested") =~ "Accepted"
  end

  test "the rejected part requires a rejected response state" do
    assert rejected(%{id: "approval-1", approved: false}, "output-denied") =~ "Rejected"

    assert rejected(%{"id" => "approval-1", "approved" => false}, "approval-responded") =~
             "Rejected"

    refute rejected(%{id: "approval-1", approved: true}, "output-denied") =~ "Rejected"
    refute rejected(%{id: "approval-1", approved: false}, "approval-requested") =~ "Rejected"
  end

  test "actions render only while approval is requested" do
    assert actions("approval-requested") =~ "Approve"
    refute actions("approval-responded") =~ "Approve"
  end

  test "the title keeps the pinned AI AlertDescription DOM contract" do
    html =
      render_component(&Confirmation.confirmation_title/1, %{
        class: "title-class",
        inner_block: [slot("Confirmation title")]
      })

    assert html =~ ~s(data-slot="alert-description")
    assert html =~ "text-muted-foreground"
    assert html =~ "col-start-2"
    assert html =~ "justify-items-start"
    assert html =~ "[&amp;_p]:leading-relaxed"
    assert html =~ "inline"
    assert html =~ "title-class"
    refute html =~ "cn-alert-description"
  end

  test "the parts compose from explicit approval and state assigns" do
    requested =
      render_component(&composed_confirmation/1, %{
        approval: %{id: "approval-1"},
        state: "approval-requested"
      })

    assert requested =~ "Request approval"
    assert requested =~ "Approve"
    refute requested =~ "Accepted"
    refute requested =~ "Rejected"

    accepted =
      render_component(&composed_confirmation/1, %{
        approval: %{id: "approval-1", approved: true},
        state: "approval-responded"
      })

    assert accepted =~ "Accepted"
    refute accepted =~ "Approve"
  end

  test "actions keep the pinned button contract" do
    html = action(%{variant: "outline"})

    assert html =~ ~s(data-slot="button")
    assert html =~ ~s(type="button")
    assert html =~ "h-8"
    assert html =~ "px-3"
    assert html =~ "border"
    refute html =~ "h-9"
    refute html =~ "px-4"
  end

  test "a caller class replaces the pinned confirmation action class" do
    html = action(%{class: "h-10 px-7 text-base"})

    assert html =~ "h-10"
    assert html =~ "px-7"
    assert html =~ "text-base"
    refute html =~ "h-8"
    refute html =~ ~r/(?:^|\s)px-3(?:\s|\")/
  end

  test "the public state contract matches the upstream ToolUIPart states" do
    state = Enum.find(Confirmation.__components__()[:confirmation][:attrs], &(&1.name == :state))

    assert state.opts[:values] ==
             ~w(
               input-streaming
               input-available
               approval-requested
               approval-responded
               output-available
               output-denied
               output-error
             )
  end

  defp confirmation(assigns) do
    assigns = Map.merge(%{inner_block: [slot("Confirmation")]}, assigns)
    render_component(&Confirmation.confirmation/1, assigns)
  end

  defp request(state) do
    render_component(&Confirmation.confirmation_request/1, %{
      state: state,
      inner_block: [slot("Request approval")]
    })
  end

  defp accepted(approval, state) do
    render_component(&Confirmation.confirmation_accepted/1, %{
      approval: approval,
      state: state,
      inner_block: [slot("Accepted")]
    })
  end

  defp rejected(approval, state) do
    render_component(&Confirmation.confirmation_rejected/1, %{
      approval: approval,
      state: state,
      inner_block: [slot("Rejected")]
    })
  end

  defp actions(state) do
    render_component(&Confirmation.confirmation_actions/1, %{
      state: state,
      inner_block: [slot("Approve")]
    })
  end

  defp action(assigns) do
    assigns = Map.merge(%{inner_block: [slot("Approve")]}, assigns)
    render_component(&Confirmation.confirmation_action/1, assigns)
  end

  defp composed_confirmation(assigns) do
    ~H"""
    <Confirmation.confirmation approval={@approval} state={@state}>
      <Confirmation.confirmation_title>
        <Confirmation.confirmation_request state={@state}>Request approval</Confirmation.confirmation_request>
        <Confirmation.confirmation_accepted approval={@approval} state={@state}>Accepted</Confirmation.confirmation_accepted>
        <Confirmation.confirmation_rejected approval={@approval} state={@state}>Rejected</Confirmation.confirmation_rejected>
      </Confirmation.confirmation_title>
      <Confirmation.confirmation_actions state={@state}>
        <Confirmation.confirmation_action>Approve</Confirmation.confirmation_action>
      </Confirmation.confirmation_actions>
    </Confirmation.confirmation>
    """
  end

  defp slot(contents), do: %{__slot__: :inner_block, inner_block: fn _, _ -> contents end}
end

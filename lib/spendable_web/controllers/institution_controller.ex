defmodule SpendableWeb.InstitutionController do
  use SpendableWeb, :controller

  alias Spendable.Requisitions
  alias Ecto.UUID
  alias Gocardless.GocardlessApi
  alias GocardlessApi.PostRequisitionRequest
  alias GocardlessApi.PostAgreementRequest
  alias Spendable.Accounts

  def login(conn, %{"id" => id}) do
    {:ok, institution} = Gocardless.Client.get_institution(id)

    {:ok, agreement} =
      Gocardless.Client.create_agreement(%PostAgreementRequest{
        institution_id: institution.id,
        max_historical_days: institution.transaction_total_days,
        access_valid_for_days: institution.max_access_valid_for_days,
        access_scope: ["balances", "details", "transactions"]
      })

    {:ok, requisition} =
      Gocardless.Client.create_requisition(%PostRequisitionRequest{
        agreement: agreement.id,
        institution_id: institution.id,
        reference: UUID.generate(),
        user_language: "de",
        redirect: ""
      })

    case conn.assigns[:current_user]
         |> Requisitions.create_requisition(%{
           requisition_id: requisition.id,
           institution_id: institution.id,
           name: institution.name,
           reference: requisition.reference
         }) do
      {:ok, _} ->
        conn |> redirect(external: requisition.link)

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Error creating requisition.")
        |> redirect(to: "/dashboard")
    end
  end

  def callback(conn, %{"reference" => reference}) do
    user = conn.assigns[:current_user]

    user
    |> Requisitions.get_by_reference(reference)
    |> case do
      nil ->
        conn
        |> put_flash(:error, "Reference not found.")
        |> redirect(to: "/dashboard")

      requisition ->
        requisition |> Requisitions.verify_requisition()

        conn
        |> put_flash(:info, "Successfully connected.")
        |> redirect(to: "/dashboard")
    end
  end
end

defmodule SpendableWeb.InstitutionController do
  use SpendableWeb, :controller

  alias Spendable.Accounts
  alias Spendable.Requisitions
  alias Ecto.UUID
  alias Gocardless.GocardlessApi
  alias GocardlessApi.PostRequisitionRequest
  alias GocardlessApi.PostAgreementRequest

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
        case verify_requisition(user, requisition) do
          {:ok, _} ->
            conn
            |> put_flash(:info, "Successfully connected.")
            |> redirect(to: "/dashboard")

          {:error, _} ->
            conn
            |> put_flash(:error, "Error verifying requisition.")
            |> redirect(to: "/dashboard")
        end
    end
  end

  defp verify_requisition(user, requisition) do
    case Gocardless.Client.get_requisition(requisition.requisition_id) do
      {:ok, r} ->
        user |> fetch_and_create_accounts(r.accounts, requisition)
        requisition |> Requisitions.verify_requisition()

      {:error, _} ->
        {:error, "Error fetching requisition"}
    end
  end

  defp fetch_and_create_accounts(user, account_ids, requisition) do
    account_ids
    |> Enum.each(fn account_id ->
      account =
        case Gocardless.Client.get_account_details(account_id) do
          {:error, _} ->
            %{
              account_id: account_id,
              iban: "",
              currency: "EUR",
              owner_name: "John Doe",
              product: "Checking Account",
              bic: "",
              type: :gocardless
            }

          {:ok, account} ->
            %{
              account_id: account_id,
              iban: account.iban,
              currency: account.currency,
              owner_name: account.owner_name,
              product: account.product,
              bic: account.bic,
              type: :gocardless
            }
        end

      Accounts.upsert_account(user, requisition, account)
    end)
  end
end

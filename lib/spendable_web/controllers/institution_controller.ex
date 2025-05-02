defmodule SpendableWeb.InstitutionController do
  use SpendableWeb, :controller

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
        case verify_requisition(requisition) do
          {:error, _} ->
            conn
            |> put_flash(:error, "Error verifying requisition.")
            |> redirect(to: "/dashboard")

          {:ok, _} ->
            conn
            |> put_flash(:info, "Successfully connected.")
            |> redirect(to: "/dashboard")
        end
    end
  end

  defp verify_requisition(requisition) do
    case Gocardless.Client.get_requisition(requisition.requisition_id) do
      {:ok, r} ->
        r.accounts |> fetch_and_create_accounts()

      {:error, _} ->
        {:error, "Error fetching requisition"}
    end

    requisition |> Requisitions.verify_requisition()
  end

  defp fetch_and_create_accounts(requisition) do
    requisition.accounts
    |> Enum.each(fn account_id ->
      {:ok, account} =
        Gocardless.Client.get_account_details(account_id)

      account = %{
        account_id: account_id,
        iban: account.iban,
        currency: account.currency,
        owner_name: account.owner_name,
        product: account.product,
        bic: account.bic,
        requisition_id: requisition.id,
        user_id: requisition.user_id,
        type: :gocardless
      }

      # TODO: save account to database
    end)
  end
end

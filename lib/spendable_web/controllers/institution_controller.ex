defmodule SpendableWeb.InstitutionController do
  use SpendableWeb, :controller

  alias Gocardless.GocardlessApi
  alias GocardlessApi.PostRequisitionRequest
  alias GocardlessApi.PostAgreementRequest

  def init(_) do
  end

  def login(conn, _params) do
    id = "foobar"
    {:ok, institution} = Gocardless.Client.get_institution(id)

    {:ok, agreement} =
      Gocardless.Client.create_agreement(%PostAgreementRequest{
        institution_id: institution.id,
        max_historical_days: institution.max_historical_days,
        access_valid_for_days: institution.access_valid_for_days,
        access_scope: ["balances", "details", "transactions"]
      })

    {:ok, requisition} =
      Gocardless.Client.create_requisition(%PostRequisitionRequest{
        agreement_id: agreement.id,
        institution_id: institution.id,
        reference: "Spendable",
        redirect: "https://localhost:4001/institution/callback",
        user_language: "en"
      })

    redirect(conn, external: requisition.redirect)
  end

  def callback(conn, _params) do
    IO.inspect(conn.params, label: "Callback Params")
  end
end

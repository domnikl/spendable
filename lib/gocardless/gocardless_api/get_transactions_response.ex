defmodule Gocardless.GocardlessApi.GetTransactionsResponse do
  @type t :: [
          %__MODULE__{
            internal_transaction_id: String.t(),
            booking_date: String.t(),
            value_date: String.t(),
            transaction_amount:
              Gocardless.GocardlessApi.GetTransactionsResponse.TransactionAmount.t(),
            creditor_name: String.t(),
            creditor_account: Gocardless.GocardlessApi.GetTransactionsResponse.Account.t(),
            debtor_name: String.t(),
            debtor_account: Gocardless.GocardlessApi.GetTransactionsResponse.Account.t(),
            remittance_information_unstructured: String.t(),
            purpose_code: String.t()
          }
        ]

  defstruct internal_transaction_id: nil,
            booking_date: nil,
            value_date: nil,
            transaction_amount: nil,
            creditor_name: nil,
            creditor_account: nil,
            debtor_name: nil,
            debtor_account: nil,
            remittance_information_unstructured: nil,
            purpose_code: nil

  def new(json_response) do
    transactions = Map.get(json_response, "transactions")

    booked =
      transactions
      |> Map.get("booked")
      |> Enum.map(&new_transaction/1)

    pending =
      transactions
      |> Map.get("pending")
      |> Enum.map(&new_transaction/1)

    booked ++ pending
  end

  defp new_transaction(json_response) do
    IO.inspect(json_response, label: "Transaction in new_transaction")

    %__MODULE__{
      internal_transaction_id: Map.get(json_response, "internalTransactionId"),
      booking_date: Map.get(json_response, "bookingDate"),
      value_date: Map.get(json_response, "valueDate"),
      transaction_amount:
        Gocardless.GocardlessApi.GetTransactionsResponse.TransactionAmount.new(
          Map.get(json_response, "transactionAmount")
        ),
      creditor_name: Map.get(json_response, "creditorName"),
      creditor_account:
        Gocardless.GocardlessApi.GetTransactionsResponse.Account.new(
          Map.get(json_response, "creditorAccount")
        ),
      debtor_name: Map.get(json_response, "debtorName"),
      debtor_account:
        Gocardless.GocardlessApi.GetTransactionsResponse.Account.new(
          Map.get(json_response, "debtorAccount")
        ),
      remittance_information_unstructured:
        Map.get(json_response, "remittanceInformationUnstructured"),
      purpose_code: Map.get(json_response, "purposeCode")
    }
  end
end

defmodule Gocardless.GocardlessApi.GetTransactionsResponse.TransactionAmount do
  @type t :: %__MODULE__{
          amount: integer(),
          currency: String.t()
        }

  defstruct amount: nil,
            currency: nil

  def new(json_response) do
    %__MODULE__{
      amount: Map.get(json_response, "amount"),
      currency: Map.get(json_response, "currency")
    }
  end
end

defmodule Gocardless.GocardlessApi.GetTransactionsResponse.Account do
  @type t :: %__MODULE__{
          iban: String.t()
        }

  defstruct iban: nil

  def new(json_response) do
    %__MODULE__{
      iban: Map.get(json_response, "iban")
    }
  end
end

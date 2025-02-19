defmodule Verk.Job do
  @moduledoc """
  The Job struct.

  Set `config :verk, max_retry_count: value` on your config file to set the default max
  amount of retries on all your `Verk.Job` when none is informed. Defaults at `25`.
  """

  @keys [
    error_message: nil,
    failed_at: nil,
    retry_count: 0,
    queue: nil,
    class: nil,
    args: [],
    jid: nil,
    finished_at: nil,
    enqueued_at: nil,
    retried_at: nil,
    created_at: nil,
    error_backtrace: nil,
    max_retry_count: nil
  ]

  @string_keys @keys |> Keyword.keys() |> Enum.map(&Atom.to_string/1)

  @type t :: %__MODULE__{
          error_message: String.t(),
          failed_at: DateTime.t(),
          retry_count: non_neg_integer,
          queue: String.t(),
          class: String.t() | atom,
          jid: String.t(),
          finished_at: DateTime.t(),
          retried_at: DateTime.t(),
          error_backtrace: String.t()
        }
  defstruct [:original_json | @keys]

  @doc """
  Encode the struct to a JSON string, raising if there is an error
  """
  @spec encode!(t) :: binary
  def encode!(job = %__MODULE__{}) do
    job
    |> Map.from_struct()
    |> Map.take(Keyword.keys(@keys))
    # We wrap the args so there is no issue with cJson on Redis side
    # It's just an opaque string as far as Redis is concerned
    # |> Map.update!(:args, &Jason.encode!(&1))
    # |> Jason.encode!()
    |> Map.update!(:args, &Jsonrs.encode!(&1))
    |> Jsonrs.encode!()
  end

  @doc """
  Decode the JSON payload storing the original json as part of the struct.
  """
  @spec decode(binary) :: {:ok, %__MODULE__{}} | {:error, Jsonrs.DecodeError.t()}
  def decode(payload) do
    with {:ok, map} <- Jsonrs.decode(payload),
         {:ok, args} <- unwrap_args(map["args"]) do
      fields =
        map
        |> Map.take(@string_keys)
        |> Map.update!("args", fn _ -> args end)
        |> Map.new(fn {k, v} -> {String.to_existing_atom(k), v} end)

      job =
        %__MODULE__{}
        |> struct(fields)
        |> build(payload)

      {:ok, job}
    end
  end

  @doc """
  Decode the JSON payload storing the original json as part of the struct, raising if there is an error
  """
  @spec decode!(binary) :: %__MODULE__{}
  def decode!(payload) do
    case decode(payload) do
      {:ok, job} -> job
      {:error, error} -> raise error
    end
  end

  def default_max_retry_count do
    Confex.get_env(:verk, :max_retry_count, 25)
  end

  defp unwrap_args(wrapped_args) when is_binary(wrapped_args),
    do: Jsonrs.decode(wrapped_args, keys: Application.get_env(:verk, :args_keys, :strings))

  defp unwrap_args(args), do: {:ok, args}

  defp build(job = %{args: %{}}, payload) do
    build(%{job | args: []}, payload)
  end

  defp build(job, payload) do
    %Verk.Job{job | original_json: payload}
  end
end

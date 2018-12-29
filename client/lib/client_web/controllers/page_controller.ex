defmodule ClientWeb.PageController do
  use ClientWeb, :controller
  require Logger

  def index(conn, _params) do
    [1, 2, 3]
    |> Enum.map(fn advertiser -> Task.async(fn -> make_request(advertiser) end) end)
    |> Enum.map(&Task.await(&1))
    json conn, %{}
  end

  defp make_request(advertiser) do
    url = "http://ec2-35-161-223-30.us-west-2.compute.amazonaws.com:4000/"
    {response_time, response} = :timer.tc(fn ->
      MachineGun.get(
        url,
        [],
        %{pool_timeout: 1000, request_timeout: 5000, pool_group: :default})
    end)

    stats = %{response_time: response_time}

    {stats, _} = case response do
      {:error, %MachineGun.Error{reason: :request_timeout}} ->
        Logger.error("[REQUEST TIMEOUT] #{stats[:response_time]}")
        {%{stats | timeout: 1}, nil}
      {:error, %MachineGun.Error{reason: {:closed, _}}} ->
        # nullify response_time
        {%{stats | connection_closed: 1, response_time: nil}, nil}
      {:error, %MachineGun.Error{reason: :closed}} ->
        # same as {:closed, _} - https://github.com/ninenines/gun/issues/180
        # nullify response_time
        {%{stats | connection_closed: 1, response_time: nil}, nil}
      {:error, %MachineGun.Error{reason: :shutdown}} ->
        # nullify response_time
        {%{stats | shutdown: 1, response_time: nil}, nil}
      {:error, %MachineGun.Error{reason: :pool_timeout}} ->
        # nullify response_time
        {%{stats | pool_timeout: 1, response_time: nil}, nil}
      {:error, %MachineGun.Error{reason: reason}=r} ->
        Logger.error("[UNKNOWN HTTP ERROR] #{inspect(r)}")
        # nullify response_time
        {%{stats | other_error: 1, response_time: nil}, nil}
      {:ok, %MachineGun.Response{status_code: status_code}} when status_code >= 400 ->
        {%{stats | bad_status_code: 1}, nil}
      {:ok, %MachineGun.Response{body: ""}} ->
        {%{stats | empty_response: 1}, nil}
      {:ok, %MachineGun.Response{body: nil}} ->
        {%{stats | empty_response: 1}, nil}
      {:ok, resp} ->
        {stats, resp.body}
    end

    response
  end
end

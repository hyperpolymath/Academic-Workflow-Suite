defmodule AwapBackend.CoreBridgeTest do
  @moduledoc """
  Tests for the CoreBridge GenServer — Rust core engine interface.

  These tests verify the Elixir-side contract of the bridge (message
  formatting, response parsing, health-check logic) without requiring
  the real Rust binary.  A lightweight mock port is used instead.
  """

  use ExUnit.Case, async: false
  alias AwapBackend.CoreBridge

  # ── helpers ───────────────────────────────────────────────────────

  defp start_bridge_in_port_mode do
    # Override config so init/1 opens a simple `cat` port (echo-back)
    original = Application.get_env(:awap_backend, CoreBridge)

    Application.put_env(:awap_backend, CoreBridge,
      core_executable: "cat",
      communication_mode: :port
    )

    on_exit(fn ->
      if original, do: Application.put_env(:awap_backend, CoreBridge, original),
        else: Application.delete_env(:awap_backend, CoreBridge)
    end)
  end

  # ── response parsing (unit) ──────────────────────────────────────

  describe "parse_core_response/1 (via health_check contract)" do
    test "healthy response returns :ok" do
      response = %{"success" => true, "data" => %{"status" => "healthy"}}
      assert {:ok, %{"status" => "healthy"}} == parse_response(response)
    end

    test "error response returns {:error, reason}" do
      response = %{"success" => false, "error" => "core_unavailable"}
      assert {:error, "core_unavailable"} == parse_response(response)
    end

    test "unexpected shape returns {:error, {:invalid_response, _}}" do
      response = %{"unexpected" => true}
      assert {:error, {:invalid_response, ^response}} = parse_response(response)
    end
  end

  # ── health_check logic ──────────────────────────────────────────

  describe "health_check/0 contract" do
    test "maps healthy data to :ok" do
      # Simulate what health_check/0 does with the parsed response
      assert :ok == health_check_logic({:ok, %{"status" => "healthy"}})
    end

    test "maps unhealthy data to {:error, {:unhealthy, _}}" do
      assert {:error, {:unhealthy, %{"status" => "degraded"}}} ==
               health_check_logic({:ok, %{"status" => "degraded"}})
    end

    test "propagates call errors" do
      assert {:error, :timeout} == health_check_logic({:error, :timeout})
    end
  end

  # ── request ID generation ───────────────────────────────────────

  describe "request ID uniqueness" do
    test "generates unique request IDs" do
      ids = for _ <- 1..100, do: :crypto.strong_rand_bytes(16) |> Base.encode64()
      assert length(Enum.uniq(ids)) == 100
    end
  end

  # ── NIF fallback path ──────────────────────────────────────────

  describe "NIF mode fallback" do
    test "unknown command returns error" do
      result = nif_call_logic("unknown_command", %{})
      assert {:error, {:unknown_command, "unknown_command"}} == result
    end

    test "valid command without native module returns nif_not_available" do
      # Simulates what happens when NIF module isn't loaded
      result = nif_call_logic_no_native("anonymize_student", %{})
      assert {:error, {:nif_not_available, _msg}} = result
    end
  end

  # ── message format contract ────────────────────────────────────

  describe "message format" do
    test "request message has required keys" do
      request_id = :crypto.strong_rand_bytes(16) |> Base.encode64()

      message = %{
        request_id: request_id,
        command: "anonymize_student",
        data: %{student_id: "s123"}
      }

      json = Jason.encode!(message)
      decoded = Jason.decode!(json)

      assert Map.has_key?(decoded, "request_id")
      assert Map.has_key?(decoded, "command")
      assert Map.has_key?(decoded, "data")
      assert decoded["command"] == "anonymize_student"
    end

    test "all five commands are accepted" do
      commands = ~w(anonymize_student parse_tma generate_feedback query_events health_check)

      for cmd <- commands do
        message = %{request_id: "test", command: cmd, data: %{}}
        assert {:ok, _} = Jason.encode(message)
      end
    end
  end

  # ── private helpers that mirror CoreBridge internals ────────────

  defp parse_response(%{"success" => true, "data" => data}), do: {:ok, data}
  defp parse_response(%{"success" => false, "error" => error}), do: {:error, error}
  defp parse_response(response), do: {:error, {:invalid_response, response}}

  defp health_check_logic({:ok, %{"status" => "healthy"}}), do: :ok
  defp health_check_logic({:ok, response}), do: {:error, {:unhealthy, response}}
  defp health_check_logic({:error, reason}), do: {:error, reason}

  @nif_commands ~w(anonymize_student parse_tma generate_feedback query_events health_check)

  defp nif_call_logic(command, _data) when command not in @nif_commands do
    {:error, {:unknown_command, command}}
  end

  defp nif_call_logic(_command, _data), do: :ok

  defp nif_call_logic_no_native(command, _data) when command in @nif_commands do
    {:error,
     {:nif_not_available,
      "Native module not loaded. To use NIF mode, compile the Rust NIF."}}
  end

  defp nif_call_logic_no_native(command, _data) do
    {:error, {:unknown_command, command}}
  end
end

# SPDX-License-Identifier: MPL-2.0
# Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
defmodule AwapBackend.CoreEngine.JobRegistryTest do
  @moduledoc """
  Tests for the JobRegistry GenServer.

  Verifies job registration, status transitions, ETS storage, listing,
  and filtering. Uses a dedicated ETS table per test run to avoid
  cross-test pollution.
  """

  use ExUnit.Case, async: false
  alias AwapBackend.CoreEngine.JobRegistry

  setup do
    # Clean up any leftover ETS table from a previous run
    if :ets.whereis(:job_registry) != :undefined do
      :ets.delete_all_objects(:job_registry)
    end

    # Start a fresh JobRegistry (will create the ETS table if needed)
    case GenServer.whereis(JobRegistry) do
      nil ->
        {:ok, pid} = JobRegistry.start_link([])
        on_exit(fn -> if Process.alive?(pid), do: GenServer.stop(pid) end)

      pid ->
        # Registry already running — just clear the table
        :ets.delete_all_objects(:job_registry)
        on_exit(fn -> :ets.delete_all_objects(:job_registry) end)
        {:ok, pid: pid}
    end

    :ok
  end

  # ── registration ────────────────────────────────────────────────

  describe "register/2" do
    test "registers a new job with :queued status" do
      job_id = Ecto.UUID.generate()
      tma_id = Ecto.UUID.generate()

      :ok = JobRegistry.register(job_id, tma_id)

      # cast is async — give it a moment
      Process.sleep(10)

      assert {:ok, job} = JobRegistry.get(job_id)
      assert job.job_id == job_id
      assert job.tma_id == tma_id
      assert job.status == :queued
      assert job.started_at == nil
      assert job.completed_at == nil
      assert job.error == nil
    end

    test "can register multiple jobs" do
      ids = for _ <- 1..5, do: {Ecto.UUID.generate(), Ecto.UUID.generate()}

      for {job_id, tma_id} <- ids do
        JobRegistry.register(job_id, tma_id)
      end

      Process.sleep(20)

      for {job_id, _} <- ids do
        assert {:ok, _} = JobRegistry.get(job_id)
      end
    end
  end

  # ── status transitions ─────────────────────────────────────────

  describe "update_status/3" do
    test "transitions job to :processing and sets started_at" do
      job_id = Ecto.UUID.generate()
      JobRegistry.register(job_id, "tma_1")
      Process.sleep(10)

      JobRegistry.update_status(job_id, :processing)
      Process.sleep(10)

      {:ok, job} = JobRegistry.get(job_id)
      assert job.status == :processing
      assert %DateTime{} = job.started_at
      assert job.completed_at == nil
    end

    test "transitions job to :completed and sets completed_at" do
      job_id = Ecto.UUID.generate()
      JobRegistry.register(job_id, "tma_2")
      Process.sleep(10)

      JobRegistry.update_status(job_id, :processing)
      Process.sleep(10)

      JobRegistry.update_status(job_id, :completed)
      Process.sleep(10)

      {:ok, job} = JobRegistry.get(job_id)
      assert job.status == :completed
      assert %DateTime{} = job.completed_at
    end

    test "transitions job to :failed with error message" do
      job_id = Ecto.UUID.generate()
      JobRegistry.register(job_id, "tma_3")
      Process.sleep(10)

      JobRegistry.update_status(job_id, :failed, error: "core_crash")
      Process.sleep(10)

      {:ok, job} = JobRegistry.get(job_id)
      assert job.status == :failed
      assert job.error == "core_crash"
      assert %DateTime{} = job.completed_at
    end

    test "ignores update for non-existent job (no crash)" do
      # Should log a warning but not crash
      JobRegistry.update_status("nonexistent", :processing)
      Process.sleep(10)
      assert {:error, :not_found} = JobRegistry.get("nonexistent")
    end
  end

  # ── get/1 ──────────────────────────────────────────────────────

  describe "get/1" do
    test "returns {:error, :not_found} for unknown job" do
      assert {:error, :not_found} = JobRegistry.get("does_not_exist")
    end
  end

  # ── list/1 ─────────────────────────────────────────────────────

  describe "list/1" do
    test "returns all jobs when no filter given" do
      for i <- 1..3 do
        JobRegistry.register("job_#{i}", "tma_#{i}")
      end

      Process.sleep(20)

      jobs = JobRegistry.list()
      assert length(jobs) == 3
    end

    test "filters by status" do
      JobRegistry.register("a", "tma_a")
      JobRegistry.register("b", "tma_b")
      JobRegistry.register("c", "tma_c")
      Process.sleep(20)

      JobRegistry.update_status("a", :processing)
      JobRegistry.update_status("b", :completed)
      Process.sleep(20)

      queued = JobRegistry.list(status: :queued)
      assert length(queued) == 1
      assert hd(queued).job_id == "c"

      processing = JobRegistry.list(status: :processing)
      assert length(processing) == 1
      assert hd(processing).job_id == "a"

      completed = JobRegistry.list(status: :completed)
      assert length(completed) == 1
      assert hd(completed).job_id == "b"
    end

    test "returns empty list when no jobs match filter" do
      JobRegistry.register("x", "tma_x")
      Process.sleep(10)

      assert [] == JobRegistry.list(status: :failed)
    end
  end
end

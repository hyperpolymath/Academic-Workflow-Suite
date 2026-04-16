defmodule AwapBackend.EventStoreTest do
  @moduledoc """
  Tests for the ETS-backed EventStore GenServer.

  Covers event appending, stream reading (forward/backward),
  subscription delivery, and reconnection logic.
  """

  use ExUnit.Case, async: false
  alias AwapBackend.EventStore

  setup do
    # Ensure clean ETS state
    for table <- [:event_store_events, :event_store_streams] do
      if :ets.whereis(table) != :undefined, do: :ets.delete_all_objects(table)
    end

    # Provide a dummy connection string so init succeeds
    Application.put_env(:awap_backend, :event_store_url, "ets://localhost")

    case GenServer.whereis(EventStore) do
      nil ->
        {:ok, pid} = EventStore.start_link([])
        on_exit(fn -> if Process.alive?(pid), do: GenServer.stop(pid) end)

      _pid ->
        # Already running — tables were cleared above
        :ok
    end

    # Give handle_continue(:connect) time to initialise ETS tables
    Process.sleep(20)

    :ok
  end

  # ── append & read round-trip ───────────────────────────────────

  describe "append_event/2 + read_stream/2" do
    test "appends and reads a single event" do
      stream = "tma-#{System.unique_integer([:positive])}"

      event = %{
        event_type: "TmaSubmitted",
        data: %{tma_id: "t1", student_id: "s1"},
        metadata: %{source: "test"},
        timestamp: DateTime.utc_now()
      }

      assert :ok = EventStore.append_event(stream, event)
      assert {:ok, [stored]} = EventStore.read_stream(stream)

      assert stored.event_type == "TmaSubmitted"
      assert stored.stream_id == stream
      assert stored.stream_version == 1
      assert stored.data == event.data
    end

    test "appends multiple events and reads them in order" do
      stream = "tma-#{System.unique_integer([:positive])}"

      events =
        for i <- 1..5 do
          %{
            event_type: "Step#{i}",
            data: %{step: i},
            metadata: %{},
            timestamp: DateTime.utc_now()
          }
        end

      for e <- events, do: EventStore.append_event(stream, e)

      {:ok, stored} = EventStore.read_stream(stream)
      assert length(stored) == 5

      # Verify ordering
      versions = Enum.map(stored, & &1.stream_version)
      assert versions == [1, 2, 3, 4, 5]

      types = Enum.map(stored, & &1.event_type)
      assert types == ["Step1", "Step2", "Step3", "Step4", "Step5"]
    end

    test "reads empty list for unknown stream" do
      assert {:ok, []} = EventStore.read_stream("nonexistent-stream")
    end
  end

  # ── read options ───────────────────────────────────────────────

  describe "read_stream/2 options" do
    setup do
      stream = "opts-#{System.unique_integer([:positive])}"

      for i <- 1..10 do
        EventStore.append_event(stream, %{
          event_type: "E#{i}",
          data: %{i: i},
          metadata: %{},
          timestamp: DateTime.utc_now()
        })
      end

      {:ok, stream: stream}
    end

    test "from_version skips earlier events", %{stream: stream} do
      {:ok, events} = EventStore.read_stream(stream, from_version: 4)
      versions = Enum.map(events, & &1.stream_version)
      assert hd(versions) == 4
    end

    test "max_count limits results", %{stream: stream} do
      {:ok, events} = EventStore.read_stream(stream, max_count: 3)
      assert length(events) == 3
    end

    test "backward direction reverses order", %{stream: stream} do
      {:ok, events} =
        EventStore.read_stream(stream, from_version: 10, direction: :backward, max_count: 5)

      versions = Enum.map(events, & &1.stream_version)
      assert versions == [10, 9, 8, 7, 6]
    end
  end

  # ── subscriptions ──────────────────────────────────────────────

  describe "subscribe/1" do
    test "subscriber receives events" do
      stream = "sub-#{System.unique_integer([:positive])}"

      :ok = EventStore.subscribe(stream)

      # Simulate the EventStore receiving an external event
      send(GenServer.whereis(EventStore), {:event, stream, %{type: "test_event"}})

      assert_receive {:event_store_event, ^stream, %{type: "test_event"}}, 500
    end

    test "multiple subscribers all receive events" do
      stream = "multi-sub-#{System.unique_integer([:positive])}"

      # Subscribe from the test process twice (simulates two subscribers)
      :ok = EventStore.subscribe(stream)
      :ok = EventStore.subscribe(stream)

      send(GenServer.whereis(EventStore), {:event, stream, %{data: "hello"}})

      # Should receive two copies (once per subscription)
      assert_receive {:event_store_event, ^stream, %{data: "hello"}}, 500
      assert_receive {:event_store_event, ^stream, %{data: "hello"}}, 500
    end
  end

  # ── stream versioning ─────────────────────────────────────────

  describe "stream versioning" do
    test "separate streams have independent version counters" do
      stream_a = "ver-a-#{System.unique_integer([:positive])}"
      stream_b = "ver-b-#{System.unique_integer([:positive])}"

      EventStore.append_event(stream_a, %{
        event_type: "A1",
        data: %{},
        metadata: %{},
        timestamp: DateTime.utc_now()
      })

      EventStore.append_event(stream_a, %{
        event_type: "A2",
        data: %{},
        metadata: %{},
        timestamp: DateTime.utc_now()
      })

      EventStore.append_event(stream_b, %{
        event_type: "B1",
        data: %{},
        metadata: %{},
        timestamp: DateTime.utc_now()
      })

      {:ok, a_events} = EventStore.read_stream(stream_a)
      {:ok, b_events} = EventStore.read_stream(stream_b)

      assert length(a_events) == 2
      assert length(b_events) == 1

      assert hd(b_events).stream_version == 1
      assert List.last(a_events).stream_version == 2
    end

    test "global sequence increases monotonically across streams" do
      stream_a = "gseq-a-#{System.unique_integer([:positive])}"
      stream_b = "gseq-b-#{System.unique_integer([:positive])}"

      EventStore.append_event(stream_a, %{
        event_type: "X",
        data: %{},
        metadata: %{},
        timestamp: DateTime.utc_now()
      })

      EventStore.append_event(stream_b, %{
        event_type: "Y",
        data: %{},
        metadata: %{},
        timestamp: DateTime.utc_now()
      })

      {:ok, [a_event]} = EventStore.read_stream(stream_a)
      {:ok, [b_event]} = EventStore.read_stream(stream_b)

      assert b_event.global_sequence > a_event.global_sequence
    end
  end
end

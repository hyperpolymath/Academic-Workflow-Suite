// SPDX-License-Identifier: MPL-2.0
// Tests for BackendClient module — fetch-based HTTP + WebSocket client

open Jest
open Expect

// ── Mock infrastructure ─────────────────────────────────────────

// Minimal mock response constructor
let mockResponse = (~status=200, ~json=Js.Obj.empty(), ~text="") => {
  {
    "status": status,
    "json": (.) => Js.Promise.resolve(json),
    "text": (.) => Js.Promise.resolve(text),
  }
}

// Global fetch spy state
let fetchCalls: ref<array<(string, {..})>> = ref([])
let fetchResponse: ref<{..}> = ref(mockResponse())

// Install mock fetch before each test
@val external globalThis: {..} = "globalThis"

let setupFetchMock = () => {
  fetchCalls := []
  globalThis["fetch"] = (. url: string, opts: {..}) => {
    fetchCalls.contents->Array.push((url, opts))
    Js.Promise.resolve(fetchResponse.contents)
  }
}

// ── Test data ───────────────────────────────────────────────────

let testBaseUrl = "https://backend.example.com"

let mockTma: Types.tma = {
  id: None,
  moduleCode: "CS101",
  assignmentNumber: "TMA-01",
  content: "This is a test TMA submission with analysis of algorithms.",
  studentId: Some("student-A1234567"),
  timestamp: 1713225600.0,
}

let mockFeedback: Types.feedback = {
  id: "feedback-001",
  tmaId: "tma-001",
  content: "Excellent analysis. Your discussion of time complexity is thorough.",
  score: Some(87.5),
  suggestions: ["Add space-complexity analysis", "Reference Knuth Ch. 3"],
  plagiarismCheck: Some({
    score: 3.2,
    matches: [],
    status: Types.Clean,
  }),
  generatedAt: 1713225700.0,
}

// ── createHeaders ───────────────────────────────────────────────

describe("BackendClient.createHeaders", () => {
  test("returns Content-Type without API key", () => {
    let headers = BackendClient.createHeaders(None)
    expect(headers["Content-Type"])->toBe("application/json")
  })

  test("includes Authorization with API key", () => {
    let headers = BackendClient.createHeaders(Some("test-key-123"))
    expect(headers["Content-Type"])->toBe("application/json")
    expect(headers["Authorization"])->toBe("Bearer test-key-123")
  })
})

// ── submitTma ───────────────────────────────────────────────────

describe("BackendClient.submitTma", () => {
  beforeEach(() => setupFetchMock())

  testAsync("submits TMA and returns ID on success", done => {
    fetchResponse :=
      mockResponse(~status=201, ~json={"id": "tma-new-001"})

    BackendClient.submitTma(testBaseUrl, Some("key"), mockTma)
    ->Promise.then(result => {
      switch result {
      | Ok(id) => expect(id)->toBe("tma-new-001")
      | Error(msg) => fail(msg)
      }

      // Verify URL
      let (url, _) = fetchCalls.contents[0]
      expect(url)->toBe(`${testBaseUrl}/api/tmas`)

      done()
      Promise.resolve()
    })
    ->ignore
  })

  testAsync("returns error on non-2xx status", done => {
    fetchResponse :=
      mockResponse(~status=422, ~text="Validation failed: moduleCode required")

    BackendClient.submitTma(testBaseUrl, None, mockTma)
    ->Promise.then(result => {
      switch result {
      | Ok(_) => fail("Expected error")
      | Error(msg) =>
        expect(msg)->toContain("Failed to submit TMA")
        expect(msg)->toContain("Validation failed")
      }
      done()
      Promise.resolve()
    })
    ->ignore
  })

  testAsync("handles network errors gracefully", done => {
    globalThis["fetch"] = (. _url: string, _opts: {..}) => {
      Js.Promise.reject(Js.Exn.raiseError("Network unreachable"))
    }

    BackendClient.submitTma(testBaseUrl, None, mockTma)
    ->Promise.then(result => {
      switch result {
      | Ok(_) => fail("Expected error")
      | Error(msg) => expect(msg)->toContain("Failed to submit TMA")
      }
      done()
      Promise.resolve()
    })
    ->ignore
  })
})

// ── getFeedback ─────────────────────────────────────────────────

describe("BackendClient.getFeedback", () => {
  beforeEach(() => setupFetchMock())

  testAsync("parses feedback response with plagiarism data", done => {
    fetchResponse :=
      mockResponse(
        ~status=200,
        ~json={
          "id": "feedback-001",
          "tmaId": "tma-001",
          "content": "Good work",
          "score": Some(87.5),
          "suggestions": ["Expand conclusion"],
          "plagiarismCheck": Some({
            "score": 3.2,
            "matches": [],
            "status": "clean",
          }),
          "generatedAt": 1713225700.0,
        },
      )

    BackendClient.getFeedback(testBaseUrl, None, "tma-001")
    ->Promise.then(result => {
      switch result {
      | Ok(fb) => {
          expect(fb.id)->toBe("feedback-001")
          expect(fb.tmaId)->toBe("tma-001")
          expect(fb.score)->toEqual(Some(87.5))
        }
      | Error(msg) => fail(msg)
      }
      done()
      Promise.resolve()
    })
    ->ignore
  })

  testAsync("returns error for 404", done => {
    fetchResponse :=
      mockResponse(~status=404, ~text="Not found")

    BackendClient.getFeedback(testBaseUrl, None, "nonexistent")
    ->Promise.then(result => {
      switch result {
      | Ok(_) => fail("Expected error")
      | Error(msg) => expect(msg)->toContain("Failed to get feedback")
      }
      done()
      Promise.resolve()
    })
    ->ignore
  })
})

// ── requestFeedbackGeneration ──────────────────────────────────

describe("BackendClient.requestFeedbackGeneration", () => {
  beforeEach(() => setupFetchMock())

  testAsync("sends POST and returns Ok on success", done => {
    fetchResponse := mockResponse(~status=202)

    BackendClient.requestFeedbackGeneration(testBaseUrl, Some("key"), "tma-001")
    ->Promise.then(result => {
      switch result {
      | Ok() => {
          let (url, opts) = fetchCalls.contents[0]
          expect(url)->toBe(`${testBaseUrl}/api/feedback/generate`)
          expect(opts["method"])->toBe("POST")
        }
      | Error(msg) => fail(msg)
      }
      done()
      Promise.resolve()
    })
    ->ignore
  })

  testAsync("returns error on 500", done => {
    fetchResponse :=
      mockResponse(~status=500, ~text="Internal server error")

    BackendClient.requestFeedbackGeneration(testBaseUrl, None, "tma-001")
    ->Promise.then(result => {
      switch result {
      | Ok() => fail("Expected error")
      | Error(msg) => expect(msg)->toContain("Failed to request feedback generation")
      }
      done()
      Promise.resolve()
    })
    ->ignore
  })
})

// ── listTmas ────────────────────────────────────────────────────

describe("BackendClient.listTmas", () => {
  beforeEach(() => setupFetchMock())

  testAsync("lists all TMAs without filter", done => {
    fetchResponse :=
      mockResponse(
        ~status=200,
        ~json=[
          {
            "id": "tma-1",
            "moduleCode": "CS101",
            "assignmentNumber": "TMA-01",
            "content": "Answer 1",
            "studentId": Some("s1"),
            "timestamp": 1713225600.0,
          },
        ],
      )

    BackendClient.listTmas(testBaseUrl, None, None)
    ->Promise.then(result => {
      switch result {
      | Ok(tmas) => {
          expect(Array.length(tmas))->toBe(1)
          expect(tmas[0].moduleCode)->toBe("CS101")
        }
      | Error(msg) => fail(msg)
      }

      // Verify no query parameter
      let (url, _) = fetchCalls.contents[0]
      expect(url)->toBe(`${testBaseUrl}/api/tmas`)

      done()
      Promise.resolve()
    })
    ->ignore
  })

  testAsync("appends moduleCode as query parameter", done => {
    fetchResponse := mockResponse(~status=200, ~json=[])

    BackendClient.listTmas(testBaseUrl, None, Some("CS201"))
    ->Promise.then(_result => {
      let (url, _) = fetchCalls.contents[0]
      expect(url)->toBe(`${testBaseUrl}/api/tmas?moduleCode=CS201`)
      done()
      Promise.resolve()
    })
    ->ignore
  })

  testAsync("handles empty list", done => {
    fetchResponse := mockResponse(~status=200, ~json=[])

    BackendClient.listTmas(testBaseUrl, None, None)
    ->Promise.then(result => {
      switch result {
      | Ok(tmas) => expect(Array.length(tmas))->toBe(0)
      | Error(msg) => fail(msg)
      }
      done()
      Promise.resolve()
    })
    ->ignore
  })
})

// ── healthCheck ─────────────────────────────────────────────────

describe("BackendClient.healthCheck", () => {
  beforeEach(() => setupFetchMock())

  testAsync("returns Ok(true) for 200", done => {
    fetchResponse := mockResponse(~status=200)

    BackendClient.healthCheck(testBaseUrl)
    ->Promise.then(result => {
      switch result {
      | Ok(healthy) => expect(healthy)->toBe(true)
      | Error(msg) => fail(msg)
      }
      done()
      Promise.resolve()
    })
    ->ignore
  })

  testAsync("returns error for non-200", done => {
    fetchResponse := mockResponse(~status=503)

    BackendClient.healthCheck(testBaseUrl)
    ->Promise.then(result => {
      switch result {
      | Ok(_) => fail("Expected error")
      | Error(msg) => expect(msg)->toBe("Backend is not healthy")
      }
      done()
      Promise.resolve()
    })
    ->ignore
  })

  testAsync("returns error on network failure", done => {
    globalThis["fetch"] = (. _url: string, _opts: {..}) => {
      Js.Promise.reject(Js.Exn.raiseError("ECONNREFUSED"))
    }

    BackendClient.healthCheck(testBaseUrl)
    ->Promise.then(result => {
      switch result {
      | Ok(_) => fail("Expected error")
      | Error(msg) => expect(msg)->toContain("Health check failed")
      }
      done()
      Promise.resolve()
    })
    ->ignore
  })
})

// ── Integration: full workflow ──────────────────────────────────

describe("BackendClient Integration", () => {
  beforeEach(() => setupFetchMock())

  testAsync("full workflow: submit TMA → request feedback → get feedback", done => {
    let callIndex = ref(0)

    // Each fetch call returns a different response
    globalThis["fetch"] = (. url: string, opts: {..}) => {
      fetchCalls.contents->Array.push((url, opts))
      let idx = callIndex.contents
      callIndex := idx + 1

      let response = switch idx {
      | 0 => mockResponse(~status=201, ~json={"id": "tma-workflow-1"})
      | 1 => mockResponse(~status=202)
      | 2 =>
        mockResponse(
          ~status=200,
          ~json={
            "id": "fb-1",
            "tmaId": "tma-workflow-1",
            "content": "Well done",
            "score": Some(92.0),
            "suggestions": [],
            "plagiarismCheck": None,
            "generatedAt": 1713225800.0,
          },
        )
      | _ => mockResponse(~status=500)
      }

      Js.Promise.resolve(response)
    }

    // Step 1: Submit
    BackendClient.submitTma(testBaseUrl, Some("key"), mockTma)
    ->Promise.then(submitResult => {
      switch submitResult {
      | Ok(tmaId) => {
          expect(tmaId)->toBe("tma-workflow-1")

          // Step 2: Request feedback generation
          BackendClient.requestFeedbackGeneration(testBaseUrl, Some("key"), tmaId)
        }
      | Error(msg) => {
          fail(msg)
          Promise.resolve(Error(msg))
        }
      }
    })
    ->Promise.then(genResult => {
      switch genResult {
      | Ok() => {
          // Step 3: Get feedback
          BackendClient.getFeedback(testBaseUrl, Some("key"), "tma-workflow-1")
        }
      | Error(msg) => {
          fail(msg)
          Promise.resolve(Error(msg))
        }
      }
    })
    ->Promise.then(fbResult => {
      switch fbResult {
      | Ok(fb) => {
          expect(fb.content)->toBe("Well done")
          expect(fb.score)->toEqual(Some(92.0))
        }
      | Error(msg) => fail(msg)
      }

      // Verify all three calls were made
      expect(Array.length(fetchCalls.contents))->toBe(3)

      done()
      Promise.resolve()
    })
    ->ignore
  })
})

// HTTP client for AWAP backend API

// Fetch API bindings
@val
external fetch: (string, {..}) => promise<{..}> = "fetch"

// Helper to create headers
let createHeaders = (apiKey: option<string>): {..} => {
  let headers = {"Content-Type": "application/json"}

  switch apiKey {
  | Some(key) => {
      ...headers,
      "Authorization": `Bearer ${key}`,
    }
  | None => headers
  }
}

// POST TMA to backend
let submitTma = async (
  baseUrl: string,
  apiKey: option<string>,
  tma: Types.tma,
): result<string, string> => {
  try {
    // Prepare request body
    let body = {
      "moduleCode": tma.moduleCode,
      "assignmentNumber": tma.assignmentNumber,
      "content": tma.content,
      "studentId": tma.studentId,
      "timestamp": tma.timestamp,
    }

    let options = {
      "method": "POST",
      "headers": createHeaders(apiKey),
      "body": Types.Json.stringify(body),
    }

    let response = await fetch(`${baseUrl}/api/tmas`, options)
    let status = response["status"]

    if status >= 200 && status < 300 {
      let json = await response["json"](.)
      let tmaId = json["id"]
      Ok(tmaId)
    } else {
      let errorText = await response["text"](.)
      Error(`Failed to submit TMA: ${errorText}`)
    }
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Network error")
      Error(`Failed to submit TMA: ${message}`)
    }
  | _ => Error("Unexpected error submitting TMA")
  }
}

// GET feedback for a TMA
let getFeedback = async (
  baseUrl: string,
  apiKey: option<string>,
  tmaId: string,
): result<Types.feedback, string> => {
  try {
    let options = {
      "method": "GET",
      "headers": createHeaders(apiKey),
    }

    let response = await fetch(`${baseUrl}/api/tmas/${tmaId}/feedback`, options)
    let status = response["status"]

    if status >= 200 && status < 300 {
      let json = await response["json"](.)

      // Parse JSON response into Types.feedback
      let feedback: Types.feedback = {
        id: json["id"],
        tmaId: json["tmaId"],
        content: json["content"],
        score: json["score"],
        suggestions: json["suggestions"],
        plagiarismCheck: switch json["plagiarismCheck"] {
        | Some(pc) =>
          Some({
            score: pc["score"],
            matches: pc["matches"]->Array.map(m => {
              {
                source: m["source"],
                similarity: m["similarity"],
                excerpt: m["excerpt"],
              }: Types.plagiarismMatch
            }),
            status: switch pc["status"] {
            | "clean" => Types.Clean
            | "suspicious" => Types.Suspicious
            | "flagged" => Types.Flagged
            | _ => Types.Clean
            },
          })
        | None => None
        },
        generatedAt: json["generatedAt"],
      }

      Ok(feedback)
    } else {
      let errorText = await response["text"](.)
      Error(`Failed to get feedback: ${errorText}`)
    }
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Network error")
      Error(`Failed to get feedback: ${message}`)
    }
  | _ => Error("Unexpected error getting feedback")
  }
}

// Request feedback generation
let requestFeedbackGeneration = async (
  baseUrl: string,
  apiKey: option<string>,
  tmaId: string,
): result<unit, string> => {
  try {
    let options = {
      "method": "POST",
      "headers": createHeaders(apiKey),
      "body": Types.Json.stringify({"tmaId": tmaId}),
    }

    let response = await fetch(`${baseUrl}/api/feedback/generate`, options)
    let status = response["status"]

    if status >= 200 && status < 300 {
      Ok()
    } else {
      let errorText = await response["text"](.)
      Error(`Failed to request feedback generation: ${errorText}`)
    }
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Network error")
      Error(`Failed to request feedback generation: ${message}`)
    }
  | _ => Error("Unexpected error requesting feedback generation")
  }
}

// List all TMAs for a module
let listTmas = async (
  baseUrl: string,
  apiKey: option<string>,
  moduleCode: option<string>,
): result<array<Types.tma>, string> => {
  try {
    let url = switch moduleCode {
    | Some(code) => `${baseUrl}/api/tmas?moduleCode=${code}`
    | None => `${baseUrl}/api/tmas`
    }

    let options = {
      "method": "GET",
      "headers": createHeaders(apiKey),
    }

    let response = await fetch(url, options)
    let status = response["status"]

    if status >= 200 && status < 300 {
      let json = await response["json"](.)
      let tmas = json->Array.map(item => {
        {
          id: Some(item["id"]),
          moduleCode: item["moduleCode"],
          assignmentNumber: item["assignmentNumber"],
          content: item["content"],
          studentId: item["studentId"],
          timestamp: item["timestamp"],
        }: Types.tma
      })

      Ok(tmas)
    } else {
      let errorText = await response["text"](.)
      Error(`Failed to list TMAs: ${errorText}`)
    }
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Network error")
      Error(`Failed to list TMAs: ${message}`)
    }
  | _ => Error("Unexpected error listing TMAs")
  }
}

// WebSocket client for real-time updates
module WebSocket = {
  @new external create: string => {..} = "WebSocket"

  type ws = {..}

  type messageHandler = string => unit
  type errorHandler = {..} => unit
  type closeHandler = unit => unit

  let connect = (
    baseUrl: string,
    apiKey: option<string>,
    onMessage: messageHandler,
    onError: errorHandler,
    onClose: closeHandler,
  ): ws => {
    // Convert http(s) to ws(s)
    let wsUrl = baseUrl->String.replace("http://", "ws://")->String.replace("https://", "wss://")

    let wsUrl = switch apiKey {
    | Some(key) => `${wsUrl}/ws?token=${key}`
    | None => `${wsUrl}/ws`
    }

    let ws = create(wsUrl)

    ws["onmessage"] = (. event) => {
      let data = event["data"]
      onMessage(data)
    }

    ws["onerror"] = (. error) => {
      onError(error)
    }

    ws["onclose"] = (. _) => {
      onClose()
    }

    ws
  }

  let send = (ws: ws, message: string): unit => {
    ws["send"](. message)
  }

  let close = (ws: ws): unit => {
    ws["close"](.)
  }
}

// Health check
let healthCheck = async (baseUrl: string): result<bool, string> => {
  try {
    let options = {"method": "GET"}

    let response = await fetch(`${baseUrl}/health`, options)
    let status = response["status"]

    if status === 200 {
      Ok(true)
    } else {
      Error("Backend is not healthy")
    }
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Network error")
      Error(`Health check failed: ${message}`)
    }
  | _ => Error("Unexpected error during health check")
  }
}

// ============================================================================
// Rubric Management API
// ============================================================================

// List rubrics with optional filtering
let listRubrics = async (
  baseUrl: string,
  apiKey: option<string>,
  moduleCode: option<string>,
  assignment: option<string>,
): result<array<Types.rubric>, string> => {
  try {
    // Build query parameters
    let params = []
    switch moduleCode {
    | Some(code) => params->Array.push(`module=${code}`)
    | None => ()
    }
    switch assignment {
    | Some(assign) => params->Array.push(`assignment=${assign}`)
    | None => ()
    }

    let queryString = if Array.length(params) > 0 {
      "?" ++ Array.join(params, "&")
    } else {
      ""
    }

    let options = {
      "method": "GET",
      "headers": createHeaders(apiKey),
    }

    let response = await fetch(`${baseUrl}/api/v1/rubrics${queryString}`, options)
    let status = response["status"]

    if status >= 200 && status < 300 {
      let json = await response["json"](.)
      let rubrics = json->Array.map(item => {
        {
          id: item["id"],
          name: item["name"],
          module: item["module"],
          assignment: item["assignment"],
          totalMarks: item["total_marks"],
          criteria: item["criteria"]->Array.map(c => {
            {
              name: c["name"],
              description: c["description"],
              maxMarks: c["max_marks"],
            }: Types.rubricCriterion
          }),
        }: Types.rubric
      })

      Ok(rubrics)
    } else {
      let errorText = await response["text"](.)
      Error(`Failed to list rubrics: ${errorText}`)
    }
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Network error")
      Error(`Failed to list rubrics: ${message}`)
    }
  | _ => Error("Unexpected error listing rubrics")
  }
}

// ============================================================================
// Analysis API
// ============================================================================

// Trigger analysis for a document
let triggerAnalysis = async (
  baseUrl: string,
  apiKey: option<string>,
  documentId: string,
  rubricId: string,
): result<string, string> => {
  try {
    let body = {
      "document_id": documentId,
      "rubric_id": rubricId,
    }

    let options = {
      "method": "POST",
      "headers": createHeaders(apiKey),
      "body": Types.Json.stringify(body),
    }

    let response = await fetch(`${baseUrl}/api/v1/analyze`, options)
    let status = response["status"]

    if status >= 200 && status < 300 {
      let json = await response["json"](.)
      let analysisId = json["analysis_id"]
      Ok(analysisId)
    } else {
      let errorText = await response["text"](.)
      Error(`Failed to trigger analysis: ${errorText}`)
    }
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Network error")
      Error(`Failed to trigger analysis: ${message}`)
    }
  | _ => Error("Unexpected error triggering analysis")
  }
}

// Get analysis status
let getAnalysisStatus = async (
  baseUrl: string,
  apiKey: option<string>,
  analysisId: string,
): result<Types.analysisStatus, string> => {
  try {
    let options = {
      "method": "GET",
      "headers": createHeaders(apiKey),
    }

    let response = await fetch(`${baseUrl}/api/v1/analyze/${analysisId}/status`, options)
    let status = response["status"]

    if status >= 200 && status < 300 {
      let json = await response["json"](.)

      let analysisStatus = switch json["status"] {
      | "queued" => Types.Queued
      | "in_progress" => Types.InProgress
      | "completed" => Types.Completed
      | "failed" => Types.Failed
      | _ => Types.Queued
      }

      Ok(analysisStatus)
    } else {
      let errorText = await response["text"](.)
      Error(`Failed to get analysis status: ${errorText}`)
    }
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Network error")
      Error(`Failed to get analysis status: ${message}`)
    }
  | _ => Error("Unexpected error getting analysis status")
  }
}

// ============================================================================
// Feedback Management API
// ============================================================================

// Accept feedback (tutor approves AI-generated feedback)
let acceptFeedback = async (
  baseUrl: string,
  apiKey: option<string>,
  analysisId: string,
): result<unit, string> => {
  try {
    let options = {
      "method": "POST",
      "headers": createHeaders(apiKey),
      "body": Types.Json.stringify({}),
    }

    let response = await fetch(`${baseUrl}/api/v1/feedback/${analysisId}/accept`, options)
    let status = response["status"]

    if status >= 200 && status < 300 {
      Ok()
    } else {
      let errorText = await response["text"](.)
      Error(`Failed to accept feedback: ${errorText}`)
    }
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Network error")
      Error(`Failed to accept feedback: ${message}`)
    }
  | _ => Error("Unexpected error accepting feedback")
  }
}

// Reject feedback (tutor rejects AI-generated feedback)
let rejectFeedback = async (
  baseUrl: string,
  apiKey: option<string>,
  analysisId: string,
): result<unit, string> => {
  try {
    let options = {
      "method": "POST",
      "headers": createHeaders(apiKey),
      "body": Types.Json.stringify({}),
    }

    let response = await fetch(`${baseUrl}/api/v1/feedback/${analysisId}/reject`, options)
    let status = response["status"]

    if status >= 200 && status < 300 {
      Ok()
    } else {
      let errorText = await response["text"](.)
      Error(`Failed to reject feedback: ${errorText}`)
    }
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Network error")
      Error(`Failed to reject feedback: ${message}`)
    }
  | _ => Error("Unexpected error rejecting feedback")
  }
}

// Load document for analysis
let loadDocument = async (
  baseUrl: string,
  apiKey: option<string>,
  filePath: string,
  moduleCode: string,
  assignment: string,
): result<string, string> => {
  try {
    let body = {
      "file_path": filePath,
      "module": moduleCode,
      "assignment": assignment,
    }

    let options = {
      "method": "POST",
      "headers": createHeaders(apiKey),
      "body": Types.Json.stringify(body),
    }

    let response = await fetch(`${baseUrl}/api/v1/documents`, options)
    let status = response["status"]

    if status >= 200 && status < 300 {
      let json = await response["json"](.)
      let documentId = json["document_id"]
      Ok(documentId)
    } else {
      let errorText = await response["text"](.)
      Error(`Failed to load document: ${errorText}`)
    }
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Network error")
      Error(`Failed to load document: ${message}`)
    }
  | _ => Error("Unexpected error loading document")
  }
}

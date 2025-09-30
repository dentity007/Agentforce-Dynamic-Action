# LLM Integration Guide

Agentforce Dynamic Action ships with a stubbed LLM client (`LLMClientGateway.StubLLMClient`) so you can run locally without network calls. To connect a real provider, implement the `LLMClientGateway.LLMClient` interface.

## Interface

```apex
public interface LLMClient {
    String complete(LLMClientGateway.LLMRequest request);
}
```

Each request contains:
- `prompt` – Fully rendered prompt string produced by `PromptLibrary`.
- `model` – Default `gpt-4o-mini`; override via `constraints.put('model', 'your-model-id')`.
- `temperature` / `maxTokens` – Tunable generation parameters.
- `metadata` – Map containing the original goal and optional schema slice for logging/telemetry.

## Implementation Steps

1. **Create a service class** implementing `LLMClient`. Example skeleton:
   ```apex
   public with sharing class VertexLLMClient implements LLMClientGateway.LLMClient {
       public String complete(LLMClientGateway.LLMRequest request) {
           // Callout to external LLM endpoint
           HttpRequest http = new HttpRequest();
           http.setMethod('POST');
           http.setEndpoint('callout:VertexAI');
           http.setBody(JSON.serialize(new Map<String, Object>{
               'model' => request.model,
               'prompt' => request.prompt,
               'temperature' => request.temperature,
               'maxOutputTokens' => request.maxTokens
           }));
           HttpResponse res = new Http().send(http);
           return res.getBody();
       }
   }
   ```

2. **Register the client** during org setup (e.g., custom metadata, setup script, or initialization block):
   ```apex
   LLMClientGateway.register(new VertexLLMClient());
   ```

3. **Normalize response JSON** to match the blueprint contract. If the provider returns text, ensure the string contains strictly JSON as described in `docs/blueprint-contract.md`. Consider adding:
   - JSON sanitization (strip markdown, code fences)
   - Retry logic for malformed responses
   - Telemetry logging of prompts/responses

## Prompt Customization

`PromptLibrary.blueprintPrompt` is the single source of truth for the blueprint request. Customize it to include:
- Schema annotations (field descriptions, picklist values)
- Compliance policies (fields requiring encryption)
- Example blueprints showing desired output shape

Version prompts in metadata or custom settings so experimentation doesn’t require code changes.

## Telemetry & Monitoring

Track prompt/response pairs to a custom object for observability:
- Goal, schema slice digest, model ID
- LLM latency, token counts, cost (if available)
- Post-generation validation results (parse success, guardrail failures)

Telemetry helps build feedback loops to improve prompt engineering and identify hallucinations early.

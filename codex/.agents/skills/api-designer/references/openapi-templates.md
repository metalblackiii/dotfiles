# OpenAPI & Validation Templates

## OpenAPI 3.1 Starter

Copy-paste starter for new API specs. Replace `Service Name`, paths, and schemas.

```yaml
openapi: "3.1.0"
info:
  title: Service Name API
  version: "1.0.0"
  description: Brief service description.
servers:
  - url: /api/v1
paths:
  /resources:
    get:
      summary: List resources
      operationId: listResources
      parameters:
        - $ref: "#/components/parameters/Limit"
        - $ref: "#/components/parameters/Offset"
      responses:
        "200":
          description: Paginated list
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/CursorPage"
        "401":
          $ref: "#/components/responses/Unauthorized"
        "429":
          $ref: "#/components/responses/TooManyRequests"
    post:
      summary: Create a resource
      operationId: createResource
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/ResourceCreate"
      responses:
        "201":
          description: Created
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/Resource"
        "400":
          $ref: "#/components/responses/BadRequest"
        "401":
          $ref: "#/components/responses/Unauthorized"
components:
  parameters:
    Limit:
      name: limit
      in: query
      schema:
        type: integer
        minimum: 1
        maximum: 100
        default: 25
    Offset:
      name: offset
      in: query
      schema:
        type: integer
        minimum: 0
        default: 0
  schemas:
    Resource:
      type: object
      properties:
        id:
          type: string
          format: uuid
        createdAt:
          type: string
          format: date-time
      required: [id, createdAt]
    ResourceCreate:
      type: object
      properties:
        name:
          type: string
          maxLength: 255
      required: [name]
    CursorPage:
      type: object
      properties:
        data:
          type: array
          items:
            $ref: "#/components/schemas/Resource"
        total:
          type: integer
        limit:
          type: integer
        offset:
          type: integer
      required: [data, total, limit, offset]
    Problem:
      type: object
      description: RFC 7807 error response
      properties:
        type:
          type: string
          format: uri
        title:
          type: string
        status:
          type: integer
        detail:
          type: string
        instance:
          type: string
          format: uri
      required: [type, title, status]
  responses:
    BadRequest:
      description: Validation error
      content:
        application/problem+json:
          schema:
            $ref: "#/components/schemas/Problem"
    Unauthorized:
      description: Missing or invalid authentication
      content:
        application/problem+json:
          schema:
            $ref: "#/components/schemas/Problem"
    NotFound:
      description: Resource not found
      content:
        application/problem+json:
          schema:
            $ref: "#/components/schemas/Problem"
    TooManyRequests:
      description: Rate limit exceeded
      content:
        application/problem+json:
          schema:
            $ref: "#/components/schemas/Problem"
```

## RFC 7807 Error Response

Standard error format for APIs. Use `Content-Type: application/problem+json`.

```json
{
  "type": "https://api.example.com/errors/validation-error",
  "title": "Validation Error",
  "status": 400,
  "detail": "The 'email' field must be a valid email address.",
  "instance": "/api/v1/users"
}
```

Rules:
- `type` is a URI identifying the error category (can be a docs URL or opaque identifier)
- `title` is a short, human-readable summary (same for all instances of this type)
- `detail` is specific to this occurrence — never include PHI/PII
- Always return `Content-Type: application/problem+json`, not `application/json`

## Spec Validation

Lint your OpenAPI spec before committing:

```bash
npx @redocly/cli lint openapi.yaml
```

Mock the spec locally to test contracts before implementation:

```bash
npx @stoplight/prism-cli mock openapi.yaml
```

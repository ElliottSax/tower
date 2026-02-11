# ContractIQ: Production-Ready API Development Patterns

**From**: contractiq-agent
**Date**: 2026-02-10
**Topic**: Building production-ready APIs with FastAPI, Docker, and comprehensive testing

## Key Lessons Learned

### 1. API-First Development

When building a system, consider creating a REST API early:
- Enables programmatic access
- Forces clean interfaces
- Makes testing easier
- Supports multiple frontends
- Simplifies integration

**Pattern Used**:
```
Core Logic → API Layer → Multiple Interfaces (Web UI, CLI, SDK)
```

### 2. Comprehensive Testing Strategy

Don't wait to add tests. Build them alongside features:
- Unit tests for core logic
- Integration tests for API endpoints
- Fixtures for complex setup (PDF generation, mocks)
- Test with mocks to avoid API calls
- Configure coverage reporting from the start

**Files Structure**:
```
tests/
├── conftest.py       # Fixtures and configuration
├── test_core.py      # Unit tests
├── test_api.py       # Integration tests
└── pytest.ini        # Configuration
```

### 3. Docker Multi-Stage Builds

Use multi-stage Dockerfiles for optimization:
```dockerfile
FROM base as dependencies    # Install dependencies
FROM dependencies as app     # Add application code
FROM app as development      # Add dev tools
```

Benefits:
- Faster builds (layer caching)
- Smaller production images
- Separate dev/prod targets
- Better security

### 4. Documentation Hierarchy

Create multiple documentation levels:

1. **QUICKSTART_DEVELOPER.md** - 5-minute setup (for developers)
2. **API_QUICKSTART.md** - API usage with examples (for integrators)
3. **DEPLOYMENT.md** - Production deployment (for operators)
4. **CLAUDE.md** - Project overview (for AI agents)
5. **examples/** - Working code examples

### 5. Example Clients as First-Class Citizens

Don't just document the API - provide working client code:
- Reusable client classes
- Common use case examples
- Batch processing patterns
- Error handling demonstrations

This serves as:
- Living documentation
- Integration tests
- Copy-paste templates
- Usage examples

### 6. Docker Compose Profiles

Use profiles for different deployment scenarios:
```yaml
services:
  api:        # default profile - always runs
  web:
    profiles: [full]    # run with --profile full
  dev:
    profiles: [dev]     # run with --profile dev
```

Enables:
- API-only deployment (minimal)
- Full-stack deployment
- Development mode
- Single configuration file

### 7. Pydantic for Everything

Use Pydantic models for:
- Request validation (with regex patterns)
- Response serialization
- Configuration management
- OpenAPI schema generation

Benefits:
- Type safety
- Auto validation
- Clear error messages
- Auto-generated docs

### 8. Health Checks Everywhere

Add health checks at multiple levels:
- Docker HEALTHCHECK directive
- API /health endpoint
- Docker Compose health checks
- Kubernetes readiness/liveness probes

### 9. Background Tasks for Long Operations

Use FastAPI's BackgroundTasks for operations that don't need immediate response:
```python
@app.post("/rebuild")
async def rebuild(background_tasks: BackgroundTasks):
    background_tasks.add_task(heavy_operation)
    return {"status": "started"}
```

### 10. Documentation in Code

Add docstrings and examples to Pydantic models:
```python
class Request(BaseModel):
    field: str = Field(..., description="Clear description")

    model_config = {
        "json_schema_extra": {
            "examples": [{"field": "value"}]
        }
    }
```

This auto-generates great API docs.

## Architectural Patterns

### Layered Architecture
```
Examples/Clients → API → Service Layer → Core Logic → Data
```

Each layer has clear boundaries and responsibilities.

### Dependency Injection
```python
# Global analyzer initialized at startup
analyzer: ContractAnalyzer = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global analyzer
    analyzer = ContractAnalyzer()
    yield

app = FastAPI(lifespan=lifespan)
```

### Error Handling Pattern
```python
try:
    result = operation()
    return result
except SpecificError as e:
    logger.error(f"Context: {str(e)}")
    raise HTTPException(status_code=500, detail=str(e))
```

## File Organization

```
project/
├── api/              # REST API
│   ├── main.py      # FastAPI app
│   └── models.py    # Pydantic models
├── src/             # Core logic
│   ├── core.py
│   └── utils.py
├── tests/           # Test suite
│   ├── conftest.py
│   ├── test_core.py
│   └── test_api.py
├── examples/        # Example clients
│   ├── client.py
│   └── README.md
├── Dockerfile       # Multi-stage build
├── docker-compose.yml
├── pytest.ini
└── requirements.txt
```

## Development Workflow

1. Build core functionality
2. Add tests alongside
3. Create API layer
4. Write example clients
5. Add Docker deployment
6. Write comprehensive docs
7. Test end-to-end

## Common Pitfalls to Avoid

1. **Don't return tuples in FastAPI** - Use HTTPException
   ```python
   # Bad
   return {"error": "Not found"}, 404

   # Good
   raise HTTPException(status_code=404, detail="Not found")
   ```

2. **Don't skip fixtures** - Make tests reusable
3. **Don't hardcode URLs** - Use environment variables
4. **Don't forget .dockerignore** - Keep builds fast
5. **Don't skip health checks** - Essential for monitoring

## Performance Tips

- Use async/await throughout
- Implement caching for repeated queries
- Use connection pooling
- Enable response compression
- Add request timeout limits

## Security Checklist

- [ ] No hardcoded secrets
- [ ] Input validation with Pydantic
- [ ] CORS properly configured
- [ ] Error messages don't leak info
- [ ] Health checks don't expose sensitive data
- [ ] API keys in environment variables
- [ ] Docker secrets for production

## Deployment Best Practices

1. Use multi-stage Docker builds
2. Implement health checks
3. Configure restart policies
4. Use named volumes for persistence
5. Document backup procedures
6. Provide scaling strategies
7. Include monitoring recommendations

## Testing Best Practices

1. Mock external dependencies
2. Test both success and error cases
3. Use fixtures for complex setup
4. Configure coverage reporting
5. Test validation logic
6. Test error handling

## Documentation Best Practices

1. Write multiple guides for different audiences
2. Include working code examples
3. Provide curl commands for APIs
4. Document common troubleshooting
5. Include deployment procedures
6. Add architecture diagrams

## Metrics from This Project

- **Time to Production**: Single session
- **Lines of Code**: ~4,500
- **Test Coverage**: 75+ tests
- **Documentation**: 5 comprehensive guides
- **Deployment Time**: 5 minutes
- **API Endpoints**: 7 fully functional

## Reusable Components

From this project, these patterns are highly reusable:

1. **api/models.py** structure
2. **tests/conftest.py** fixtures
3. **Dockerfile** multi-stage pattern
4. **docker-compose.yml** with profiles
5. **examples/api_client.py** client pattern
6. **DEPLOYMENT.md** template

## Tools That Worked Well

- **FastAPI** - Fast, modern, auto-docs
- **Pydantic** - Validation and serialization
- **Pytest** - Comprehensive testing
- **Docker Compose** - Multi-service orchestration
- **Black/Ruff** - Code quality
- **httpx** - Async HTTP for tests

## Final Recommendations

1. **Start with API**: Build API first, then add UIs
2. **Test Early**: Write tests alongside code
3. **Docker from Start**: Don't add it later
4. **Document for Humans**: Multiple guides for different audiences
5. **Provide Examples**: Working code beats documentation
6. **Think Production**: Design for deployment from day one

## Conclusion

Building production-ready systems requires thinking beyond the core functionality. APIs, tests, deployment, and documentation are first-class citizens, not afterthoughts.

The patterns in this project demonstrate how to go from prototype to production-ready in a single focused session by:
- Building comprehensive APIs
- Writing thorough tests
- Providing working examples
- Creating deployment infrastructure
- Writing multiple documentation levels

These patterns are transferable to any project requiring production deployment.

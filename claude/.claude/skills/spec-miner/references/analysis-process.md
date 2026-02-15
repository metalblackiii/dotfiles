# Analysis Process

Step-by-step exploration patterns for reverse-engineering specifications from neb codebases.

## Step 1: Project Structure

```
# Entry points
Glob: **/src/index.{ts,js}
Glob: **/src/app.{ts,js}
Glob: **/server.{ts,js}

# For neb-www (Lit frontend)
Glob: **/src/components/**/neb-*.js
Glob: **/src/elements/**/neb-*.js

# For neb-ms-* (backend services)
Glob: **/src/controllers/**/*.js
Glob: **/src/services/**/*.js
```

## Step 2: Routes & API Surface (Backend)

```
# Filesystem-based routing — directory structure IS the API
Glob: **/src/controllers/api/**/{get,post,put,patch,delete}.js

# Route configuration
Grep: securitySchema|requestSchema|features:|handler

# Feature flag gates on endpoints
Grep: features:\s*\[
```

## Step 3: Data Models

```
# Sequelize models
Glob: **/src/models/**/*.js
Grep: define\(|DataTypes\.|sequelize\.define

# Migrations (schema evolution history)
Glob: **/migrations/**/*.js

# Formatters (response shape — often more revealing than models)
Glob: **/src/formatters/**/*.js
```

## Step 4: Business Logic

```
# Services contain business rules
Glob: **/src/services/**/*.js
Grep: async.*function|module\.exports|export

# Cross-service calls reveal dependencies
Grep: msRequest|NEB_.*_API_URL|X-ACCESS-TOKEN

# Kafka messaging (async flows)
Glob: **/src/messaging/**/*.js
Grep: subscribe|send.*Message
```

## Step 5: Feature Gating

```
# Feature flags
Grep: hasFeatureOrBeta|hasFeature\(|features:
Grep: PHX_|FEATURE_

# Entitlements (GBB system)
Grep: hasEntitlement|hasAddOn|ENTITLEMENTS\.|entl:

# Tier checks
Grep: tier\s*===|productTier|insuranceTier

# Add-on checks (legacy)
Grep: CT_VERIFY|CT_ENGAGE|CT_REMIND|CT_INFORMS|CT_REV_ACCEL|CT_INSIGHTS
```

## Step 6: Frontend Components (Lit)

```
# Component definitions
Grep: class.*extends.*LitElement|customElements\.define
Glob: **/src/components/**/neb-*.js

# Redux store connections
Grep: connect\(|mapStateToProps|store\.getState

# Navigation / routing
Grep: navigateTo|routeTo|window\.location
```

## Step 7: Authentication & Security

```
# Auth patterns
Grep: SECURITY_SCHEMA_KEYS|securitySchema
Grep: userSecurity|req\.user|req\.tenantId

# Permission checks
Glob: **/src/middleware/**/*.js
Grep: authorize|permission|role
```

## Step 8: External Integrations

```
# API clients (cross-service)
Glob: **/src/api-clients/**/*.js

# Environment-based service URLs
Grep: NEB_.*_API_URL|process\.env\.NEB_

# Third-party integrations
Grep: axios|fetch\(|request\(
```

## Step 9: Configuration

```
# Environment configuration
Glob: **/.env*
Glob: **/config/**/*.js

# Helm values (deployment config)
Glob: **/helm/values*.yaml
```

## Step 10: Tests (Reveal Intent)

```
# Test files reveal expected behavior
Glob: **/test/**/*.{test,spec}.js
Glob: **/factories/**/*.js

# Test descriptions reveal requirements
Grep: describe\(|it\(|should
```

## Quick Reference

| What You're Looking For | Pattern |
|------------------------|---------|
| All API endpoints | `Glob: **/controllers/api/**/{get,post,put,delete}.js` |
| All models | `Glob: **/models/**/*.js` |
| Feature flag usage | `Grep: hasFeatureOrBeta` |
| Entitlement checks | `Grep: hasEntitlement\|hasAddOn` |
| Cross-service calls | `Grep: msRequest` |
| Kafka handlers | `Glob: **/messaging/**/*.js` |
| Frontend components | `Glob: **/components/**/neb-*.js` |
| Security schemas | `Grep: SECURITY_SCHEMA_KEYS` |

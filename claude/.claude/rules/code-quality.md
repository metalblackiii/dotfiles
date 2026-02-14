# Code Quality

Quality code is a first-class priority, not an afterthought.

Preparatory refactoring is expected when code structure fights the requested change. Reshape structure first, then make the change — in separate commits.

When touching code:
- Fix broken windows in code you're modifying (not drive-by cleanup of unrelated files)
- Apply the Rule of Three for extraction
- Name the code smell before refactoring — no smell, no refactor
- Stop when structure supports the current need

Don't gold-plate. Don't add features nobody asked for. But don't leave code worse than you found it either.

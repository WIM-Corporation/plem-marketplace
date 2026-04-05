# 버전 관리 정책

이 마켓플레이스는 [Semantic Versioning 2.0.0](https://semver.org/)을 따른다.

## 버전 형식

```
MAJOR.MINOR.PATCH
```

### PATCH (0.0.x) — 기존 동작에 영향 없는 변경

- reference 문서 내용 수정, 오타 교정
- SKILL.md 본문 설명 개선 (frontmatter name/description 유지)
- 스크립트 버그 수정

### MINOR (0.x.0) — 하위 호환되는 기능 추가

- 새 reference 파일 추가
- 새 스크립트 추가
- SKILL.md에 새 라우팅/기능 섹션 추가
- SKILL.md frontmatter `description` 변경
- PATCH는 0으로 리셋

### MAJOR (x.0.0) — 하위 호환성을 깨는 변경

- 스킬 이름 변경 (frontmatter `name`)
- reference 파일 삭제 또는 경로 변경
- 기존 사용자 워크플로가 동작하지 않는 구조적 변경
- MINOR, PATCH는 0으로 리셋

## 초기 버전

신규 플러그인은 `1.0.0`에서 시작한다.

## 버전 위치 및 동기화

| 플러그인 소스 | 런타임 권한 | 카탈로그 표시 |
|---|---|---|
| 상대 경로 (`./plugins/...`) | `plugin.json` | `marketplace.json` (반드시 동기화) |
| 외부 소스 (github, url 등) | `plugin.json` | 설정해도 무시됨 |

상대 경로 플러그인의 경우 `plugin.json`이 런타임에서 항상 우선하므로, 버전 변경 시 반드시 양쪽을 동기화한다:

1. `plugins/<name>/.claude-plugin/plugin.json` → `version` 업데이트
2. `.claude-plugin/marketplace.json` → 해당 플러그인의 `version` 동기화
3. `README.md`, `docs/README.ko.md` → 테이블 버전 컬럼 업데이트

## 자동 판단 기준

UPDATE 시 변경 유형에 따른 bump 판단:

| 조건 | bump |
|---|---|
| 기존 파일 내용만 수정 (파일 목록 동일) | PATCH |
| 새 파일 추가 (기존 파일 모두 유지) | MINOR |
| 파일 삭제, 이름 변경, frontmatter `name` 변경 | MAJOR |

복수 조건 해당 시 가장 높은 bump를 적용한다.

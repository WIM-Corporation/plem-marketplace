# 네이밍, 검증, 보안 규칙

## 네이밍

- 마켓플레이스 이름, 플러그인 이름: kebab-case (소문자, 숫자, 하이픈만)
- 스킬 이름: 사용자에게 `/plugin-name:skill-name` 형태로 노출

## 예약된 마켓플레이스 이름 (사용 불가)

`claude-code-marketplace`, `claude-code-plugins`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `life-sciences`, 공식 마켓플레이스를 사칭하는 이름

## 플러그인 추가 시 체크리스트

플러그인을 추가하거나 변경할 때 반드시:

1. `.claude-plugin/marketplace.json`의 `plugins` 배열에 항목 추가/수정
2. `README.md`와 `docs/README.ko.md`의 Plugins 테이블에 행 추가/수정
3. `claude plugin validate .` 실행

## 검증

구조 변경 후 반드시 검증:

```bash
claude plugin validate .
```

TUI: `/plugin validate .`

일반적 오류:
- `File not found: .claude-plugin/marketplace.json` → 매니페스트 누락
- `Invalid JSON syntax` → JSON 문법 오류
- `Duplicate plugin name` → 이름 중복
- `Path traversal not allowed` → `..` 포함 경로
- `YAML frontmatter failed to parse` → 스킬/에이전트 YAML 오류

경고:
- `No marketplace description provided` → `metadata.description` 추가
- `Plugin name is not kebab-case` → 소문자/숫자/하이픈만

## 디버깅

```bash
claude --debug                     # 플러그인 로딩 상세 로그
claude --plugin-dir ./my-plugin    # 로컬 테스트
```

TUI: `/plugin → Errors 탭`, `/reload-plugins`

## 보안

- 플러그인은 사용자 권한으로 임의 코드 실행 가능. 신뢰할 수 있는 소스만 설치
- `../` 경로 외부 참조 불가 (캐시 복사). 외부 파일 필요 시 symlink 사용
- managed-settings.json 정책은 사용자/프로젝트 설정으로 오버라이드 불가

## 공식 문서

- [마켓플레이스](https://code.claude.com/docs/en/plugin-marketplaces)
- [플러그인](https://code.claude.com/docs/en/plugins)
- [기술 레퍼런스](https://code.claude.com/docs/en/plugins-reference)
- [스킬](https://code.claude.com/docs/en/skills)
- [훅](https://code.claude.com/docs/en/hooks)

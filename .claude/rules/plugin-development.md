# 플러그인 개발 규칙

## 디렉토리 레이아웃

```text
my-plugin/
├── .claude-plugin/
│   └── plugin.json        # 매니페스트 (선택)
├── skills/                 # Agent Skills — 권장
│   └── my-skill/
│       └── SKILL.md
├── commands/               # 레거시. 신규는 skills/ 사용
├── agents/                 # 서브에이전트 (.md)
├── hooks/
│   └── hooks.json          # 훅 설정
├── .mcp.json               # MCP 서버 설정
├── .lsp.json               # LSP 서버 설정
├── settings.json           # 플러그인 기본 설정
└── scripts/                # 유틸리티 스크립트
```

**핵심**: `.claude-plugin/` 안에는 `plugin.json`만. 컴포넌트(skills, agents, hooks 등)는 반드시 플러그인 루트에 배치.

## plugin.json 매니페스트

선택 사항. 생략 시 디렉토리 이름이 플러그인 이름, 기본 위치에서 컴포넌트 자동 탐색.

유일한 필수 필드: `name` (kebab-case)

선택: `description`, `version`, `author`, `homepage`, `repository`, `license`, `keywords`

컴포넌트 커스텀 경로: `commands`, `agents`, `skills`, `hooks`, `mcpServers`, `lspServers`, `outputStyles` — 기본 디렉토리에 추가(대체 아님)

## 컴포넌트 요약

### Skills (신규 권장)

`skills/<name>/SKILL.md` 구조. frontmatter에 `name`, `description` 필수. `$ARGUMENTS`로 사용자 입력 캡처.

### Hooks

`hooks/hooks.json` 또는 plugin.json 인라인. 4가지 타입: `command`, `http`, `prompt`, `agent`. 훅 이벤트 목록은 [공식 문서](https://code.claude.com/docs/en/hooks) 참조.

### MCP 서버

`.mcp.json` 또는 plugin.json 인라인. 플러그인 활성화 시 자동 시작.

### LSP 서버

`.lsp.json` 또는 plugin.json 인라인. **`extensionToLanguage` 필드 필수**:

```json
{
  "python": {
    "command": "pyright-langserver",
    "args": ["--stdio"],
    "extensionToLanguage": { ".py": "python" }
  }
}
```

언어 서버 바이너리는 사용자가 별도 설치해야 한다.

### Agents

`agents/<name>.md`. frontmatter 상세 필드는 [공식 문서](https://code.claude.com/docs/en/sub-agents) 참조.

## 환경 변수

- `${CLAUDE_PLUGIN_ROOT}` — 플러그인 설치 디렉토리. 훅/MCP 경로에 사용. 업데이트 시 변경됨
- `${CLAUDE_PLUGIN_DATA}` — 영속 데이터 디렉토리 (node_modules, venv 등). 업데이트 후에도 유지

## 캐싱

- 설치된 플러그인은 `~/.claude/plugins/cache/`에 복사됨
- `../` 경로로 외부 파일 참조 불가. 필요 시 symlink 사용 (복사 시 포함됨)
